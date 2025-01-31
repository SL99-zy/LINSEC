#!/bin/bash


RESET='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
LOG_FILE="/var/log/linsec/file_protection.log"

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

restrict_sensitive_files() {
    log_message "Restricting /etc/shadow and /etc/gshadow..."
    chmod 640 /etc/shadow /etc/gshadow 2>>"$LOG_FILE"
    chown root:root /etc/shadow /etc/gshadow 2>>"$LOG_FILE"
    loading_bar
}

avoid_setuid_setgid() {
    log_message "Listing setuid/setgid binaries..."
    find / -type f -perm /6000 -ls 2>>"$LOG_FILE" | tee -a "$LOG_FILE"
    loading_bar
}

check_orphaned_files_and_directories() {
    log_message "Checking for files with no valid user/group..."
    find / -type f \( -nouser -o -nogroup \) -ls 2>>"$LOG_FILE" | tee -a "$LOG_FILE"
    loading_bar
}

harden_tmp_directories() {
    log_message "Adding sticky bit to world-writable directories..."
    find / -type d \( -perm -0002 -a \! -perm -1000 \) -exec chmod +t {} \; 2>>"$LOG_FILE"
    find / -type d -perm -0002 -a \! -uid 0 -exec chown root {} \; 2>>"$LOG_FILE"
    loading_bar
}

configure_auditd() {
    log_message "Configuring auditd..."
    if ! command -v auditd &>/dev/null; then
        apt-get update && apt-get install -y auditd
    fi
    if [ ! -f /etc/audit/rules.d/audit.rules ]; then
        touch /etc/audit/rules.d/audit.rules
        chmod 640 /etc/audit/rules.d/audit.rules
    fi
    if ! grep -q "execve,execveat" /etc/audit/rules.d/audit.rules; then
        echo "-a exit,always -F arch=b64 -S execve,execveat" >> /etc/audit/rules.d/audit.rules
        echo "-a exit,always -F arch=b32 -S execve,execveat" >> /etc/audit/rules.d/audit.rules
    fi
    systemctl enable auditd
    systemctl restart auditd
    loading_bar
}

##############
#  AppArmor  # 
##############

setup_apparmor() {
    log_message "Setting up AppArmor..."
    apt-get update && apt-get install -y apparmor apparmor-utils
    systemctl enable apparmor
    systemctl start apparmor

    # Possibly enforce all profiles
    if [ -d /etc/apparmor.d ]; then
        for profile in /etc/apparmor.d/*; do
            if [[ -f "$profile" ]]; then
                aa-enforce "$profile" 2>>"$LOG_FILE"
            fi
        done
    fi
    loading_bar
}

###############################################################################
				# MAIN
###############################################################################
main() {
    echo -e "${GREEN}===== Protection des fichiers =====${RESET}"
    log_message "Starting file protection tasks..."

    restrict_sensitive_files
    avoid_setuid_setgid
    check_orphaned_files_and_directories
    harden_tmp_directories
    configure_auditd

    setup_apparmor

    log_message "File protection tasks completed."
}

main "$@"
