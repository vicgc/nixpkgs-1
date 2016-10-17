{ config, lib, ... }:

let
  cfg = config.flyingcircus;

  fclib = import ../lib;

  localRules = lib.concatMapStringsSep "\n"
    (filename:
       "# Local rules from ${filename}\n" +
       # We try to be helpful to our users by only allowing calls to iptables
       # and comments.
       (lib.concatMapStringsSep "\n"
          (line: assert lib.hasPrefix "#" line ||
                        lib.hasPrefix "iptables" line ||
                        lib.hasPrefix "ip6tables" line ||
                        lib.hasPrefix "ip46tables" line;
                 line)
          (lib.splitString "\n" (builtins.readFile filename))) +
       "\n")
    (fclib.files "/etc/local/firewall");

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

        ${localRules}
      '';

    system.activationScripts.local-firewall = ''
      # Enable firewall local configuration snippet place.
      install -d -o root -g service -m 02775 /etc/local/firewall
    '';
  };
}
