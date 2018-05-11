#!/bin/bash

# --- get opts ------- #

    usage() { echo "Usage: $0 [-k <file_path>] [-u <string> | -e <string>]" 1>&2; exit 1; }
    while getopts ":k:u:e:" o; do
        case "${o}" in
            k)
                KEY=${OPTARG}
                ;;
            u)
                USER=${OPTARG}
                ;;
            e)
                EFS=${OPTARG}
                ;;
            *)
                usage
                ;;
        esac
    done
    shift $((OPTIND-1))
    if [ -z "${KEY}" ] || [ -z "${USER}" ] || [ -z "${EFS}" ]; then
        usage
    fi
    EFS_DIR='/mnt/efs'
    MOUNT_EFS="${EFS_DIR}/${USER}"
    MOUNT_USR="/home/${USER}"


# --- Prompt for confirm ------- #
#
    echo " -- SFTP CREATE USER --"
    echo 'Public_key='$KEY
    echo 'USER='$USER
    echo 'efs_address='$EFS
    echo 'efs_mount='$MOUNT_EFS
    echo 'user_mount='$MOUNT_USR
    echo ''

    confirm(){
        while true; do read -r -n 1 -p "${1:-Continue?} [y/n]: " REPLY
            case $REPLY in
              [yY]) echo ; return 0 ;;
              [nN]) echo ; return 1 ;;
              *) printf " \033[31m %s \n\033[0m" "invalid input"
            esac
        done
    }

    confirm "Create User?" || exit 0




# --- create sftp user and mount ------ #

    # Create user & home dir
    sudo adduser -d /home/$USER -G oasis $USER
    # Disable user shell
    sudo usermod -s /bin/false $USER

    # Create mount points
    sudo mkdir -p $MOUNT_EFS

    # Append lines to fstab
    MOUNT_OPTS="nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 0"
    printf "\n# SFTP MOUNT - ${USER}"               | sudo tee -a /etc/fstab
    printf "\n${EFS}.efs.eu-west-1.amazonaws.com:/ ${MOUNT_EFS} ${MOUNT_OPTS}" | sudo tee -a /etc/fstab
    printf "\n${MOUNT_EFS} ${MOUNT_USR} none bind 0 0"  | sudo tee -a /etc/fstab

    # Reload mount points
    sudo mount -av

    # Add pub key
    echo “${KEY} imported-openssh-key” >> /etc/ssh/authorized_keys/$USER
    chmod 644 /etc/ssh/authorized_keys/$USER
    chown -R $USER:$USER $MOUNT_USR
