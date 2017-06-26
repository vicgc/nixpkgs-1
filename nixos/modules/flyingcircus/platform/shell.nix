{ config, lib, ... }:
let
  enc = config.flyingcircus.enc;
  parameters = lib.attrByPath [ "parameters" ] {} enc;
  isProd = (lib.attrByPath [ "location" ] "dev" parameters) != "dev"
    && lib.attrByPath [ "production" ] false parameters;
  opt = lib.optionalString;

in
{
  config = {
    environment.interactiveShellInit = ''
      export TMOUT=43200
    '';

    environment.shellInit = ''
      # help building locally compiled programs
      export LIBRARY_PATH=$HOME/.nix-profile/lib:/run/current-system/sw/lib
      # header files
      export CPATH=$HOME/.nix-profile/include:/run/current-system/sw/include
      export C_INCLUDE_PATH=$CPATH
      export CPLUS_INCLUDE_PATH=$CPATH
      # pkg-config
      export PKG_CONFIG_PATH=$HOME/.nix-profile/lib/pkgconfig:/run/current-system/sw/lib/pkgconfig
    '' +
    (opt
      (enc ? name && parameters ? location && parameters ? environment)
      # FCIO_* only exported if ENC data is present.
      ''
        # Grant easy access to the machine's ENC data for some variables to
        # shell scripts.
        export FCIO_LOCATION="${parameters.location}"
        export FCIO_ENVIRONMENT="${parameters.environment}"
        export FCIO_HOSTNAME="${enc.name}"
      '');

    users.motd = ''
      Welcome to the Flying Circus!

      Status:     http://status.flyingcircus.io/
      Docs:       https://flyingcircus.io/doc/
      Release:    ${config.system.nixosVersion}
    '' +
    (opt
      (enc ? name && parameters ? location && parameters ? environment
        && parameters ? service_description)
      ''

        Hostname:   ${enc.name}  Environment: ${parameters.environment}  Location: ${parameters.location}
        Services:   ${parameters.service_description}${opt isProd "  [production]"}
      '');

    programs.bash.promptInit =
      let
        user = "00;32m";
        root = "01;31m";
        prod = "00;36m";
        dir = "01;34m";
      in ''
        ### prompting
        PROMPT_DIRTRIM=2

        case ''${TERM} in
          [aEkx]term*|rxvt*|gnome*|konsole*|screen|cons25|*color)
            use_color=1 ;;
          *)
            use_color=0 ;;
        esac

        # window title
        case ''${TERM} in
          [aEkx]term*|rxvt*|gnome*|konsole*|interix)
            PS1='\n\[\e]0;\u@\h:\w\007\]' ;;
          screen*)
            PS1='\n\[\ek\u@\h:\w\e\\\]' ;;
          *)
            PS1='\n' ;;
        esac

        if ((use_color)); then
          if [[ $UID == 0 ]]; then
            PS1+='\[\e[${root}\]\u@\h '
          else
            PS1+='\[\e[${user}\]\u@\h '
          fi
      '' + (opt isProd ''
          PS1+='\[\e[${prod}\][prod] '
      '') +
      ''
          PS1+='\[\e[${dir}\]\w \$\[\e[0m\] '
        else
          PS1+='\u@\h ${opt isProd "[prod] "}\w \$ '
        fi

        unset use_color
      '';

    programs.zsh.enable = true;

  };
}

