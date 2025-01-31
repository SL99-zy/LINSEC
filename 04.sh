#!/bin/bash



RESET='\033[0m'

GREEN='\033[0;32m'

YELLOW='\033[0;33m'

CYAN='\033[0;36m'

LOG_FILE="/var/log/linsec/auth_identification.log"



log_message() {

    local message="$1"

    local color="${2:-$GREEN}"

    echo -e "${color}[ $(date '+%Y-%m-%d %H:%M:%S') ] $message${RESET}"

    echo "[ $(date '+%Y-%m-%d %H:%M:%S') ] $message" >> "$LOG_FILE"

}



loading_bar() {

    local progress=0

    local total=50

    echo -n -e "${CYAN}["

    while [ $progress -le $total ]; do

        printf "#"

        progress=$((progress + 1))

        sleep 0.01

    done

    echo -e "]${RESET}"

}



disable_unused_accounts() {

    # Number of days of inactivity after which an account is considered unused

    local DAYS_INACTIVE=90



    log_message "Checking for user accounts (UID >= 1000) inactive for $DAYS_INACTIVE+ days..."



    # 'lastlog -b DAYS_INACTIVE' lists users who haven't logged in for at least DAYS_INACTIVE days.

    # Skip the header line with 'tail -n +2'

    local inactive_users

    inactive_users=$(lastlog -b "$DAYS_INACTIVE" 2>/dev/null | tail -n +2 | awk '{print $1}')



    # Loop over those inactive users

    for user in $inactive_users; do

        # Check if the user actually exists on the system

        # (sometimes 'lastlog' can display system accounts or old entries)

        if id "$user" &>/dev/null; then

            # Retrieve UID

            local user_uid

            user_uid=$(id -u "$user")



            # We only want to act on accounts with UID >= 1000, excluding root

            if [[ "$user_uid" -ge 1000 && "$user" != "root" ]]; then

                # Prompt the admin for confirmation

                read -r -p "User '$user' has been inactive for $DAYS_INACTIVE+ days. Delete this user? [y/N] " answer



                # Convert answer to lowercase for easy comparison

                answer="${answer,,}"



                if [[ "$answer" == "y" || "$answer" == "yes" ]]; then

                    log_message "Deleting user '$user' - Inactive for $DAYS_INACTIVE+ days." "$YELLOW"

                    if ! userdel -r "$user" 2>>"$LOG_FILE"; then

                        log_message "Failed to delete user '$user'. Check logs." "$RED"

                    fi

                else

                    log_message "Skipping deletion for user '$user'." "$CYAN"

                fi

            fi

        fi

    done



    loading_bar

}







enforce_password_policies() {

    log_message "Enforcing password policies (ANSSI-based)..."

    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs

    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 7/' /etc/login.defs

    sed -i 's/^PASS_MIN_LEN.*/PASS_MIN_LEN 12/' /etc/login.defs

    sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs

    loading_bar

}



expire_local_sessions() {

    log_message "Configuring session inactivity timeout (900s)..."

    if ! grep -q "TMOUT" /etc/profile; then

        echo "TMOUT=900" >> /etc/profile

        echo "export TMOUT" >> /etc/profile

    else

        sed -i 's/^TMOUT=.*/TMOUT=900/' /etc/profile

    fi

    loading_bar

}



disable_root_login() {

    log_message "Disabling direct root login..."

    usermod -s /usr/sbin/nologin root 2>>"$LOG_FILE"

    if [ -f /etc/securetty ]; then

        sed -i 's/^tty[0-9]\+/#&/' /etc/securetty

    fi

    loading_bar

}



restrict_su_command() {

    log_message "Restricting 'su' command to sudo group..."

    if ! grep -q "pam_wheel.so" /etc/pam.d/su; then

        echo "auth required pam_wheel.so use_uid group=sudo" >> /etc/pam.d/su

    fi

    chown root:sudo /bin/su

    chmod 4750 /bin/su

    loading_bar

}



configure_admin_accounts() {

    log_message "Ensuring sudo group exists and adding current user..."

    if ! grep -q '^sudo:' /etc/group; then

        groupadd sudo 2>>"$LOG_FILE"

    fi

    local current_user

    current_user=$(whoami)

    usermod -aG sudo "$current_user" 2>>"$LOG_FILE"

    loading_bar

}



configure_login_banner() {

    log_message "Configuring login banner..."

    local banner_text="\

********************************************************

*  WARNING: Unauthorized access to this system is       *

*  prohibited. All activities may be monitored.         *

********************************************************"

    echo -e "$banner_text" > /etc/issue

    echo -e "$banner_text" > /etc/issue.net

    if ! grep -q '^Banner /etc/issue.net' /etc/ssh/sshd_config; then

        echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config

    fi

    systemctl restart ssh

    loading_bar

}



#-----------------------------------------------------------------------------

# NEW: PAM Configuration Hardening (ANSSI)

#-----------------------------------------------------------------------------

pam_configuration_hardening() {

    log_message "Applying PAM configuration hardening (ANSSI guidelines)..."



    # Example: /etc/pam.d/common-password (Debian/Ubuntu-like) 

    # requiring 'pam_pwquality.so' with complexity rules

    if [ -f /etc/pam.d/common-password ]; then

        if ! grep -q 'pam_pwquality.so' /etc/pam.d/common-password; then

            sed -i '/pam_unix.so/ s/$/ remember=5 use_authtok/' /etc/pam.d/common-password

            echo "password    requisite     pam_pwquality.so retry=3 minlen=12 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1 enforce_for_root" \

                 >> /etc/pam.d/common-password

        fi

    fi



    # Example: Lockout after 5 failed attempts using pam_tally2 or faillock

    # Many distributions now use 'faillock':

    if [ -f /etc/pam.d/common-auth ]; then

        if ! grep -q 'faillock' /etc/pam.d/common-auth; then

            echo "auth required pam_faillock.so preauth silent deny=5 unlock_time=900" >> /etc/pam.d/common-auth

            echo "auth [success=1 default=bad] pam_faillock.so authfail deny=5 unlock_time=900" >> /etc/pam.d/common-auth

            echo "auth sufficient pam_faillock.so authsucc deny=5 unlock_time=900" >> /etc/pam.d/common-auth

        fi

    fi



    loading_bar

}





#-----------------------------------------------------------------------------

# NEW: fail2ban (or sshguard)

#-----------------------------------------------------------------------------

install_fail2ban() {

    log_message "Installing and configuring fail2ban..."

    if ! command -v fail2ban-client &>/dev/null; then

        apt-get update && apt-get install -y fail2ban

    fi



    # Basic SSH jail config

    if [ ! -f /etc/fail2ban/jail.local ]; then

        cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

    fi

    # You can configure [sshd] section here or add custom rules

    systemctl enable fail2ban

    systemctl start fail2ban

    loading_bar

}



# Main

main() {

    echo -e "${GREEN}===== Authentification / Identification =====${RESET}"

    log_message "Starting auth/identification tasks..."



    disable_unused_accounts

    enforce_password_policies

    expire_local_sessions

    disable_root_login

    configure_admin_accounts

    configure_login_banner



    # PAM Hardening

    pam_configuration_hardening



   



    # fail2ban

    install_fail2ban



    log_message "Auth/Identification tasks completed."

}



main "$@"

