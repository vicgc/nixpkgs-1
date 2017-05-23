{ config, lib, ... }:
let
  enc = config.flyingcircus.enc;
  parameters = lib.attrByPath [ "parameters" ] {} enc;
  isProd = (lib.attrByPath [ "location" ] "dev" parameters) != "dev"
    && lib.attrByPath [ "production" ] false parameters;

in
{
  config = {
    environment.interactiveShellInit = ''
      export TMOUT=43200
    '';

    environment.shellInit =
      # FCIO_* only exported if ENC data is present.
      (lib.optionalString
        (enc ? name && parameters ? location && parameters ? environment)
        ''
          # Grant easy access to the machine's ENC data for some variables to
          # shell scripts.
          export FCIO_LOCATION="${parameters.location}"
          export FCIO_ENVIRONMENT="${parameters.environment}"
          export FCIO_HOSTNAME="${enc.name}"
        '');

    users.motd = ''
        Welcome to the Flying Circus!

        Status:    http://status.flyingcircus.io/
        Docs:      https://flyingcircus.io/doc/
        Release:   ${config.system.nixosVersion}

    '' +
    (lib.optionalString
      (enc ? name && parameters ? location && parameters ? environment
        && parameters ? service_description)
      ''
        Hostname:  ${enc.name}    Environment: ${parameters.environment}    Location: ${parameters.location}
        Services:  ${parameters.service_description}

      '');

    programs.bash.promptInit =
      let
        dirColor = "00;34m";
        prodColor = "00;33m";
        userColor = if isProd then "01;32m" else "01;34m";
        rootColor = if isProd then "01;31m" else "01;35m";
      in ''
        ### PROMPTING
        PROMPT_DIRTRIM=3

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
      '' + (lib.optionalString isProd ''
        if ((use_color)); then
          PS1+='\[\e[${prodColor}\][prod] '
        else
          PS1+='[prod] '
        fi
      '') +
      ''
        if ((use_color)); then
          if [[ $UID == 0 ]]; then
            PS1+='\[\e[${rootColor}\]\u@\h '
          else
            PS1+='\[\e[${userColor}\]\u@\h '
          fi
          PS1+='\[\e[${dirColor}\]\w \$\[\e[0m\] '
        else
          PS1+='\n\u@\h \w \$ '
        fi

        unset use_color
    '';

    programs.zsh.enable = true;

  };
}
