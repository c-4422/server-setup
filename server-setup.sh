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
# - Set kernel parmaters for rootless and possibly additional 
#   security
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
version="1.0.0"
varname="null"
RED="\\033[0;31m"
GREEN="\\033[0;32m"
ENDCOLOR="\\x1b[0m"

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
if [ \"\$(ls -A ~/backups/scripts)\" ]; then
    for f in ~/backups/scripts/*.sh; do
        let \"count+=1\"
        echo \"Step \$count. Entering script \$f\"
        bash \"\$f\"
    done
fi
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
    otterPixelArt=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 0 0
0 1 2 1 2 2 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 2 2 1 2 1 0
1 2 2 3 1 2 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 2 2 1 3 2 2 1
1 2 3 3 3 1 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 1 3 3 3 2 1
1 2 3 3 1 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 1 3 3 2 1
1 2 2 3 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 3 2 2 1
0 1 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 1 0
0 0 1 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 1 0 0
0 0 1 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 1 0 0
0 0 1 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 1 0 0
0 1 2 2 2 4 4 4 4 4 2 2 2 2 2 2 2 2 2 2 4 4 4 4 4 2 2 2 1 0
0 1 2 2 4 4 4 4 5 4 4 2 2 2 2 2 2 2 2 4 4 4 4 5 4 4 2 2 1 0
0 1 2 2 4 4 4 4 4 4 4 2 2 2 2 2 2 2 2 4 4 4 4 4 4 4 2 2 1 0
0 1 2 3 4 4 4 4 4 4 4 2 2 2 2 2 2 2 2 4 4 4 4 4 4 4 3 2 1 0
1 3 3 3 3 4 4 4 4 4 3 2 6 6 6 6 6 6 2 3 4 4 4 4 4 3 3 3 3 1
1 3 3 3 3 3 3 3 3 3 3 6 7 7 7 7 7 7 6 3 3 3 3 3 3 3 3 3 3 1
1 3 3 3 3 3 3 3 3 3 3 7 7 7 7 7 7 7 7 3 3 3 3 3 3 3 3 3 3 1
1 3 3 3 3 3 3 3 3 3 3 3 7 7 7 7 7 7 3 3 3 3 3 3 3 3 3 3 3 1
1 3 3 3 3 3 3 3 3 3 3 3 3 7 7 7 7 3 3 3 3 3 3 3 3 3 3 3 3 1
1 3 3 3 3 3 3 3 3 3 3 3 3 3 1 1 3 3 3 3 3 3 3 3 3 3 3 3 3 1
1 3 3 3 3 3 3 3 1 3 3 3 3 3 1 1 3 3 3 3 3 1 3 3 3 3 3 3 3 1
1 3 3 3 3 3 3 3 3 1 1 1 1 1 3 3 1 1 1 1 1 3 3 3 3 3 3 3 3 1
1 8 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 8 1
0 1 8 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 8 1 0
0 1 1 8 8 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 8 8 1 1 0
0 0 0 1 1 8 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 8 1 1 0 0 0
0 0 0 0 0 1 1 1 8 3 3 3 3 3 3 3 3 3 3 3 3 8 1 1 1 0 0 0 0 0
0 0 0 0 0 0 0 0 1 1 3 3 3 3 3 3 3 3 3 3 1 1 0 0 0 0 0 0 0 0)
    count=0
    for i in "${otterPixelArt[@]}"
    do
        case $i in
            0)
                # Transparent
                echo -en "  "
                ;;
            1)
                # Dark Brown
                echo -en "\x1b[38;2;87;58;44m██\x1b[0m"
                ;;
            2)
                # Brown
                echo -en "\x1b[38;2;154;106;82m██\x1b[0m"
                ;;
            3)
                # Gray
                echo -en "\x1b[38;2;239;187;167m██\x1b[0m"
                ;;
            4)
                # Black
                echo -en "\x1b[38;2;0;0;0m██\x1b[0m"
                ;;
            5)
                # White
                echo -en "\x1b[38;2;255;255;255m██\x1b[0m"
                ;;
            6)
                # Light Pink
                echo -en "\x1b[38;2;254;124;160m██\x1b[0m"
                ;;
            7)
                # Darker Pink
                echo -en "\x1b[38;2;186;91;117m██\x1b[0m"
                ;;
            8)
                # Shading Brown
                echo -en "\x1b[38;2;154;106;82m██\x1b[0m"
                ;;

        esac
        let "count+=1"
        if (( $count % 30 == 0 ))
        then
            echo -en "\n"
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
            echo -e "${GREEN}Beginning set up.${ENDCOLOR}"
        else
            echo -e "${RED}Exiting script${ENDCOLOR}"
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
            echo -e "${GREEN}Beginning set up.${ENDCOLOR}"
        else
            echo -e "${RED}Exiting script, rerun script with a valid username${ENDCOLOR}"
            echo -e "${RED}to continue${ENDCOLOR}"
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
    echo "        Enable software services, verify"
    echo "        sudo is enabled."
    echo "        Enable cockpit and Fail2ban."
    echo "--------------------------------------------"
    sudo usermod -aG wheel "$varname"
    sudo dnf install epel-release -y
    sudo dnf update -y
    sudo dnf install make crun podman pass cockpit cockpit-storaged cockpit-podman fail2ban dialog gpg sed -y
    echo "Enable cockpit service"
    sudo systemctl enable cockpit.socket
    sudo systemctl start cockpit.socket

    echo "Confirm wheel is in sudo group"
    sudo sed -i 's/# %wheel  ALL=(ALL)       ALL/%wheel  ALL=(ALL)       ALL/' /etc/sudoers
    echo "Enable fail2ban service"
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban

    echo -en "${GREEN}Completed Step 1\n\n${ENDCOLOR}"
}

########################################
# FUNCTION
#   step_2()
########################################
step_2() {
    echo "--------------------------------------------"
    echo "     2: Modify kernel parameters so that"
    echo "        port 80 is usable with rootless"
    echo "        podman."
    echo "        Enable / Disable additional kernel"
    echo "        parameters for added security."
    echo "--------------------------------------------"

    numEnabledSecurityParams=0

    sysParams="/etc/sysctl.d/c-4422_server_kernel_parameters.conf"

    sysctlSecurity=(
"net.ipv4.conf.default.rp_filter" "1"
"net.ipv4.conf.all.rp_filter" "1"
"net.ipv4.conf.all.accept_redirects" "0"
"net.ipv6.conf.all.accept_redirects" "0"
"net.ipv4.conf.all.send_redirects" "0"
"net.ipv4.conf.all.accept_source_route" "0"
"net.ipv6.conf.all.accept_source_route" "0"
"net.ipv4.conf.all.log_martians" "1"
"net.ipv4.conf.all.arp_notify" "1")

    basicKernelParam="################################################
# Server Kernel Parameter File
# 
# by C-4422
#
# Basic kernel parameters for rootless podman
# and security if enabled. Parameters used for
# security, specifically preventing man in the 
# middle attacks, can potentially mess with 
# networking tasks e.g. if you plan on using 
# your server for network routing. Hopefully 
# you won't need to edit this file yourself.
#
# auto-generated from server-setup.sh
################################################

# Unprivileged port start at 80 is necessary for 
# rootless podman this parameter shouldn't be changed
net.ipv4.ip_unprivileged_port_start=80

# The following parameters are meant for added security
# and can be commented out if needed

# Uncomment the next two lines to enable Spoof protection (reverse-path filter)
# Turn on Source Address Verification in all interfaces to
# prevent some spoofing attacks
#net.ipv4.conf.default.rp_filter=1
#net.ipv4.conf.all.rp_filter=1

# Do not accept ICMP redirects (prevent MITM attacks)
#net.ipv4.conf.all.accept_redirects=0
#net.ipv6.conf.all.accept_redirects=0

# Do not send ICMP redirects (we are not a router)
#net.ipv4.conf.all.send_redirects=0

# Do not accept IP source route packets (we are not a router)
#net.ipv4.conf.all.accept_source_route=0
#net.ipv6.conf.all.accept_source_route=0

# Log Martian Packets
#net.ipv4.conf.all.log_martians=1

# Send gratitous ARP when device change
#net.ipv4.conf.all.arp_notify=1"

    if [ -f $sysParams ]; then
        echo "$sysParams file exists."
    else
        echo "Create $sysParams"
        echo "Set unprivileged port start to 80"
        sudo /bin/su -c "echo '$basicKernelParam' >> $sysParams"
    fi
    
    for (( i=0; i<${#sysctlSecurity[@]}; i=i+2 ))
    do
        if grep -q "^${sysctlSecurity[$i]}=${sysctlSecurity[$i+1]}" $sysParams; then
            numEnabledSecurityParams=$(($numEnabledSecurityParams+1))
        fi
    done

    securityStatus="disabled"
    # Check to see if number of enabled security parameters equals the
    # total number of stored security parameters
    totalSecurityParams=$((${#sysctlSecurity[@]}/2))

    if [[ $numEnabledSecurityParams -eq $totalSecurityParams ]]; then
        securityStatus="enabled"
    elif [[ $numEnabledSecurityParams -gt 0 ]]; then
        securityStatus="partially enabled"
    fi

    echo ""
    echo "Currently additional security measures are $securityStatus."
    echo "Additional security is used for mitigating / preventing"
    echo "man in the middle network attacks. These security measures"
    echo "are not strictly required."
    echo -e "${RED}NOTE: If you plan on running Pi-hole or a DNS server do${ENDCOLOR}"
    echo -e "${RED}      not enable additional security parameters, it will${ENDCOLOR}"
    echo -e "${RED}      cause said applications to not work.${ENDCOLOR}"
    echo -e "Select to enable disable or leave as is (Current status: ${RED}$securityStatus${ENDCOLOR})"
    read -r -p " [Enable=e, Disable=d, default (leave as is)=l]:" selection

    case "$selection" in
    "e")
        for (( i=0; i<${#sysctlSecurity[@]}; i=i+2 ))
        do
            if grep -q ${sysctlSecurity[$i]} $sysParams; then
                # Look for security parameters and enable them
                sudo /bin/su -c "sed -i '/${sysctlSecurity[$i]}/c\\${sysctlSecurity[$i]}=${sysctlSecurity[$i+1]}' $sysParams"
            else
                sudo /bin/su -c "echo '${sysctlSecurity[$i]}=${sysctlSecurity[$i+1]}' >> $sysParams"
            fi
        done
        ;;
    "d")
        for (( i=0; i<${#sysctlSecurity[@]}; i=i+2 ))
        do
            sudo /bin/su -c "sed -i '/${sysctlSecurity[$i]}/c\\#${sysctlSecurity[$i]}=${sysctlSecurity[$i+1]}' $sysParams"
        done
        ;;
    *)
        ;;
    esac

    echo -en "${GREEN}Completed Step 1\n\n${ENDCOLOR}"
}

########################################
# FUNCTION
#   step_3()
########################################
step_3() {
    echo "--------------------------------------------"
    echo "Step 3: Configure folders for podman"
    echo "        persistent storage"
    echo "--------------------------------------------"
    
    # Set SRV_LOCATION user environment variable
    srvLocation=$(sudo -u $varname sed -n 's;^export SRV_LOCATION=\(.*\).*;\1;p' /home/$varname/.bashrc)
    if [[ $srvLocation != "" ]] ; then
        echo "User environment variable SRV_LOCATION already exists"
        isConfigured=true
    else
        echo "---------------------------------------------------------------"
        echo "SRV_LOCATION is not set. The default srv location is:"
        echo "/srv/$varname"
        echo -e "${RED}Note that if you set a custom srv location the folder you${ENDCOLOR}"
        echo -e "${RED}specify should already exist${ENDCOLOR}"
        echo "---------------------------------------------------------------"
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
        sudo -u "$varname" sed -i 's;^export SRV_LOCATION=.*;export SRV_LOCATION='"$srvLocation"';' /home/"$varname"/.bashrc
        echo "Change SRV_LOCATION to $srvLocation"
    elif [[ $isConfigured = false ]]; then
        echo "set SRV_LOCTION to $srvLocation"
        sudo -u "$varname" echo "export SRV_LOCATION=$srvLocation" >> /home/$varname/.bashrc
        echo "SRV_LOCTION set to $srvLocation"
        if [[ "$srvLocation" == "/srv/$varname" ]]; then
            echo "Make /srv/$varname directory"
            sudo mkdir -p -- "/srv"
            sudo mkdir -p -- "/srv/$varname"
        fi
    fi
    if [ "$(ls -A $srvLocation)" ]; then
        echo -e "${RED}$srvLocation is not empty do not change ownership.${ENDCOLOR}"
    else
        sudo chown -R "$varname:$varname" "$srvLocation"
        echo "$srvLocation ownership changed to $varname"
    fi

    # Set STORAGE_LOCATION
    storageLocation=$(sudo -u "$varname" sed -n 's;^export STORAGE_LOCATION=\(.*\).*;\1;p' /home/"$varname"/.bashrc)
    if [[ $storageLocation != "" ]] ; then
        echo "User environment variable STORAGE_LOCATION already exists"
        isConfigured=true
    else
        echo "---------------------------------------------------------------"
        echo "STORAGE_LOCATION is not. The default storage location is:"
        echo "/storage/$varname"
        echo -e "${RED}Note that the default storage location will install on the${ENDCOLOR}"
        echo -e "${RED}root of the OS drive. If you have a second hard drive you${ENDCOLOR}"
        echo -e "${RED}would like to use for storage make sure it is mounted and${ENDCOLOR}"
        echo -e "${RED}enter the absolute path to the folder. Example:${ENDCOLOR}"
        echo "/mnt/Second-Drive/$varname"
        echo "---------------------------------------------------------------"
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
        sudo -u "$varname" sed -i 's;^export STORAGE_LOCATION=.*;export STORAGE_LOCATION='"$storageLocation"';' /home/"$varname"/.bashrc
        echo "Change STORAGE_LOCATION to $storageLocation"
    elif [[ $isConfigured = false ]]; then
        echo "set STORAGE_LOCATION to $storageLocation"
        sudo -u "$varname" echo "export STORAGE_LOCATION=$storageLocation" >> /home/"$varname"/.bashrc
        echo "STORAGE_LOCATION set to $storageLocation"
        if [[ "$storageLocation" == "/storage/$varname" ]]; then
            echo "Make /storage/$varname directory"
            sudo mkdir -p -- "/storage"
            sudo mkdir -p -- "/storage/$varname"
        fi
    fi
    if [ "$(ls -A "$storageLocation")" ]; then
        echo -en "${RED}$storageLocation is not empty do not change ownership.\n${ENDCOLOR}"
    else
        sudo chown -R "$varname:$varname" "$storageLocation"
        echo "$storageLocation ownership changed to $varname"
    fi

    echo -en "${GREEN}Completed Step 3\n\n${ENDCOLOR}"
}

########################################
# FUNCTION
#   step_4()
########################################
step_4() {
    echo "--------------------------------------------"
    echo "Step 4: Configure systemd user settings,"
    echo "        configure podman to use fuse-fs."
    echo "--------------------------------------------"
    echo "Configure $varname user systemd folder"

    sudo -u "$varname" mkdir -p -- "/home/$varname/.config"
    sudo -u "$varname" mkdir -p -- "/home/$varname/.config/systemd"
    sudo -u "$varname" mkdir -p -- "/home/$varname/.config/systemd/user"

    echo "Enable user systemd startup and persist settings"
    sudo loginctl enable-linger "$varname"
    echo "Enable fuse-overlay file system for use with rootless podman"
    sudo sed -i 's/#mount_program = "\/usr\/bin\/fuse-overlayfs"/mount_program = "\/usr\/bin\/fuse-overlayfs"/' /etc/containers/storage.conf
    echo "Enable rootless podman storage path: ~/.local/share/containers/storage"
    sudo sed -i '/rootless_storage_path/c\rootless_storage_path = "$HOME\/.local\/share\/containers\/storage"' /etc/containers/storage.conf

    echo -en "${GREEN}Completed Step 4\n\n${ENDCOLOR}"
}

########################################
# FUNCTION
#   step_4()
########################################
step_5() {
    echo "--------------------------------------------"
    echo "Step 5: Configure pass password manager"
    echo "--------------------------------------------"
    currentUser=$(whoami)
    if [[ "$currentUser" != "$varname" ]]; then
        echo -en "${RED}You need to be logged in as $varname\n${ENDCOLOR}"
        echo -en "${RED}in order to configure pass.\n${ENDCOLOR}"
        echo -en "${RED}Skipping Step 4\n\n${ENDCOLOR}"
    else
        echo "Configure pass? A basic password manager used"
        echo "to load in passwords for podman applications"
        echo "C-4422 has configured."
        read -r -p "HINT: you should set this up. Configure Pass? y/n: " isPass
        if [[ "$isPass" =~ ^[Yy]$ ]]; then
            gpgKey=$(gpg --list-secret-keys --keyid-format LONG)
            if [ "$gpgKey" == "" ]; then
                echo -e "${RED}When prompted for the following:${ENDCOLOR}"
                echo -e "${RED}    1. 'Your selection?' hit enter to select default${ENDCOLOR}"
                echo -e "${RED}    2. 'What key size do you want' hit enter to select default${ENDCOLOR}"
                echo -e "${RED}    3. 'Key is valid for? (0)' hit enter to select default${ENDCOLOR}"
                echo -e "${RED}It will then ask you if this is correct enter y${ENDCOLOR}"
                echo -e "${RED}You will then be prompted to enter your name and password.${ENDCOLOR}"
                echo -e "${RED}I advise you make the password something easy to type.${ENDCOLOR}"
                read -n 1 -s -r -p "Press any key to continue to GPG password creation:"
                gpg --full-generate-key
                gpgKey=$(gpg --list-secret-keys --keyid-format LONG)
            fi
            gpg --list-secret-keys --keyid-format LONG
            gpgKey=$(printf "%.21s" "${gpgKey#*rsa}")
            gpgKey=$(printf "%.16s" "${gpgKey#*\/}")
            read -r -p "Is the following key correct: $gpgKey: y/n:" isCorrect
            if [[ "$isCorrect" =~ ^[Nn]$ ]]; then
                gpgKey=""
            fi
            while ! pass init "$gpgKey" ; do
                echo "Key ID incorrect enter correct key"
                gpg --list-secret-keys --keyid-format LONG
                read -r -p "KeyID = " gpgKey 
            done
        else
            echo "Skipping pass configuration, you can always"
            echo "set this up later using this script or manually"
            echo "running gpg and pass init"
        fi

        echo -en "${GREEN}Completed Step 5\n\n${ENDCOLOR}"
    fi
}

########################################
# FUNCTION
#   step_6()
########################################
step_6() {
    echo "--------------------------------------------"
    echo "Step 6: Configure automatic updates and"
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
        sudo -u "$varname" echo "$autoUpdateBackupScript" >> "$backupScriptLocation"
        sudo chmod +x "$backupScriptLocation"
        sudo chown $varname:$varname $backupScriptLocation
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
    echo -en "${GREEN}Completed step 6\n${ENDCOLOR}"
}

########################################
# FUNCTION
#   step_7()
########################################
step_7() {
    echo "--------------------------------------------"
    echo "Step 7: Configure containers configuration"
    echo "        folder. The containers folder will"
    echo "        hold all of the makefiles used to"
    echo "        make podman applications and to hold"
    echo "        the various commands needed to run"
    echo "        the containers"
    echo "--------------------------------------------"
    echo "Making containers directory at:"
    echo "/home/$varname/containers"
    sudo -u "$varname" mkdir -p -- "/home/$varname/containers"
    read -r -p "HINT: you should download this file if you don't have it. Download master Makefile? y/n: " isDownload
    if [[ "$isDownload" =~ ^[Yy]$ ]]; then
        curl -o "/home/$varname/Makefile" https://raw.githubusercontent.com/c-4422/app-configs/main/Makefile
    fi
}

########################################
# FUNCTION
#   step_8()
########################################
step_8() {
    echo "--------------------------------------------"
    echo "Step 7: Add lsper alias to .bashrc"
    echo "--------------------------------------------"
    echo "Adding command lsper to .bashrc, this is not"
    echo "crucial to system function. lsper stands for"
    echo "list permissions. The idea is that after ls -al"
    echo "you can types lsper which will tell you what the"
    echo "columns mean."
    read -r -p "Install lsper alias? y/n: " isLsper
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
        echo -en "${GREEN}Completed step 7\n${ENDCOLOR}"
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

echo "============================================================"
echo "The following steps are available"
echo "============================================================"
echo "--------------------------------------------"
echo "     1: Add selected user to sudo group,"
echo "        install all necessary programs."
echo "        Enable software services, verify"
echo "        sudo is enabled."
echo "        Enable cockpit and Fail2ban."
echo "--------------------------------------------"
echo "     2: Modify kernel parameters so that"
echo "        port 80 is usable with rootless"
echo "        podman."
echo "        Enable / Disable additional kernel"
echo "        parameters for added security."
echo "--------------------------------------------"
echo "     3: Configure folders for podman"
echo "        persistent storage"
echo "--------------------------------------------"
echo "     4: Configure systemd user settings,"
echo "        configure podman to use fuse-fs."
echo "--------------------------------------------"
echo "     5: Configure pass password manager"
echo "--------------------------------------------"
echo "     6: Configure automatic updates and"
echo "        backup service."
echo "--------------------------------------------"
echo "     7: Configure containers configuration"
echo "        folder. The containers folder will"
echo "        hold all of the makefiles used to"
echo "        make podman applications and to hold"
echo "        the various commands needed to run"
echo "        the containers"
echo "--------------------------------------------"
echo "[OPTIONAL]"
echo "     8: Add lsper alias to .bashrc"
echo "--------------------------------------------"
read -r -p "Select the step you wish to execute (1-6, Default All=A):" stepSelect

case "$stepSelect" in
    "1")
        step_1
        ;;
    "2")
        step_2
        ;;
    "3")
        step_3
        ;;
    "4")
        step_4
        ;;
    "5")
        step_5
        ;;
    "6")
        step_6
        ;;
    "7")
        step_7
        ;;
    "8")
        step_8
        ;;
    *)
        # Default
        step_1
        step_2
        step_3
        step_4
        step_5
        step_6
        step_7
        step_8
        ;;
esac

echo -en "${GREEN}Setup completed succesfully!\n${ENDCOLOR}"
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