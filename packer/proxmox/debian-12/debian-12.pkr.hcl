# Debian 12 (bookworm)
# ---
# Packer Template to create Debian 12 on Proxmox

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
    default = "local:iso/debian-12.5.0-amd64-netinst.iso"
}

variable "iso_url" {
    type = string
    default = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso"
}

variable "iso_checksum" {
    type = string
    default = "013f5b44670d81280b5b1bc02455842b250df2f0c6763398feb69af1a805a14f"
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
    default = "9998"
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

source "proxmox-iso" "debian-12" {

    # Proxmox Connection Settings
    proxmox_url = var.proxmox_api_url
    username = var.proxmox_api_token_id
    token = var.proxmox_api_token_secret
    insecure_skip_tls_verify = false

    # VM General Settings
    node = var.proxmox_node
    vm_id = var.vm_id
    vm_name = "debian-12"
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
    iso_url = var.iso_url
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
        "<<wait>",
        "<down><down><enter><wait>",
        "<down><down><down><down><down>e<wait>",
        "<down><down><down><end>",
        "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg<f10>"
    ]
    boot = "c"
    boot_wait = "5s"

    # PACKER Autoinstall Settings
    http_directory = "http" 
    ssh_username = "root"
    ssh_password = "packer" # temporary password
    ssh_timeout = "20m"
}

build {
    name = "debian-12"
    sources = ["source.proxmox-iso.debian-12"]

    provisioner "shell" {
        inline = [
            "apt-get install ${var.optional_packages}"
            "timedatectl set-timezone ${var.timezone}",
            "rm /etc/ssh/ssh_host_*",
            "rm -f /etc/machine-id /var/lib/dbus/machine-id",
            "dbus-uuidgen --ensure=/etc/machine-id",
            "dbus-uuidgen --ensure",
            "sudo passwd -d root", # disable root password login
            "apt-get -y autoremove --purge",
            "apt-get -y clean",
            "apt-get -y autoclean",
            "cloud-init clean",
            "sync"
        ]
    }

    provisioner "file" {
        destination = "/etc/cloud/cloud.cfg"
        source = "files/cloud.cfg"
    }
    
    provisioner "file" {
        destination = "/etc/cloud/99-pve.cfg"
        source = "files/99-pve.cfg"
    }
}