#!/bin/bash

# Define colors for styling
RESET='\033[0m'
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'

LOG_FILE="/var/log/linsec/kernel_hardening.log"

# Initialize log file
init_log() {
    echo "Kernel Hardening Log - $(date)" > "$LOG_FILE"
    echo "===================================" >> "$LOG_FILE"
}

# Function for a loading bar
loading_bar() {
    local progress=0
    local total=50
    echo -n -e "${CYAN}["
    while [ $progress -le $total ]; do
        printf "#"
        progress=$((progress + 1))
        sleep 0.04
    done
    echo -e "]${RESET}"
}

# Function to log messages with colors and save to file
log_message() {
    local message="$1"
    local color="${2:-$GREEN}" # Default color is green
    echo -e "${color}[ $(date '+%Y-%m-%d %H:%M:%S') ] ${message}${RESET}"
    echo "[ $(date '+%Y-%m-%d %H:%M:%S') ] $message" >> "$LOG_FILE"
}

# Apply sysctl hardening configurations
apply_sysctl_hardening() {
    log_message "Applying sysctl hardening configurations..." "$CYAN"
    local sysctl_file="/etc/sysctl.d/99-kernel-hardening.conf"

    cat > "$sysctl_file" <<EOF
# Memory Protection
vm.mmap_min_addr = 65536
kernel.randomize_va_space = 2

# Kernel Protection
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.perf_event_paranoid = 2
kernel.sysrq = 0
kernel.unprivileged_bpf_disabled = 1
kernel.modules_disabled = 1
kernel.panic_on_oops = 1
kernel.pid_max = 65536
kernel.yama.ptrace_scope = 1

# Filesystem Protection
fs.suid_dumpable = 0
fs.protected_fifos = 2
fs.protected_regular = 2
fs.protected_symlinks = 1
fs.protected_hardlinks = 1

# Network Configuration
net.ipv4.ip_forward = 0
net.ipv4.ip_local_port_range = 32768 65535
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_local = 0
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.all.disable_ipv6 = 1
EOF

    sysctl --system >> "$LOG_FILE" 2>&1
    log_message "Sysctl configurations applied successfully." "$GREEN"
    loading_bar
}

# Configure bootloader with IOMMU activation
configure_bootloader_with_iommu() {
    log_message "Configuring bootloader with IOMMU activation..." "$CYAN"
    local grub_file="/etc/default/grub"

    # Backup existing GRUB configuration
    cp "$grub_file" "$grub_file.bak"
    echo "Backup of GRUB configuration created at $grub_file.bak" >> "$LOG_FILE"

    # Add IOMMU and other kernel parameters
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 intel_iommu=on security=yama ipv6.disable=1"/' "$grub_file"

    # Update GRUB configuration
    update-grub >> "$LOG_FILE" 2>&1
    log_message "Bootloader updated successfully." "$GREEN"
    loading_bar
}

# Enable LSM Yama
enable_lsm_yama() {
    log_message "Enabling LSM Yama security module..." "$CYAN"
    if ! grep -q "security=yama" /proc/cmdline; then
        configure_bootloader_with_iommu
    fi
    log_message "LSM Yama enabled and configured successfully." "$GREEN"
    loading_bar
}

# Disable unnecessary kernel modules
disable_kernel_modules() {
    log_message "Disabling unnecessary kernel modules..." "$CYAN"

    # 1) Blacklist certain modules so they cannot be loaded
    cat <<EOF > /etc/modprobe.d/blacklist.conf
install cramfs /bin/true
install freevxfs /bin/true
install jffs2 /bin/true
install hfs /bin/true
install hfsplus /bin/true
install usb-storage /bin/true
EOF
    chmod 0600 /etc/modprobe.d/blacklist.conf
    echo "Kernel module blacklist configuration saved at /etc/modprobe.d/blacklist.conf" >> "$LOG_FILE"

    # 2) Permanently disable kernel module loading
   
    echo "kernel.modules_disabled=1" >> /etc/sysctl.conf
    sysctl -p

    log_message "Unnecessary kernel modules disabled, and runtime module loading is now blocked." "$GREEN"
    loading_bar
}

# Verify applied configurations
verify_hardening() {
    log_message "Verifying applied kernel hardening configurations..." "$CYAN"
    echo -e "${YELLOW}Checking sysctl parameters:${RESET}"
    sysctl -a | grep -E "kernel\.|fs\.|net\." | grep -i "disable\|restrict\|protect" >> "$LOG_FILE" 2>&1
    echo -e "${YELLOW}Checking GRUB parameters:${RESET}"
    cat /proc/cmdline >> "$LOG_FILE"
    log_message "Verification completed." "$GREEN"
    loading_bar
}

# Ensure a required command is installed
ensure_command() {
    local cmd="$1"
    local package="$2"
    if ! command -v "$cmd" &>/dev/null; then
        log_message "Command $cmd not found. Installing package: $package..." "$YELLOW"
        if apt-get install -y "$package" >> "$LOG_FILE" 2>&1; then
            log_message "$package installed successfully." "$GREEN"
        else
            log_message "Failed to install $package. Exiting." "$RED"
            exit 1
        fi
    fi
}

# Main execution function
main() {
    clear
    echo -e "${BOLD}${MAGENTA}======================================${RESET}"
    echo -e "${BOLD}${MAGENTA}   LINSEC - Kernel Hardening Script${RESET}"
    echo -e "${BOLD}${MAGENTA}======================================${RESET}\n"

    init_log
    log_message "Starting kernel hardening process with IOMMU activation..." "$CYAN"
    ensure_command "update-grub" "grub-common"
    ensure_command "sysctl" "procps"
    apply_sysctl_hardening
    configure_bootloader_with_iommu
    enable_lsm_yama
    disable_kernel_modules
    verify_hardening
    log_message "Kernel hardening process completed successfully." "$GREEN"
    log_message "For detailed logs, see $LOG_FILE" "$YELLOW"
}

# Run main function
main "$@"
