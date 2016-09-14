#!/usr/bin/env bash
# This script processes per-user logrotate snippets for a single user.
# The first argument given is a directory of all user logrotate configs.
# This script runs within the context of a single user and assumes his
#
set -e

USER="${USER:-$(whoami)}"
cfg="${1}/${USER}"
dir="/var/spool/logrotate"

# Run only if there actually are config files around.
if [[ -d "${cfg}" && -z $(find "${cfg}" -maxdepth 0 -empty) ]]; then
    state="${dir}/${USER}.state"
    if [[ ! -f ${state} ]]; then
        touch "${state}"
        chown "${USER}:" "${state}"
    fi
    expandedconf="${dir}/${USER}.conf"
    cat /etc/logrotate.options "${cfg}"/* > "${expandedconf}" &&
        logrotate -v -s "${state}" "${expandedconf}" ||
        true
fi
