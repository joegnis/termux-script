#!/bin/bash
PROG="$(basename "$0")"
# Parse options
USAGE="Usage: $PROG [-h|--help] [-a|--all] [--ssh] [--shortcuts]
Setup environment from Termux app
...

Options:

--ssh
    Setup SSH. Public key file id_rsa.pub should be put in
    'Internal Memory/Downloads' beforehand.

--shortcuts
    Install shortcuts scripts.

-a, --all
    Setup all above.

-h, --help
    Display this help and exit
...
"

echo_action () {
    echo ===================================================
    echo "==> $*"
    echo ===================================================
}

echo_action_end () {
    echo Done...
}

getopt --test > /dev/null
if [[ $? -ne 4 ]]; then
    >&2 echo "I’m sorry, $(getopt --test) failed in this environment."
    exit 1
fi

SHORT=ha
LONG=help,ssh,shortcuts,all

PARSED=$(getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@")
if [[ $? -ne 0 ]]; then
    exit 2
fi

eval set -- "$PARSED"

SETUP_ALL=yes
SETUP_SSH=no
SETUP_SHORTCUTS=no
while [ $# -gt 0 ]; do
    case "$1" in
        -a | --all )
            setup_all_option=yes
            ;;
        --ssh )
            SETUP_ALL=no
            SETUP_SSH=yes
            ;;
        --shortcuts )
            SETUP_ALL=no
            SETUP_SHORTCUTS=yes
            ;;
        -h | --help)
            echo "$USAGE"
            exit 0
            ;;
        --)
            shift
            break
            ;;
    esac
    shift
done

[[ $setup_all_option = yes ]] && SETUP_ALL=yes

echo_action "Set up Storage"
termux-setup-storage
echo_action_end

echo_action "Install necessary packages"
pkg install -y rsync
echo_action_end

if [ $SETUP_ALL = yes ] || [ $SETUP_SSH = yes ]; then
    echo_action "Set up SSH"

    pkg install -y openssh
    touch ~/.ssh/authorized_keys
    # Set Permissions to the file
    chmod 600 ~/.ssh/authorized_keys
    # Make sure the folder .ssh folder has the correct permissions
    chmod 700 ~/.ssh
    # Copy public key
    pub_key=~/storage/downloads/id_rsa.pub
    while [ ! -e "$pub_key" ]; do
        echo Please put public key file id_rsa.pub in /sdcard/Download
        echo -n Press any key to continue...
        read -n 1 anything
        echo ""
    done
    cat "$pub_key" >> ~/.ssh/authorized_keys

    echo_action_end
fi

if [ $SETUP_ALL = yes ] || [ $SETUP_SHORTCUTS = yes ]; then
    echo_action "Install shortcut scripts"
    setup_script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    rsync --delete -va --checksum "$setup_script_dir"/shortcuts/ ~/.shortcuts
    echo_action_end
fi
