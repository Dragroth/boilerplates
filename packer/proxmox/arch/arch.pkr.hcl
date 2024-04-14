# Arch Linux
# ---
# Packer Template to create Arch Linux on Proxmox

packer {
    required_plugins {
        name = {
            version = "~> 1"
            source  = "github.com/hashicorp/proxmox"
        }
    }
}

# Variable Definitions

# PVE connection
variable "proxmox_api_url" {
    type = string
}

variable "proxmox_api_token_id" {
    type = string
}

variable "proxmox_api_token_secret" {
    type = string
    sensitive = true
}

# ISO variables
variable "iso_file" {
    type = string
    default = "local:iso/archlinux-x86_64.iso"
}
 
variable "iso_url" {
    type = string
    default = "https://mirror2.evolution-host.com/archlinux/iso/2024.03.01/archlinux-x86_64.iso"
}

variable "iso_checksum" {
    type = string
    default = "0062e39e57d492672712467fdb14371fca4e3a5c57fed06791be95da8d4a60e3"
}

# VM variables
variable "cloudinit_storage_pool" {
    type = string
    default = "local-lvm"
}

variable "proxmox_node" {
    type = string
    default = "pve"
}

variable "storage_pool" {
    type = string
    default = "local-lvm"
}

variable "cpu_type" {
    type = string
    default = "host"
}

variable "vm_id" {
    type = string
    default = "9999"
}

variable "bridge_name" {
    type = string
    default = "vmbr0"
}

variable "cores" {
    type = string
    default = "1"
}

variable "memory" {
    type = string
    default = "1024"
}

variable "disk_size" {
    type = string
    default = "30G"
}

variable "swap_size" {
    type = string
    default = "4G"
}

variable "optional_packages" {
    type = string
    default = "vim"
}

variable "language" {
    type = string
    default = "en_US.UTF-8"
}

variable "country" {
    type = string
    default = "country=US"
}

variable "timezone" {
    type = string
    default = "America/Los_Angeles"
}

source "proxmox-iso" "arch" {

    # Proxmox Connection Settings
    proxmox_url = var.proxmox_api_url
    username = var.proxmox_api_token_id
    token = var.proxmox_api_token_secret
    insecure_skip_tls_verify  = false

    # VM General Settings
    node = var.proxmox_node
    vm_id = var.vm_id
    vm_name = "arch"
    template_description = "Built from ${basename(var.iso_file)} on ${formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())}"
    cores = var.cores
    memory = var.memory
    cpu_type = var.cpu_type
    qemu_agent = true
    bios = "ovmf"
    machine = "q35"
    
    efi_config {
        efi_storage_pool = var.storage_pool
    }

    # ISO file
    iso_file = var.iso_file
    iso_checksum = var.iso_checksum
    iso_storage_pool = "local"
    unmount_iso = true

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-single"
    disks {
        disk_size = var.disk_size
        storage_pool = var.storage_pool
        type = "scsi"
    }

    # VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = var.bridge_name
        firewall = "false"
    }
    
    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = var.cloudinit_storage_pool

    # PACKER Boot Commands
    boot_command = [
        "<enter><wait40s>",
        "curl -sSl http://{{ .HTTPIP }}:{{ .HTTPPort }}/install.sh | bash -s -- 'packer' '${var.swap_size}' '${var.country}' '${var.timezone}' '${var.language}'  '${var.optional_packages}'<enter>"
    ]
    boot = "c"
    boot_wait = "8s"

    # PACKER Autoinstall Settings
    http_directory = "arch/http" 
    ssh_username = "root"
    ssh_password = "packer" # temporary password
    ssh_timeout = "20m"
}

build {
    name = "arch"
    sources = ["source.proxmox-iso.arch"]

    provisioner "shell" {
        inline = [
            # Arch stuff
            "timedatectl set-timezone ${var.timezone}",
            "/usr/bin/pacman -Scc --noconfirm",
            # Identity
            "rm /etc/ssh/ssh_host_*",
            "rm -f /etc/machine-id /var/lib/dbus/machine-id",
            "dbus-uuidgen --ensure=/etc/machine-id",
            "dbus-uuidgen --ensure",
            "cloud-init clean",
            "rm -f /var/run/utmp",
            ">/var/log/lastlog",
            ">/var/log/wtmp", ">/var/log/btmp",
            "rm -rf /tmp/* /var/tmp/*",
            "unset HISTFILE; rm -rf /home/*/.*history /root/.*history",
            # Root login
            "sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config",
            "passwd -d root",
            "passwd -l root",
            # Cleaning up
            "sync"
        ]
    }
}