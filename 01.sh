#!/bin/bash

# ─────────────────────────────────────────────────────────────────────────────
# Color variables
# ─────────────────────────────────────────────────────────────────────────────
RESET='\033[0m'
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

# ─────────────────────────────────────────────────────────────────────────────
# Log file variable & log_message function
# ─────────────────────────────────────────────────────────────────────────────
LOG_FILE="/var/log/linsec/hardware.log"

log_message() {
    local message="$1"
    local color="${2:-$GREEN}"  # default color: GREEN
    echo -e "${color}[ $(date '+%Y-%m-%d %H:%M:%S') ] $message${RESET}"
    echo "[ $(date '+%Y-%m-%d %H:%M:%S') ] $message" >> "$LOG_FILE"
}

# ─────────────────────────────────────────────────────────────────────────────
# loading_bar function
# ─────────────────────────────────────────────────────────────────────────────
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

# ─────────────────────────────────────────────────────────────────────────────
# 1) Disable USB storage
# ─────────────────────────────────────────────────────────────────────────────
disable_usb_storage() {
    log_message "Disabling USB storage devices..." "$CYAN"
    
    # Create or overwrite a blacklist file for USB storage
    echo "blacklist usb-storage" > /etc/modprobe.d/usb-storage-blacklist.conf
    
    # Update initramfs so the blacklist takes effect on next reboot
    update-initramfs -u &>/dev/null
    
    log_message "USB storage module is now blacklisted. Reboot is required for changes to fully take effect." "$GREEN"
    loading_bar
}

# ─────────────────────────────────────────────────────────────────────────────
# 2) Restrict serial port access
# ─────────────────────────────────────────────────────────────────────────────
restrict_serial_ports() {
    log_message "Restricting access to serial ports via user/group permissions..." "$CYAN"
    
    # Create a restricted group if it doesn't exist
    if ! getent group restricted_group &>/dev/null; then
        groupadd restricted_group
        log_message "Group 'restricted_group' created." "$GREEN"
    else
        log_message "'restricted_group' already exists." "$YELLOW"
    fi

    # Immediately restrict existing /dev/ttyS* and /dev/ttyUSB* devices
    for tty in /dev/ttyS{0..3} /dev/ttyUSB{0..3}; do
        if [ -e "$tty" ]; then
            chown root:restricted_group "$tty"
            chmod 0660 "$tty"
            log_message "Restricted access to $tty for 'restricted_group' only." "$GREEN"
        fi
    done

    # Create udev rules for future serial devices
    cat <<EOF > /etc/udev/rules.d/70-serial-restrict.rules
KERNEL=="ttyS[0-9]*", GROUP="restricted_group", MODE="0660"
KERNEL=="ttyUSB[0-9]*", GROUP="restricted_group", MODE="0660"
EOF

    # Reload udev rules
    udevadm control --reload-rules && udevadm trigger

    log_message "udev rules created to restrict access to serial ports on each boot." "$GREEN"
    loading_bar
}

# ─────────────────────────────────────────────────────────────────────────────
# 3) Disable FireWire
# ─────────────────────────────────────────────────────────────────────────────
disable_firewire() {
    log_message "Disabling FireWire modules using blacklist..." "$CYAN"
    
    # Create or overwrite a blacklist file for FireWire
    cat <<EOF > /etc/modprobe.d/firewire-blacklist.conf
blacklist firewire-core
blacklist firewire-ohci
blacklist ieee1394
EOF
    
    # Update initramfs
    update-initramfs -u &>/dev/null

    log_message "FireWire modules have been blacklisted. Reboot required for changes to fully take effect." "$GREEN"
    loading_bar
}

# ─────────────────────────────────────────────────────────────────────────────
# 4) Set GRUB password
# ─────────────────────────────────────────────────────────────────────────────
set_grub_password() {
    log_message "Setting up a custom GRUB password..." "$CYAN"

    # Prompt user for a password (twice for confirmation)
    read -s -p "Enter new GRUB password: " grub_password
    echo
    read -s -p "Confirm new GRUB password: " grub_password2
    echo

    # Check if passwords match
    if [ "$grub_password" != "$grub_password2" ]; then
        log_message "Error: Passwords do not match." "$RED"
        return 1
    fi

    # Generate a PBKDF2 hash from the user's password
    # We'll parse the output of grub-mkpasswd-pbkdf2 to capture the full hash.
    grub_hash=$(echo -e "$grub_password\n$grub_password" | grub-mkpasswd-pbkdf2 2>/dev/null | \
        sed -n 's/^PBKDF2 hash of your password is //p')

    if [ -z "$grub_hash" ]; then
        log_message "Failed to generate a PBKDF2 hash. Is grub-mkpasswd-pbkdf2 installed?" "$RED"
        return 1
    fi

    # If /etc/grub.d/40_custom doesn't already have a 'password_pbkdf2 root' line, add it
    if ! grep -q "password_pbkdf2 root" /etc/grub.d/40_custom 2>/dev/null; then
        echo "set superusers=\"root\"" >> /etc/grub.d/40_custom
        echo "password_pbkdf2 root $grub_hash" >> /etc/grub.d/40_custom
        
        # Update GRUB configuration
        update-grub &>/dev/null
        log_message "Custom GRUB password has been set successfully." "$GREEN"
    else
        log_message "GRUB password is already set in /etc/grub.d/40_custom." "$YELLOW"
    fi

    loading_bar
}

# ─────────────────────────────────────────────────────────────────────────────
# 5) Disable boot from external devices — BIOS/UEFI only
# ─────────────────────────────────────────────────────────────────────────────
disable_boot_external_devices() {
    log_message "Disabling boot from external devices..." "$CYAN"
    log_message "Please disable boot from external devices in your BIOS settings." "$RED"
    log_message "Boot from external devices can only be disabled manually in BIOS." "$YELLOW"
    loading_bar
}

# ─────────────────────────────────────────────────────────────────────────────
# 6) Disable Legacy Boot Mode — BIOS/UEFI only
# ─────────────────────────────────────────────────────────────────────────────
disable_legacy_boot() {
    log_message "Disabling Legacy Boot Mode..." "$CYAN"
    log_message "Please disable Legacy Boot Mode in your BIOS settings." "$RED"
    log_message "Legacy Boot Mode can only be disabled manually in BIOS." "$YELLOW"
    loading_bar
}

# ─────────────────────────────────────────────────────────────────────────────
# 7) Enable TPM — BIOS/UEFI only
# ─────────────────────────────────────────────────────────────────────────────
enable_tpm() {
    log_message "Enabling TPM (if supported)..." "$CYAN"
    log_message "Please enable TPM in your BIOS/UEFI settings." "$RED"
    loading_bar
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
clear
log_message "LINSEC - Linux Hardening Script" "$MAGENTA"

disable_usb_storage
restrict_serial_ports
disable_firewire
set_grub_password
disable_boot_external_devices
disable_legacy_boot
enable_tpm

log_message "Hardening completed successfully!" "$GREEN"
