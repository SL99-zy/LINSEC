#!/bin/bash





RESET='\033[0m'

GREEN='\033[0;32m'

YELLOW='\033[0;33m'

CYAN='\033[0;36m'

LOG_FILE="/var/log/linsec/network.log"



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



configure_sshd() {

    log_message "Hardening SSH..."

    if ! command -v sshd &>/dev/null; then

        apt-get update && apt-get install -y openssh-server

    fi

    local ssh_config="/etc/ssh/sshd_config"

    if [ -f "$ssh_config" ]; then

        cp "$ssh_config" "${ssh_config}.bak_$(date +%F_%T)"

        sed -i 's/^#\?PermitRootLogin\s.*/PermitRootLogin no/' "$ssh_config"

        sed -i 's/^#\?Protocol\s.*/Protocol 2/' "$ssh_config"

        # sed -i 's/^#\?Port\s.*/Port 2222/' "$ssh_config"

        systemctl restart ssh

    else

        log_message "SSHD config not found." "$YELLOW"

    fi

    loading_bar

}



configure_firewall_ufw() {

    log_message "Configuring UFW firewall..."

    if ! command -v ufw &>/dev/null; then

        apt-get update && apt-get install -y ufw

    fi

    ufw default deny incoming

    ufw default allow outgoing

    ufw allow 22/tcp

    ufw --force enable

    loading_bar

}



restrict_sockets_and_pipes() {

    log_message "Restricting access to sockets/pipes..."

    if command -v sockstat &>/dev/null; then

        log_message "sockstat output:" "$YELLOW"

        sockstat 2>>"$LOG_FILE" | tee -a "$LOG_FILE"

    fi

    if command -v ss &>/dev/null; then

        log_message "ss -xp output:" "$YELLOW"

        ss -xp 2>>"$LOG_FILE" | tee -a "$LOG_FILE"

    fi

    loading_bar

}



#-----------------------------------------------------------------------------

# NEW: Advanced Firewall Rules (iptables)

#-----------------------------------------------------------------------------

configure_firewall_iptables() {

    log_message "Setting up advanced iptables firewall rules..."

    # 1) Flush existing rules

    iptables -F

    iptables -X

    iptables -Z



    # 2) Default policies

    iptables -P INPUT DROP

    iptables -P FORWARD DROP

    iptables -P OUTPUT ACCEPT



    # 3) Allow loopback

    iptables -A INPUT -i lo -j ACCEPT



    # 4) Allow established/related

    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT



    # 5) Allow SSH (port 22)

    iptables -A INPUT -p tcp --dport 22 -j ACCEPT



    # 6) Example: Allow HTTP/HTTPS

    # iptables -A INPUT -p tcp --dport 80 -j ACCEPT

    # iptables -A INPUT -p tcp --dport 443 -j ACCEPT



    # 7) Log dropped packets (optional)

    iptables -A INPUT -j LOG --log-prefix "IPTables-Dropped: " --log-level 4



    # Save iptables

    if command -v netfilter-persistent &>/dev/null; then

        netfilter-persistent save

    else

        apt-get install -y iptables-persistent

        netfilter-persistent save

    fi

    loading_bar

}



main() {

    echo -e "${GREEN}===== Network =====${RESET}"

    log_message "Starting network tasks..."



    configure_sshd

    configure_firewall_ufw

    restrict_sockets_and_pipes



    # Advanced iptables

    configure_firewall_iptables



    log_message "Network tasks completed."

}



main "$@"

