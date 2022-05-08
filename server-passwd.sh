###################################################################
# SERVER PASSWORD MANAGER
#
# by C-4422
# 9b6b87bf3d3f44de936e7283ce4e555402feb741a005dfdc70cbbe2f08581911
# 353b5bd8ab63aa7d4f15f462ef001d7b12f1abd6d32b9f9751ef7d9df9b3462a
#
# FUNCTION:
#   cpass
#
# ARGS:
#   $1 - "set" "get" "v" "version"
#   $2 - name of password string
#
# Description:
#   Adapter alias function for managing passwords either through 
#   pass or writing to the secrets file. This function is REQUIRED
#   for C-4422 style podman configuration makefiles.
#
###################################################################
#!/bin/bash

cpass () {
    version="1.0.0"
    secrets_location="$CONFIGURATION_LOCATION/containers/secrets"
    action="$1"
    password_name="$2"

    if [[ "$action" == "v" || "$action" == "version" ]]; then
        # Get version number
        echo $version
    elif [[ "$action" == "get" ]]; then
        # Get password
        if ! [ -x "$(command -v pass)" ]; then
            password_file_name="passwd_$password_name"
            cat "$secrets_location/$password_file_name"
        else
            pass "$password_name"
        fi
    elif [[ "$action" == "set" ]]; then
        # Set password
        if ! [ -x "$(command -v pass)" ]; then
            is_new_password="y"
            password_file_name="passwd_$password_name"

            mkdir -p -- "$secrets_location"
            if [ -f "$secrets_location/$password_file_name" ]; then
                current_password=$(cat "$secrets_location/$password_file_name")
                echo "Password: $password_name currently set to: $current_password"
                is_new_password="n"
                read -r -p "Set new password for $password_name? y/N: " is_new_password
            fi
            while [[ "$is_new_password" =~ ^[Yy]$ ]]; do
                read -r -p "Type password: " new_password
                read -r -p "Retype Password: " confirm_new_password
                if [[ "$new_password" == "$confirm_new_password" ]]; then
                    is_new_password="n"
                    echo "$new_password" > "$secrets_location/$password_file_name"
                else
                    echo "Input does not match retry"
                fi
            done
        else
            pass insert "$password_name"
        fi
    fi
}

export -f cpass