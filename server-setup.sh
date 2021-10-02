#!/bin/bash
###################################################################
# SERVER SETUP SCRIPT
#
#   by C-4422
# 9b6b87bf3d3f44de936e7283ce4e555402feb741a005dfdc70cbbe2f08581911
# 353b5bd8ab63aa7d4f15f462ef001d7b12f1abd6d32b9f9751ef7d9df9b3462a
#
# The purpose of this script is for ease of use when setting up
# your own home server. Primary functions include:
# - Modify or create a user intended for running rootless podman
#   containers
# - Install needed software to run rootless podman along with
#   other software intended for ease of use like cockpit.
# - Set kernel parmaters for more security
# - Set up podman to use fuse-fs for rootless containers
# - Set up locations for container persistent storage
# - Possibly set up pass password manager for management of
#   contianer passwords
# - Possibly add an alias lsper which lists la -al permission
#   property columns
#
# server-setup script is set to fail if any commands
# in the pipeline return a non zero this is done for
# a few reasons. Modify the set options at your
# own risk!
#
# LEGAL DISCLAIMER: This script is provided in the hope that it 
# may be useful, but with no warranty, expressed or implied, 
# and with no guarantee of support or future upgrades.
#
###################################################################

###################################################################
# File definitions and variables
###################################################################
version="1.00"
varname="null"
RED="\\033[0;31m"
GREEN="\\033[0;32m"
ENDCOLOR="\\x1b[0m"

sysctlFile="/etc/sysctl.conf"

sysctlSecurity=(
"net.ipv4.ip_unprivileged_port_start=80"
"net.ipv4.conf.default.rp_filter=1"
"net.ipv4.conf.all.rp_filter=1"
"net.ipv4.conf.all.accept_redirects=0"
"net.ipv6.conf.all.accept_redirects=0"
"net.ipv4.conf.all.send_redirects=0"
"net.ipv4.conf.all.accept_source_route=0"
"net.ipv6.conf.all.accept_source_route=0"
"net.ipv4.conf.all.log_martians=1"
"net.ipv4.conf.all.arp_notify=1")

autoUpdateBackupScript="#!/bin/bash
################################################
# v1.00
# Automatic Update and Backup Script
# Auto-generated from server-setup.sh script
# by C-4422
#
# This script by default is called on the first
# Wednesday of every month by SystemD
#
# Call all scripts found in the backups/scripts
# folder and then call podman auto-update
################################################
set -eo pipefail
count=0
for f in ~/backups/scripts/*.sh; do
    let \"count+=1\"
    echo \"Step \$counter. Entering script \$f\"
	bash \"\$f\"
done
podman auto-update"

lsPerCommand="-rw-r--r-- 12 linuxize users 12.0K Apr  28 10:10 file_name
|[-][-][-]-   [------] [---]
| |  |  | |      |       |
| |  |  | |      |       +-----------> 7. Group
| |  |  | |      +-------------------> 6. Owner
| |  |  | +--------------------------> 5. Alternate Access Method
| |  |  +----------------------------> 4. Others Permissions
| |  +-------------------------------> 3. Group Permissions
| +----------------------------------> 2. Owner Permissions
+------------------------------------> 1. File Type"

lrAlias=("# Alias's created by C-4422 Setup Script"
"alias lsper='cat ~/.bashrc.d/permissions.txt'")

########################################
# FUNCTION
#   print_logo
########################################
print_logo() {
    # C-4422 pixel art routine, not important for execution
    otterPixelArt=("oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo"
    "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo"
    "oooo" "oooo" "oooo" "6TIM" "6TIM" "6TIM" "6TIM" "oooo" "oooo" "oooo" "oooo" "6TIM" "6TIM" "6TIM" "6TIM" "6TIM" "6TIM" "6TIM" "6TIM" "oooo" "oooo" "oooo" "oooo" "6TIM" "6TIM" "6TIM" "6TIM" "oooo" "oooo" "oooo"
    "oooo" "oooo" "6TIM" "GGJ3" "6TIM" "GGJ3" "GGJ3" "6TIM" "oooo" "6TIM" "6TIM" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "6TIM" "6TIM" "oooo" "6TIM" "GGJ3" "GGJ3" "6TIM" "GGJ3" "6TIM" "oooo" "oooo"
    "oooo" "6TIM" "GGJ3" "GGJ3" "X[K0" "6TIM" "GGJ3" "GGJ3" "6TIM" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "6TIM" "GGJ3" "GGJ3" "6TIM" "X[K0" "GGJ3" "GGJ3" "6TIM" "oooo"
    "oooo" "6TIM" "GGJ3" "X[K0" "X[K0" "X[K0" "6TIM" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "6TIM" "X[K0" "X[K0" "X[K0" "GGJ3" "6TIM" "oooo"
    "oooo" "6TIM" "GGJ3" "X[K0" "X[K0" "6TIM" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "6TIM" "X[K0" "X[K0" "GGJ3" "6TIM" "oooo"
    "oooo" "6TIM" "GGJ3" "GGJ3" "X[K0" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "X[K0" "GGJ3" "GGJ3" "6TIM" "oooo"
    "oooo" "oooo" "6TIM" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "6TIM" "oooo" "oooo"
    "oooo" "oooo" "oooo" "6TIM" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "6TIM" "oooo" "oooo" "oooo"
    "oooo" "oooo" "6TIM" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "6TIM" "oooo" "oooo"
    "oooo" "oooo" "6TIM" "GGJ3" "GGJ3" "GGJ3" "!!!!" "!!!!" "!!!!" "!!!!" "!!!!" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "!!!!" "!!!!" "!!!!" "!!!!" "!!!!" "GGJ3" "GGJ3" "GGJ3" "6TIM" "oooo" "oooo"
    "oooo" "6TIM" "GGJ3" "GGJ3" "GGJ3" "!!!!" "!!!!" "!!!!" "!!!!" "````" "!!!!" "!!!!" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "!!!!" "!!!!" "!!!!" "!!!!" "````" "!!!!" "!!!!" "GGJ3" "GGJ3" "GGJ3" "6TIM" "oooo"
    "oooo" "6TIM" "GGJ3" "GGJ3" "GGJ3" "!!!!" "!!!!" "!!!!" "!!!!" "!!!!" "!!!!" "!!!!" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "!!!!" "!!!!" "!!!!" "!!!!" "!!!!" "!!!!" "!!!!" "GGJ3" "GGJ3" "GGJ3" "6TIM" "oooo"
    "oooo" "6TIM" "GGJ3" "GGJ3" "GGJ3" "!!!!" "!!!!" "!!!!" "!!!!" "!!!!" "!!!!" "!!!!" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "GGJ3" "!!!!" "!!!!" "!!!!" "!!!!" "!!!!" "!!!!" "!!!!" "GGJ3" "GGJ3" "GGJ3" "6TIM" "oooo"
    "oooo" "6TIM" "GGJ3" "X[K0" "X[K0" "X[K0" "!!!!" "!!!!" "!!!!" "!!!!" "!!!!" "GGJ3" "04=V" "04=V" "04=V" "04=V" "04=V" "04=V" "GGJ3" "!!!!" "!!!!" "!!!!" "!!!!" "!!!!" "X[K0" "X[K0" "X[K0" "GGJ3" "6TIM" "oooo"
    "oooo" "6TIM" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "04=V" "04=V" "04=V" "04=V" "04=V" "04=V" "04=V" "04=V" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "6TIM" "oooo"
    "6TIM" "GGJ3" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "04=V" "04=V" "04=V" "04=V" "04=V" "04=V" "04=V" "04=V" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "GGJ3" "6TIM"
    "6TIM" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "04=V" "04=V" "04=V" "04=V" "04=V" "04=V" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "6TIM"
    "6TIM" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "04=V" "04=V" "04=V" "04=V" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "6TIM"
    "6TIM" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "6TIM" "6TIM" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "6TIM"
    "6TIM" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "6TIM" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "6TIM" "6TIM" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "6TIM" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "6TIM"
    "6TIM" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "6TIM" "6TIM" "6TIM" "6TIM" "6TIM" "X[K0" "X[K0" "6TIM" "6TIM" "6TIM" "6TIM" "6TIM" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "6TIM"
    "6TIM" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "6TIM"
    "6TIM" "GGJ3" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "GGJ3" "6TIM"
    "oooo" "6TIM" "GGJ3" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "GGJ3" "6TIM" "oooo"
    "oooo" "oooo" "6TIM" "6TIM" "GGJ3" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "GGJ3" "6TIM" "6TIM" "oooo" "oooo"
    "oooo" "oooo" "oooo" "oooo" "6TIM" "GGJ3" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "GGJ3" "6TIM" "oooo" "oooo" "oooo" "oooo"
    "oooo" "oooo" "oooo" "oooo" "oooo" "6TIM" "6TIM" "6TIM" "6TIM" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "6TIM" "6TIM" "6TIM" "6TIM" "oooo" "oooo" "oooo" "oooo" "oooo"
    "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "6TIM" "GGJ3" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "X[K0" "GGJ3" "6TIM" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo" "oooo")
    count=0
    for i in "${otterPixelArt[@]}"
    do
        case "$i" in
            "oooo")
                # Transparent
                printf "  "
                ;;
            "!!!!")
                # Black
                printf "\x1b[38;2;0;0;0m██\x1b[0m"
                ;;
            "6TIM")
                # Dark Brown
                printf "\x1b[38;2;87;58;44m██\x1b[0m"
                ;;
            "GGJ3")
                # Brown
                printf "\x1b[38;2;154;106;82m██\x1b[0m"
                ;;
            "04=V")
                # Gray
                printf "\x1b[38;2;61;55;53m██\x1b[0m"
                ;;
            "````")
                # White
                printf "\x1b[38;2;255;255;255m██\x1b[0m"
                ;;
            "X[K0")
                # Light Brown
                printf "\x1b[38;2;233;170;143m██\x1b[0m"
                ;;
        esac
        let "count+=1"
        if (( $count % 30 == 0 ))
        then
            printf "\n"
        fi
    done
    # End of unimportant pixel art routine
}

########################################
# FUNCTION
#   select_user()
########################################
select_user() {
    echo "Enter the unprivileged username you"
    echo "will be running your podman applications on:"
    echo "--------------------------------------------"
    read -r -p "Username: " varname
    if id -u "$varname" >/dev/null 2>&1; then
        echo "The user $varname will be configured"
        read -r -p "for rootless podman. Is this correct? y/n: " isContinue
        if [[ "$isContinue" =~ ^[Yy]$ ]]; then
            printf "${GREEN}Beginning set up.\n${ENDCOLOR}"
        else
            printf "${RED}Exiting script\n${ENDCOLOR}"
            exit 1
        fi
    else
        echo "User does not exist. Script cannot continue"
        echo "without a valid user. Would you like to create"
        read -r -p "the user: $varname y/n:" createuser
        if [[ "$createuser" =~ ^[Yy]$ ]]; then
            echo "Creating user $varname"
            sudo useradd "$varname"
            sudo passwd "$varname"
            printf "${GREEN}Beginning set up.\n${ENDCOLOR}"
        else
            printf "${RED}Exiting script, rerun script with a valid username\n${ENDCOLOR}"
            printf "${RED}to continue\n${ENDCOLOR}"
            exit 1
        fi
    fi
}


########################################
# FUNCTION
#   step_1()
########################################
step_1() {
    echo "--------------------------------------------"
    echo "Step 1: Add selected user to sudo group,"
    echo "        install all necessary programs."
    echo "        Configure folders for podman"
    echo "        persistent storage"
    echo "--------------------------------------------"
    sudo usermod -aG wheel "$varname"
    sudo dnf install epel-release -y
    sudo dnf update -y
    sudo dnf install make crun podman pass cockpit fail2ban dialog gpg sed -y
    echo "Enable cockpit service"
    sudo systemctl enable cockpit.socket
    sudo systemctl start cockpit.socket
    echo "Set podman container application persistent storage"
    echo "srv folder."
    
    # Set SRV_LOCATION user environment variable
    srvLocation=$(sudo -u $varname echo "$SRV_LOCATION")
    if [[ $srvLocation != "" ]] ; then
        echo "User environment variable SRV_LOCATION already exists"
        isConfigured=true
    else
        echo "SRV_LOCATION is not set, setting default srv location."
        echo "Note that if you set a custom location it has to already"
        echo "exist"
        srvLocation="/srv/$varname"
        isConfigured=false
    fi

    isSrvCorrect="n"
    while [[ ! "$isSrvCorrect" =~ ^[Yy]$ ]]; do
        read -r -p "SRV_LOCATION=$srvLocation is this correct? y/n: " isSrvCorrect
        if [[ "$isSrvCorrect" =~ ^[Nn]$ ]] ; then
            read -r -p "srv Location: " srvLocation
        fi
    done

    if [ "$SRV_LOCATION" != "$srvLocation" ] && $isConfigured; then
        sudo -u $varname sed -i 's;^export SRV_LOCATION=.*;export SRV_LOCATION='"$srvLocation"';' /home/$varname/.bashrc
        echo "Change SRV_LOCATION to $srvLocation"
    elif [[ $isConfigured = false ]]; then
        echo "set SRV_LOCTION to $srvLocation"
        sudo -u $varname echo "export SRV_LOCATION=$srvLocation" >> /home/$varname/.bashrc
        echo "SRV_LOCTION set to $srvLocation"
        if [[ "$srvLocation" == "/srv/$varname" ]]; then
            echo "Make /srv/$varname directory"
            sudo mkdir -p -- "/srv"
            sudo mkdir -p -- "/srv/$varname"
        fi
    fi
    # sudo chown $varname:$varname $srvLocation

    # Set STORAGE_LOCATION
    storageLocation=$(sudo -u $varname echo "$STORAGE_LOCATION")
    if [[ $storageLocation != "" ]] ; then
        echo "User environment variable STORAGE_LOCATION already exists"
        isConfigured=true
    else
        echo "STORAGE_LOCATION is not set, use default storage location?"
        echo "Note that the default storage location will install on the"
        echo "root of the OS drive. If you have a second hard drive you"
        echo "would like to use for storage make sure it is mounted and"
        echo "enter the absolute path to a folder that already exists."
        storageLocation="/storage/$varname"
        isConfigured=false
    fi

    isStorageCorrect="n"
    while [[ ! "$isStorageCorrect" =~ ^[Yy]$ ]]; do
        read -r -p "STORAGE_LOCATION=$storageLocation is this correct? y/n: " isStorageCorrect
        if [[ "$isStorageCorrect" =~ ^[Nn]$ ]] ; then
            read -r -p "storage Location: " storageLocation
        fi
    done

    if [ "$STORAGE_LOCATION" != "$storageLocation" ] && $isConfigured; then
        sudo -u $varname sed -i 's;^export STORAGE_LOCATION=.*;export STORAGE_LOCATION='"$storageLocation"';' /home/$varname/.bashrc
        echo "Change STORAGE_LOCATION to $storageLocation"
    elif [[ $isConfigured = false ]]; then
        echo "set STORAGE_LOCATION to $storageLocation"
        sudo -u $varname echo "export STORAGE_LOCATION=$storageLocation" >> /home/$varname/.bashrc
        echo "STORAGE_LOCATION set to $storageLocation"
        if [[ "$storageLocation" == "/storage/$varname" ]]; then
            echo "Make /storage/$varname directory"
            sudo mkdir -p -- "/storage"
            sudo mkdir -p -- "/storage/$varname"
        fi
    fi

    printf "${GREEN}Completed Step 1\n\n${ENDCOLOR}"
}

########################################
# FUNCTION
#   step_2()
########################################
step_2() {
    echo "--------------------------------------------"
    echo "Step 2: Enable software services, verify"
    echo "        sudo is enabled"
    echo "--------------------------------------------"
    echo "Confirm wheel is in sudo group"
    sudo sed -i 's/# %wheel  ALL=(ALL)       ALL/%wheel  ALL=(ALL)       ALL/' /etc/sudoers
    echo "Enable fail2ban service"
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban

    echo "Enable basic security measures"
    for i in "${sysctlSecurity[@]}"
    do
        parameter=$(sudo sysctl "$i")
        if [[ "$parameter" != "$i" ]]; then
            sudo /bin/su -c "echo '$i' >> /etc/sysctl.conf"
        fi
    done

    printf "${GREEN}Completed Step 2\n\n${ENDCOLOR}"
}

########################################
# FUNCTION
#   step_3()
########################################
step_3() {
    echo "--------------------------------------------"
    echo "Step 3: Configure systemd user settings,"
    echo "        configure podman to use fuse-fs."
    echo "--------------------------------------------"
    echo "Configure $varname user systemd folder"

    sudo -u "$varname" mkdir -p -- "/home/$varname/.config"
    sudo -u "$varname" mkdir -p -- "/home/$varname/.config/systemd"
    sudo -u "$varname" mkdir -p -- "/home/$varname/.config/systemd/user"

    echo "Enable user systemd startup and persist settings"
    sudo loginctl enable-linger "$varname"
    echo "Enable fuse-overlay file system fo use with rootless podman"
    sudo sed -i 's/#mount_program = "\/usr\/bin\/fuse-overlayfs"/mount_program = "\/usr\/bin\/fuse-overlayfs"/' /etc/containers/storage.conf

    printf "${GREEN}Completed Step 3\n\n${ENDCOLOR}"
}

########################################
# FUNCTION
#   step_4()
########################################
step_4() {
    echo "--------------------------------------------"
    echo "Step 4: Configure pass password manager"
    echo "--------------------------------------------"
    echo "Configure pass? A basic password manager"
    echo "extremely useful for managing server"
    read -r -p "application passwords, y/n:" isPass
    if [[ "$isPass" =~ ^[Yy]$ ]]; then
        gpgKey=$(sudo -u "$varname" gpg --list-secret-keys --keyid-format LONG)
        if [ "$gpgKey" == "" ]; then
            printf "${RED}When prompted for the following:\n${ENDCOLOR}"
            printf "${RED}    1. 'Your selection?' hit enter to select default\n${ENDCOLOR}"
            printf "${RED}    2. 'What key size do you want' hit enter to select default\n${ENDCOLOR}"
            printf "${RED}    3. 'Key is valid for? (0)' hit enter to select default\n${ENDCOLOR}"
            printf "${RED}It will then ask you if this is correct enter y\n${ENDCOLOR}"
            printf "${RED}You will then be prompted to enter your name and password\n${ENDCOLOR}"
            printf "${RED}Password can be whatever you want make it something somewhat easy to type\n${ENDCOLOR}"
            read -n 1 -s -r -p "Press any key to continue to GPG password creation:"
            sudo -u "$varname" gpg --full-generate-key
            gpgKey=$(sudo -u "$varname" gpg --list-secret-keys --keyid-format LONG)
        fi
        sudo -u "$varname" gpg --list-secret-keys --keyid-format LONG
        gpgKey=$(printf "%.21s" "${gpgKey#*rsa}")
        gpgKey=$(printf "%.16s" "${gpgKey#*\/}")
        read -r -p "Is the following key correct: $gpgKey: y/n:" isCorrect
        if [[ "$isCorrect" =~ ^[Nn]$ ]]; then
            gpgKey=""
        fi
        while sudo -u "$varname" ! pass init "$gpgKey" ; do
            echo "Key ID incorrect enter correct key"
            sudo -u "$varname" gpg --list-secret-keys --keyid-format LONG
            read -r -p "KeyID = " gpgKey 
        done
    else
        echo "Skipping pass configuration, you can always"
        echo "set this up later using gpg and pass init"
    fi

    printf "${GREEN}Completed Step 4\n\n${ENDCOLOR}"
}

########################################
# FUNCTION
#   step_5()
########################################
step_5() {
    echo "--------------------------------------------"
    echo "Step 5: Configure automatic updates and"
    echo "        backup service."
    echo "--------------------------------------------"
    echo "Configure folder structure for automatic"
    echo "container updates and backups."
    sudo -u "$varname" mkdir -p -- "/home/$varname/backups"
    sudo -u "$varname" mkdir -p -- "/home/$varname/backups/service"
    sudo -u "$varname" mkdir -p -- "/home/$varname/backups/scripts"

    backupScriptLocation="/home/$varname/backups/service/update-backup-main.sh"
    updateServiceLocation="/home/$varname/.config/systemd/user/container-update.service"
    updateTimerLocation="/home/$varname/.config/systemd/user/container-update.timer"
    if [ -f "$backupScriptLocation" ]; then
        echo "Notice: $backupScriptLocation file exists"
        echo "======"
        echo "Because this file exists, assume it should not be modified or"
        echo "changed. This is done to preserve user settings."
        echo "======"
    else
        echo "Create update-backup-main.sh to run backup scripts"
        sudo -u "$varname" echo "" >> "$backupScriptLocation"
        sudo chmod +x "$backupScriptLocation"
    fi

    if [ -f "$updateServiceLocation" ]; then
        echo "Notice: $updateServiceLocation file exists"
        echo "======"
        echo "Because this file exists, assume it should not be modified or"
        echo "changed. This is done to preserve user settings."
        echo "======"
    else
        serviceD="[Unit]
Description=Auto backup and update Podman containers
After=network.target

[Service]
WorkingDirectory=/home/$varname/backups/service/
Type=oneshot
ExecStart=/bin/bash $backupScriptLocation

[Install]
WantedBy=multi-user.target"
        echo "Create container-update.service for systemD"
        sudo -u "$varname" echo "$serviceD" >> "$updateServiceLocation"
    fi

    if [ -f "$updateTimerLocation" ]; then
        echo "Notice: $updateTimerLocation file exists"
        echo "======"
        echo "Because this file exists, assume it should not be modified or"
        echo "changed. This is done to preserve user settings."
        echo "======"
    else
        timerD="[Unit]
Description=Timer for podman auto backup and update

[Timer]
OnCalendar=Wed *-*-1..7 2:00:00

[Install]
WantedBy=multi-user.target"
        echo "Create container-update.timer for systemD"
        sudo -u "$varname" echo "$timerD" >> "$updateTimerLocation"
    fi
    printf "${GREEN}Completed step 5\n${ENDCOLOR}"
}

########################################
# FUNCTION
#   step_6()
########################################
step_6() {
    echo "--------------------------------------------"
    echo "Step 6: Add lsper alias to .bashrc"
    echo "--------------------------------------------"
    echo "Adding command lsper to .bashrc, this is not"
    echo "crucial to system function. lsper stands for"
    echo "list permissions. The idea is that after ls -al"
    echo "you can types lsper which will tell you what the"
    echo "columns mean."
    read -r -p "Install lsper alias? y/n:" isLsper
    if [[ "$isLsper" =~ ^[Yy]$ ]]; then
        lsPerLocation="/home/$varname/.bashrc.d/permissions.txt"
        sudo -u "$varname" mkdir -p -- "/home/$varname/.bashrc.d"
        if [ -f "$lsPerLocation" ]; then
            sudo -u "$varname" rm "$lsPerLocation"
        fi
        sudo -u "$varname" echo "$lsPerCommand" >> "$lsPerLocation"

        for i in "${lrAlias[@]}"
        do
            if ! grep "$i" -q /home/$varname/.bashrc; then
                echo "$i" >> /home/$varname/.bashrc
            fi
        done
        echo "Successfully installed lsper alias"
        printf "${GREEN}Completed step 6\n${ENDCOLOR}"
    else
        echo "Skipping lsper alias"
    fi
}

###################################################################
# SCRIPT MAIN BODY
###################################################################

set -eo pipefail

echo "--------------------------------------------"
echo "Server setup script v$version by C-4422"
echo "============================================"

print_logo
select_user
step_1
step_2
step_3
step_4
step_5
step_6

printf "${GREEN}Setup completed succesfully!\n${ENDCOLOR}"
read -r -p "Reboot required. Reboot now? y/n:" isReboot
if [[ "$isReboot" =~ ^[Yy]$ ]]; then
    echo "Rebooting"
    sudo reboot
else
    echo "Exiting script, goodbye"
fi

# Reload bashrc to update current environment variables if
# we haven't rebooted
exec bash