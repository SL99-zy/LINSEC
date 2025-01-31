#!/bin/bash


RESET='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
LOG_FILE="/var/log/linsec/partitionnement.log"

log_message() {
    local message="$1"
    local color="${2:-$GREEN}"
    printf "${color}[ $(date '+%Y-%m-%d %H:%M:%S') ] %s${RESET}\n" "$message"
    printf "[ $(date '+%Y-%m-%d %H:%M:%S') ] %s\n" "$message" >> "$LOG_FILE"
}

loading_bar() {
    local progress=0
    local total=50
    printf "${CYAN}["
    while [ $progress -le $total ]; do
        printf "#"
        progress=$((progress + 1))
        sleep 0.01
    done
    printf "]${RESET}\n"
}

create_tmp_partition() {
    log_message "Creating a dedicated /tmp partition..."
    if ! mountpoint -q /tmp; then
        log_message "No separate partition for /tmp found. Creating..." "$YELLOW"
        parted /dev/sda mkpart primary ext4 2GB 4GB || {
            log_message "Failed to create /tmp partition with parted." "$YELLOW"
            return 1
        }
        mkfs.ext4 /dev/sdaX || {
            log_message "Failed to format the /tmp partition." "$YELLOW"
            return 1
        }
        echo "/dev/sdaX /tmp ext4 defaults 0 2" >> /etc/fstab
        mount -a || {
            log_message "Failed to mount /tmp partition." "$YELLOW"
            return 1
        }
    else
        log_message "/tmp is already a separate partition."
    fi
    loading_bar
}

secure_tmp_mount() {
    log_message "Securing /tmp with noexec,nodev,nosuid..."
    if grep -q '/tmp' /etc/fstab; then
        sed -i 's|\(.* /tmp .*defaults\)|\1,noexec,nodev,nosuid|' /etc/fstab
        mount -o remount /tmp 2>>"$LOG_FILE" || {
            log_message "Failed to remount /tmp with new options." "$YELLOW"
            return 1
        }
    else
        log_message "/tmp not found in /etc/fstab." "$YELLOW"
    fi
    loading_bar
}

create_separate_partitions() {
    log_message "Creating separate partitions for /var, /home, etc. (stub)..."
    loading_bar
}

disable_unnecessary_mounts() {
    log_message "Disabling unnecessary filesystem modules..."
    local modules=(cramfs freevxfs jffs2 hfs hfsplus udf)
    for mod in "${modules[@]}"; do
        if ! grep -q "install $mod /bin/true" /etc/modprobe.d/blacklist.conf 2>/dev/null; then
            echo "install $mod /bin/true" >> /etc/modprobe.d/blacklist.conf
            log_message "Blacklisted: $mod"
        fi
    done
    if ! update-initramfs -u; then
        log_message "Failed to update initramfs after module blacklist." "$YELLOW"
        return 1
    fi
    loading_bar
}

restrict_boot_access() {
    log_message "Restricting /boot access..."
    if ! chmod 700 /boot 2>>"$LOG_FILE"; then
        log_message "Failed to set permissions on /boot." "$YELLOW"
        return 1
    fi
    local BOOT_UUID
    BOOT_UUID=$(blkid -o value -s UUID /dev/sda1 2>>"$LOG_FILE" || true)
    if [ -n "$BOOT_UUID" ] && ! grep -q "$BOOT_UUID" /etc/fstab; then
        echo "UUID=${BOOT_UUID} /boot ext4 defaults,noauto 0 2" >> /etc/fstab
    fi
    loading_bar
}

enable_fsck_on_partitions() {
    log_message "Enabling fsck checks for all partitions in /etc/fstab..."

    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

        local fs_spec fs_file fs_vfstype fs_mntops fs_freq fs_passno
        fs_spec=$(echo "$line" | awk '{print $1}')
        fs_file=$(echo "$line" | awk '{print $2}')
        fs_vfstype=$(echo "$line" | awk '{print $3}')
        fs_mntops=$(echo "$line" | awk '{print $4}')
        fs_freq=$(echo "$line" | awk '{print $5}')
        fs_passno=$(echo "$line" | awk '{print $6}')

        if [[ "$fs_vfstype" =~ ^(nfs|cifs|iso9660|squashfs|proc|sysfs|devpts|tmpfs)$ ]]; then
            log_message "Skipping fsck check for $fs_file (type: $fs_vfstype)." "$YELLOW"
            continue
        fi

        if [[ "$fs_file" == "/" ]]; then
            fs_passno=1
        else
            fs_passno=2
        fi

        local new_entry="${fs_spec} ${fs_file} ${fs_vfstype} ${fs_mntops} ${fs_freq:-1} ${fs_passno}"
        if ! grep -q "^$fs_spec[[:space:]]$fs_file" /etc/fstab; then
            log_message "Partition $fs_file not found in /etc/fstab, skipping..." "$YELLOW"
            continue
        fi
        sed -i "\|^${fs_spec}[[:space:]]${fs_file}[[:space:]]|s|.*|${new_entry}|" /etc/fstab
        log_message "Updated fsck settings for $fs_file: $new_entry"
    done < /etc/fstab

    log_message "File system integrity checks (fsck) have been configured."
    loading_bar
}

main() {
    printf "${GREEN}===== Partitionnement des disques (avec LUKS) =====${RESET}\n"
    log_message "Starting partitionnement tasks..."

    create_tmp_partition || {
        log_message "Error during /tmp partition creation. Exiting..." "$YELLOW"
        return 1
    }

    secure_tmp_mount || {
        log_message "Error during /tmp partition securing. Exiting..." "$YELLOW"
        return 1
    }

    create_separate_partitions || {
        log_message "Error during separate partition creation. Exiting..." "$YELLOW"
        return 1
    }

    disable_unnecessary_mounts || {
        log_message "Error disabling unnecessary mounts. Exiting..." "$YELLOW"
        return 1
    }

    restrict_boot_access || {
        log_message "Error restricting /boot access. Exiting..." "$YELLOW"
        return 1
    }

    enable_fsck_on_partitions || {
        log_message "Error enabling fsck checks. Exiting..." "$YELLOW"
        return 1
    }

    log_message "Partitionnement tasks completed successfully."
}

main "$@"
