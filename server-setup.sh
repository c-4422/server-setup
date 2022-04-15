#!/bin/bash
###################################################################
# SERVER SETUP SCRIPT
#
#   Made in Kansas
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
version="1.1.0"
user_name="null"
RED="\\033[0;31m"
GREEN="\\033[0;32m"
ENDCOLOR="\\x1b[0m"

autoUpdateBackupScript="#!/bin/bash
################################################
# v1.0.1
# Automatic application update and backup Script
# Auto-generated from server-setup.sh script
# by C-4422
#
# This script by default is called on the first
# Wednesday of every month by SystemD
#
# Call all scripts found in the 
# .server/applications directory and then call 
# podman auto-update
################################################
set -eo pipefail
count=0
if [ \"\$(ls -A ~/.server/applications)\" ]; then
    for f in ~/.server/applications/*.sh; do
        let \"count+=1\"
        echo \"Step \$count. Entering script \$f\"
        bash \"\$f\"
    done
fi
podman auto-update"

lsper_command="-rw-r--r-- 12 linuxize users 12.0K Apr  28 10:10 file_name
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
"alias lsper='cat ~/.server/c-4422/permissions.txt'")
alias_location="/home/$user_name/.bashrc.d/server-aliases"

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
    read -r -p "Username: " user_name
    if id -u "$user_name" >/dev/null 2>&1; then
        echo "The user $user_name will be configured"
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
        read -r -p "the user: $user_name y/n: " createuser
        if [[ "$createuser" =~ ^[Yy]$ ]]; then
            echo "Creating user $user_name"
            sudo useradd "$user_name"
            sudo passwd "$user_name"
            echo -e "${GREEN}Beginning set up.${ENDCOLOR}"
        else
            echo -e "${RED}Exiting script, rerun script with a valid username${ENDCOLOR}"
            echo -e "${RED}to continue${ENDCOLOR}"
            exit 1
        fi
    fi

    # Set the alias location now that the username has been entered
    alias_location="/home/$user_name/.bashrc.d/server-aliases"
}

########################################
# FUNCTION
#   Install and configure for apt
########################################
apt_install() {
    sudo usermod -aG sudo "$user_name"
    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y make crun podman cockpit cockpit-storaged cockpit-podman fail2ban dialog gpg sed nano
}

########################################
# FUNCTION
#   Install and configure for dnf
########################################
dnf_install() {
    sudo usermod -aG wheel "$user_name"
    sudo dnf install epel-release -y
    sudo dnf update -y
    sudo dnf install make crun podman cockpit cockpit-storaged cockpit-podman fail2ban dialog gpg sed nano -y
    if ! sudo dnf install pass -y; then
        echo -en "${RED}NOTICE: Pass cannot be installed\n${ENDCOLOR}"
    fi
}

########################################
# FUNCTION
#   step_1()
########################################
step_1_comment="--------------------------------------------
     1: Add selected user to sudo group,
        install all necessary programs.
        Enable software services, verify
        sudo is enabled.
        Enable cockpit and Fail2ban."
step_1() {
    echo "$step_1_comment"
    echo "--------------------------------------------"
    if [ -x "$(command -v dnf)" ]; then
        dnf_install
    elif [ -x "$(command -v apt)" ]; then
        apt_install
    fi
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
step_2_comment="--------------------------------------------
     2: Modify kernel parameters so that
        port 80 is usable with rootless
        podman.
        Enable / Disable additional kernel
        parameters for added security."
step_2() {
    echo "$step_2_comment"
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
        echo "$basicKernelParam" | sudo tee "$sysParams"
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
    read -r -p " [Enable=e, Disable=d, default (leave as is)=l]: " selection

    case "$selection" in
    "e")
        for (( i=0; i<${#sysctlSecurity[@]}; i=i+2 ))
        do
            if grep -q ${sysctlSecurity[$i]} $sysParams; then
                # Look for security parameters and enable them
                sudo /bin/su -c "sed -i '/${sysctlSecurity[$i]}/c\\${sysctlSecurity[$i]}=${sysctlSecurity[$i+1]}' $sysParams"
            else
                echo "${sysctlSecurity[$i]}=${sysctlSecurity[$i+1]}" | sudo tee -a $sysParams
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

    echo -en "${GREEN}Completed Step 2\n\n${ENDCOLOR}"
}

########################################
# FUNCTION
#   step_3()
########################################
step_3_comment="--------------------------------------------
     3: Configure folders for podman
        persistent storage"
step_3() {
    echo "$step_3_comment"
    echo "--------------------------------------------"

    variables_location="/home/$user_name/.bashrc.d/server-variables"
    system_paths=("SRV_LOCATION" "STORAGE_LOCATION")
    default_srv_location="/srv/$user_name"
    default_storage_location="/storage/$user_name"
    srv_message="SRV_LOCATION is not set. The default srv location is:\n
$default_srv_location\n
${RED}Note that if you set a custom srv location the directory${ENDCOLOR}\n
${RED}specified should already exist${ENDCOLOR}"
    storage_message="STORAGE_LOCATION is not set. The default storage location is:\n
$default_storage_location\n
${RED}Note that the default storage location will install on the${ENDCOLOR}\n
${RED}root of the OS drive. If you have a second hard drive you${ENDCOLOR}\n
${RED}would like to use for storage make sure it is mounted and${ENDCOLOR}\n
${RED}enter the absolute path to the folder. Example:${ENDCOLOR}\n
/mnt/Second-Drive/$user_name"

    bashrc_code="# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f \"\$rc\" ]; then
			. \"\$rc\"
		fi
	done
fi"
    server_info_comment="# Alias used for server info"
    server_info_code="function server-info() {
echo \"Server configured on `date "+%Y/%m/%d"` by server-setup.sh version: $version\"
echo \"SERVER-VARIABLES FILE LOCATION:\"
echo \"$variables_location\"
system_paths=(\$(sed -n 's;^export \(.*\).*=\(.*\).*;\1;p' $variables_location))
echo \"+=============================+===================================\"
echo -e \"| VARIABLE\\t| LOCATION\" | expand -t 30
echo \"+=============================+===================================\"
for variable in \"\${system_paths[@]}\"; do
    location=(\$(sed -n 's;^export '\"\$variable\"'=\(.*\).*;\1;p' $variables_location))
    echo -e \"| \$variable\t| \$location\" | expand -t 30
    echo \"+-----------------------------+-----------------------------------\"
done
}

export -f server-info"

    # Create .bashrc.d if it doesn't exist
    if [ ! -d "/home/$user_name/.bashrc.d" ]; then
        echo "Creating .bashrc.d folder"
        sudo -u "$user_name" mkdir -p -- "/home/$user_name/.bashrc.d"
        echo "Enable .bashrc.d server-variables file"
        sudo -u "$user_name" echo "$bashrc_code" >> "/home/$user_name/.bashrc"
        sudo -u "$user_name" touch $variables_location
    fi

    # Read in all path variables from server-variables file if exists
    if [ -f "$variables_location" ]; then
        echo "Reading in location variables"
        # Only import unique variable names
        read_in=($(sed -n 's;^export \(.*\).*=\(.*\).*;\1;p' $variables_location))
        for entry in "${read_in[@]}"; do
            is_variable_found=false
            for variable in "${system_paths[@]}"; do
                if [[ $entry == $variable ]] ; then
                    is_variable_found=true
                fi
            done
            if ! $is_variable_found; then
                system_paths+=($entry)
            fi
        done
    fi

    # Set path variables
    index=$((0))
    while (( $index < ${#system_paths[@]} )); do
        location=""
        if [ -f "$variables_location" ]; then
            location=$(sudo -u $user_name sed -n 's;^export '"${system_paths[index]}"'=\(.*\).*;\1;p' $variables_location)
        fi
        isConfigured=false
        # Try to partition the statements so that the user can read the text for a
        # given server variable.
        if [[ $location != "" ]] ; then
            isConfigured=true
        elif [[ ${system_paths[index]} == "SRV_LOCATION" ]] ; then
            echo -e $srv_message
            location=$default_srv_location
        elif [[ ${system_paths[index]} == "STORAGE_LOCATION" ]] ; then
            echo -e $storage_message
            location=$default_storage_location
        fi

        variable_config_message=""
        if ! $isConfigured; then
            variable_config_message="${RED}[NOT SET]${ENDCOLOR}"
        fi

        echo "+=============================+==================================="
        echo -e "| VARIABLE\t| LOCATION" | expand -t 30
        echo "+=============================+==================================="
        echo -e "${system_paths[index]}\t|$variable_config_message $location" | expand -t 30
        echo "------------------------------+-----------------------------------"
        action="n"
        while [[ ! "$action" =~ ^[Yy]$ ]]; do
            if [[ $location != "" ]] ; then
	            read -r -p "Variable location correct? y/n: " action
            elif [[ $location != "" || "$action" =~ ^[Nn]$ ]] ; then
                read -r -p "Set ${system_paths[index]} location: " location
            fi
            if [[ "$action" == "" || "$action" =~ ^[Yy]$ ]] ; then
                if [[ $location == "" ]] ; then
                    echo -e "${RED}ERROR: VARIABLE DOES NOT HAVE A VALID LOCATION${ENDCOLOR}"
                    action="n"
                elif [[ "$location" == "$default_srv_location" || "$location" == "$default_storage_location" ]]; then
                    # If we are using the default locations go ahead and create
                    # the directories for the user
                    echo "Make $location directory"
                    sudo mkdir -p -- "$location"
                elif [ ! -d "$location" ] ; then
                    # Notify user that the selected directory does not exist
                    # ask to create directory
                    echo -e "${RED}WARNING LOCATION:${ENDCOLOR} $location"
                    read -r -p "Does not exist. Create directory? [y/n]: " create_dir
                    if [[ "$create_dir" =~ ^[Yy]$ ]]; then
                        echo "Make $location directory"
                        sudo mkdir -p -- "$location"
                    fi
                fi
            fi
        done

        # Write changes to file
        if $isConfigured; then
            echo "Change ${system_paths[index]} to $location"
            sudo -u "$user_name" sed -i 's;^export '"${system_paths[index]}"'=.*;export '"${system_paths[index]}"'='"$location"';' "$variables_location"
        else
            echo "Set ${system_paths[index]} to $location"
            sudo -u "$user_name" echo "export ${system_paths[index]}=$location" >> "$variables_location"
        fi

        # Change directory ownership if directory is empty
        if [ "$(ls -A $location)" ]; then
            echo -e "${RED}$location is not empty do not change ownership.${ENDCOLOR}"
        else
            sudo chown -R "$user_name:$user_name" "$location"
            echo "$location ownership changed to $user_name"
        fi

        # Add any additional user variables
        if (( $index == (${#system_paths[@]} - 1) )); then
            read -r -p "Would you like to add any additional variables? y/n: " isAddVariable
            if [[ "$isAddVariable" =~ ^[Yy]$ ]]; then
                read -r -p "Variable name: " variable_name
                system_paths+=("$variable_name")
            fi
        fi
        index=$((index + 1))
    done

    # Write the server-info function to the alias file if it does
    # not exist.
    if ! grep "$server_info_comment" -q "$alias_location"; then
        echo "$server_info_comment" >> "$alias_location"
        echo "$server_info_code" >> "$alias_location"
    fi

    echo -en "${GREEN}Completed Step 3\n\n${ENDCOLOR}"
}

########################################
# FUNCTION
#   step_4()
########################################
step_4_comment="--------------------------------------------
     4: Configure systemd user settings,
        configure podman to use fuse-fs."
step_4() {
    echo "$step_4_comment"
    echo "--------------------------------------------"
    echo "Configure $user_name user systemd folder"

    sudo -u "$user_name" mkdir -p -- "/home/$user_name/.config/systemd/user"

    echo "Enable user systemd startup and persist settings"
    sudo loginctl enable-linger "$user_name"
    echo "Enable fuse-overlay file system for use with rootless podman"
    sudo sed -i 's/#mount_program = "\/usr\/bin\/fuse-overlayfs"/mount_program = "\/usr\/bin\/fuse-overlayfs"/' /etc/containers/storage.conf
    echo "Enable rootless podman storage path: ~/.local/share/containers/storage"
    sudo sed -i '/rootless_storage_path/c\rootless_storage_path = "$HOME\/.local\/share\/containers\/storage"' /etc/containers/storage.conf

    echo -en "${GREEN}Completed Step 4\n\n${ENDCOLOR}"
}

########################################
# FUNCTION
#   step_5()
########################################
step_5_comment="--------------------------------------------
     5: Configure pass password manager"
step_5() {
    echo "$step_5_comment"
    echo "--------------------------------------------"
    currentUser=$(whoami)
    if [[ "$currentUser" != "$user_name" ]]; then
        echo -en "${RED}You need to be logged in as $user_name\n${ENDCOLOR}"
        echo -en "${RED}in order to configure pass.\n${ENDCOLOR}"
        echo -en "${RED}Skipping Step 5\n\n${ENDCOLOR}"
    else
        if ! [ -x "$(command -v pass)" ]; then
            echo -en "${RED}NOTICE: pass has not been installed\n${ENDCOLOR}"
            echo -en "${GREEN}No need to worry. You can still continue.\n${ENDCOLOR}"
            echo "You can possibly install pass later with your"
            echo "distribution's package manager OR... pass is not"
            echo "available for install. You can still run your"
            echo "server without pass, it just means your passwords"
            echo "will be stored in the secrets directory in plain"
            echo "text files which is totally fine."
            read -n 1 -s -r -p "Press any key to continue:"
            echo -en "${RED}\nSkipping Step 5\n\n${ENDCOLOR}"
        else
            echo "Configure pass? A basic password manager used"
            echo "to load in passwords for podman applications"
            echo "C-4422 has configured. If you have already"
            echo "configured pass or you do not want to use it"
            echo "enter N/n"
            read -r -p "Configure Pass? y/n: " isPass
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
                read -r -p "Enter gpg KeyID: " gpgKey
                while ! pass init "$gpgKey" ; do
                    echo "Key ID incorrect enter correct key"
                    gpg --list-secret-keys --keyid-format LONG
                    read -r -p "Enter gpg KeyID: " gpgKey
                done
            else
                echo "Skipping pass configuration, you can always"
                echo "set this up later using this script or manually"
                echo "running gpg and pass init"
            fi

            echo -en "${GREEN}Completed Step 5\n\n${ENDCOLOR}"
        fi
    fi
}

########################################
# FUNCTION
#   step_6()
########################################
step_6_comment="--------------------------------------------
     6: Configure automatic updates and
        backup service."
step_6() {
    echo "$step_6_comment"
    echo "--------------------------------------------"
    echo "Configure folder structure for automatic"
    echo "container updates and backups."
    sudo -u "$user_name" mkdir -p -- "/home/$user_name/.server/service"
    sudo -u "$user_name" mkdir -p -- "/home/$user_name/.server/applications"
    sudo -u "$user_name" mkdir -p -- "/home/$user_name/.server/incremental"

    backup_script_location="/home/$user_name/.server/service/update-backup-main.sh"
    update_service_location="/home/$user_name/.config/systemd/user/container-update.service"
    update_timer_location="/home/$user_name/.config/systemd/user/container-update.timer"
    if [ -f "$backup_script_location" ]; then
        echo "Notice: $backup_script_location file exists"
        echo "======"
        echo "Because this file exists, assume it should not be modified or"
        echo "changed. This is done to preserve user settings."
        echo "======"
    else
        echo "Create update-backup-main.sh to run backup scripts"
        sudo -u "$user_name" echo "$autoUpdateBackupScript" >> "$backup_script_location"
        sudo chmod +x "$backup_script_location"
        sudo chown $user_name:$user_name $backup_script_location
    fi

    if [ -f "$update_service_location" ]; then
        echo "Notice: $update_service_location file exists"
        echo "======"
        echo "Because this file exists, assume it should not be modified or"
        echo "changed. This is done to preserve user settings."
        echo "======"
    else
        serviceD="[Unit]
Description=Auto backup and update Podman containers
After=network.target

[Service]
WorkingDirectory=/home/$user_name/.server/service/
Type=oneshot
ExecStart=/bin/bash $backup_script_location

[Install]
WantedBy=multi-user.target"
        echo "Create container-update.service for systemD"
        sudo -u "$user_name" echo "$serviceD" >> "$update_service_location"
    fi

    if [ -f "$update_timer_location" ]; then
        echo "Notice: $update_timer_location file exists"
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
        sudo -u "$user_name" echo "$timerD" >> "$update_timer_location"
    fi
    echo -en "${GREEN}Completed step 6\n${ENDCOLOR}"
}

########################################
# FUNCTION
#   step_7()
########################################
step_7_comment="--------------------------------------------
     7: Configure containers configuration
        folder. The containers folder will
        hold all of the makefiles used to
        make podman applications and to hold
        the various commands needed to run
        the containers"
step_7() {
    echo "$step_7_comment"
    echo "--------------------------------------------"
    makefileLocation="/home/$user_name/Makefile"

    echo "Making containers directory at:"
    echo "/home/$user_name/containers"
    sudo -u "$user_name" mkdir -p -- "/home/$user_name/containers"
    if [ -f "$makefileLocation" ]; then
        echo "Notice: $makefileLocation file exists"
        echo "======"
        echo "Because this file exists, assume it should not be modified or"
        echo "changed. This is done to preserve user settings."
        echo "======"
    else
        read -r -p "HINT: you should download this file if you don't have it. Download master Makefile? y/n: " isDownload
        if [[ "$isDownload" =~ ^[Yy]$ ]]; then
            curl -o "$makefileLocation" https://raw.githubusercontent.com/c-4422/app-configs/main/Makefile
        fi
    fi

    echo -en "${GREEN}Completed step 7\n${ENDCOLOR}"
}

########################################
# FUNCTION
#   step_8()
########################################
step_8_comment="--------------------------------------------
[OPTIONAL]
     8: Add lsper alias to .server directory"
step_8() {
    echo "$step_8_comment"
    echo "--------------------------------------------"
    echo "Adding command lsper to server aliases, this is not"
    echo "crucial to system function. lsper stands for"
    echo "list permissions. The idea is that after ls -al"
    echo "you can types lsper which will tell you what the"
    echo "columns mean."
    read -r -p "Install lsper alias? y/n: " is_lsper
    if [[ "$is_lsper" =~ ^[Yy]$ ]]; then
        lsper_location="/home/$user_name/.server/c-4422/permissions.txt"
        sudo -u "$user_name" mkdir -p -- "/home/$user_name/.server/c-4422"
        if [ -f "$lsper_location" ]; then
            sudo -u "$user_name" rm "$lsper_location"
        fi
        sudo -u "$user_name" echo "$lsper_command" >> "$lsper_location"

        for i in "${lrAlias[@]}"
        do
            if ! grep "$i" -q "$alias_location"; then
                echo "$i" >> "$alias_location"
            fi
        done
        echo "Successfully installed lsper alias"
        echo -en "${GREEN}Completed step 8\n${ENDCOLOR}"
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
echo "$step_1_comment"
echo "$step_2_comment"
echo "$step_3_comment"
echo "$step_4_comment"
echo "$step_5_comment"
echo "$step_6_comment"
echo "$step_7_comment"
echo "$step_8_comment"
echo "--------------------------------------------"
read -r -p "Select the step you wish to execute (1-8, Default All=A): " stepSelect

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
read -r -p "Reboot required. Reboot now? y/n: " isReboot
if [[ "$isReboot" =~ ^[Yy]$ ]]; then
    echo "Rebooting"
    sudo reboot
else
    echo "Exiting script, goodbye"
fi

# Reload bashrc to update current environment variables if
# we haven't rebooted
exec bash
