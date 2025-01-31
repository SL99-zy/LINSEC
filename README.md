# Linux Hardening Automation Tool (LinSec)

This project provides a collection of Bash scripts designed to automate the hardening of Linux systems based on **ANSSI (Agence Nationale de la Sécurité des Systèmes d'Information)** guidelines. The scripts cover various aspects of system security, including hardware, kernel, disk partitioning, authentication, file protection, and network security.

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Scripts Overview](#scripts-overview)
- [Installation](#installation)
- [Acknowledgments](#acknowledgments)
---

## Introduction

The **Linux Hardening Automation Tool (LinSec)** is a set of Bash scripts that automate the process of securing Linux systems. These scripts are designed to follow the best practices and guidelines provided by ANSSI, ensuring that your system is hardened against common security threats.

The tool is modular, allowing you to run specific scripts depending on your needs. It also includes a **main menu** for easy navigation and execution of the scripts.

---

## Features

- **Hardware Hardening**: Disables unnecessary hardware interfaces (e.g., USB, FireWire) and restricts access to sensitive ports.
- **Kernel Hardening**: Applies secure kernel configurations and disables unnecessary kernel modules.
- **Disk Partitioning**: Creates secure partitions and applies mount options to protect sensitive directories.
- **Authentication and Identification**: Enforces strong password policies, disables unused accounts, and restricts root access.
- **File Protection**: Restricts access to sensitive files, configures AppArmor, and sets up auditing with `auditd`.
- **Network Hardening**: Hardens SSH configurations, sets up firewalls (UFW and iptables), and restricts access to network sockets and pipes.

---

## Scripts Overview

### 1. **Hardware Hardening (`01.sh`)**
- Disables USB storage.
- Restricts access to serial ports.
- Disables FireWire.
- Sets a GRUB password.
- Disables boot from external devices (requires BIOS/UEFI changes).
- Disables Legacy Boot Mode (requires BIOS/UEFI changes).
- Enables TPM (Trusted Platform Module) (requires BIOS/UEFI changes).

### 2. **Kernel Hardening (`02.sh`)**
- Applies secure sysctl configurations.
- Configures the bootloader with IOMMU activation.
- Enables the Yama Linux Security Module (LSM).
- Disables unnecessary kernel modules.
- Verifies applied configurations.

### 3. **Disk Partitioning (`03.sh`)**
- Creates a dedicated `/tmp` partition.
- Secures `/tmp` with `noexec`, `nodev`, and `nosuid` options.
- Creates separate partitions for `/var`, `/home`, etc.
- Disables unnecessary filesystem modules.
- Restricts access to the `/boot` directory.
- Enables filesystem checks (`fsck`) on all partitions.

### 4. **Authentication and Identification (`04.sh`)**
- Disables unused accounts.
- Enforces password policies (ANSSI-based).
- Configures session inactivity timeout.
- Disables direct root login.
- Restricts the `su` command to the `sudo` group.
- Configures admin accounts and login banners.
- Hardens PAM configurations.
- Installs and configures `fail2ban`.

### 5. **File Protection (`05.sh`)**
- Restricts access to `/etc/shadow` and `/etc/gshadow`.
- Lists and avoids setuid/setgid binaries.
- Checks for orphaned files and directories.
- Hardens world-writable directories.
- Configures `auditd` for system auditing.
- Sets up AppArmor for mandatory access control.

### 6. **Network Hardening (`06.sh`)**
- Hardens SSH configurations (disables root login, restricts protocols, etc.).
- Configures UFW (Uncomplicated Firewall) to block unwanted traffic.
- Restricts access to network sockets and pipes.
- Sets up advanced `iptables` firewall rules.
- Logs dropped packets for monitoring.

### 7. **Main Menu (`linsec.sh`)**
- Provides an interactive menu to execute the scripts.
- Displays an ASCII art banner and animations.
- Allows users to select and run specific hardening scripts.
- Includes an introduction and goodbye banner.

---

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/SL99-zy/LINSEC.git
   cd LINSEC
2. Before running the scripts, you need to make them executable. Run the following command:
  ```bash
    chmod +x linsec.sh
  ```
3. run the script with high privileges
   ```
   sudo ./linsec.sh
---
## Acknowledgments

- **ANSSI**: For providing the guidelines and best practices for Linux hardening.
- **Open Source Community**: For the tools and libraries used in this project.

