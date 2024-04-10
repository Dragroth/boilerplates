# Rocky Linux
# ---
# Packer Template to create Rocky 9 on Proxmox

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

# VM variables
variable "iso_file" {
    type = string
    default = "local:iso/Rocky-9.3-x86_64-minimal.iso"
}
 
variable "iso_url" {
    type = string
    default = "https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9.3-x86_64-minimal.iso"
}

variable "iso_checksum" {
    type = string
    default = "eef8d26018f4fcc0dc101c468f65cbf588f2184900c556f243802e9698e56729"
}

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

source "proxmox-iso" "rocky-9" {

    # Proxmox Connection Settings
    proxmox_url = var.proxmox_api_url
    username = var.proxmox_api_token_id
    token = var.proxmox_api_token_secret
    insecure_skip_tls_verify  = false

    # VM General Settings
    node = var.proxmox_node
    vm_id = var.vm_id
    vm_name = "rocky-9"
    template_description = "Built from ${basename(var.iso_file)} on ${formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())}"
    cores = var.cores
    memory = var.memory
    cpu_type = var.cpu_type
    qemu_agent = true
    
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
    boot_command = ["<tab> text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/inst.ks<enter><wait>"]
    boot = "c"
    boot_wait = "8s"

    # PACKER Autoinstall Settings
    http_directory = "http" 
    ssh_username = "root"
    ssh_password = "packer" # temporary password
    ssh_timeout = "20m"
}

build {
    name = "arch"
    sources = ["source.proxmox-iso.rocky-9"]

    provisioner "shell" {
        inline = [
            "rm /etc/ssh/ssh_host_*",
            "rm -f /etc/machine-id /var/lib/dbus/machine-id",
            "dbus-uuidgen --ensure=/etc/machine-id",
            "dbus-uuidgen --ensure",
            "cloud-init clean",
            "/usr/bin/pacman -Scc --noconfirm",
            "usermod -p '!' root",
            "sync"
        ]
    }
}