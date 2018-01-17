{ config, pkgs, lib, ... }:

with builtins;

let
  cfg = config.flyingcircus;

  fclib = import ../lib;

  checkRules = pkgs.writeScript "check-iptables-local-rules.py" ''
    #! ${pkgs.python3.interpreter}
    import fileinput
    import re
    import shlex
    import sys
    R_ALLOWED = re.compile(r'^(#.*|ip[46]{0,2}tables .*)?$')

    for line in fileinput.input():
      line = ' '.join(
        shlex.quote(s) for s in shlex.split(line.strip(), comments=True))
      m = R_ALLOWED.match(line)
      if m:
        if m.group(1):
          print(m.group(1))
      else:
        print('ERROR: only iptable statements or comments allowed\n'
              '{}: {}'.format(fileinput.filename(), line.strip()),
              file=sys.stderr)
        sys.exit(1)
  '';

  localRules =
  pkgs.runCommand "firewall-local-rules"
    {
      inputs = concatStringsSep " "
        (map readFile (fclib.files "/etc/local/firewall"));
      passAsFile = [ "inputs" ];
    } ''
      ${checkRules} < $inputsPath > $out
    '';

  rgAddrs = map (e: e.ip) cfg.enc_addresses.srv;
  rgRules = lib.optionalString
    (lib.hasAttr "ethsrv" config.networking.interfaces)
    (lib.concatMapStringsSep "\n"
      (a:
        "${fclib.iptables a} -A nixos-fw -i ethsrv " +
        "-s ${fclib.stripNetmask a} -j nixos-fw-accept")
      rgAddrs);

in
{
  config = {
    networking.firewall.checkReversePath = false;

    networking.firewall.extraCommands =
      let
        rg = lib.optionalString
          (rgRules != "")
          "# Accept traffic within the same resource group.\n${rgRules}";
      in ''
        ${rg}

        # Local firewall rules
        ${readFile localRules}
      '';

    system.activationScripts.local-firewall = ''
      # Enable firewall local configuration snippet place.
      install -d -o root -g service -m 02775 /etc/local/firewall
    '';
  };
}
