# Ubuntu Server
# ---
# Packer Template to create Ubuntu Server on Proxmox

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
    default = "local:iso/ubuntu-22.04.3-live-server-amd64.iso"
}

variable "iso_url" {
    type = string
    default = "https://releases.ubuntu.com/jammy/ubuntu-22.04.4-live-server-amd64.iso"
}

variable "iso_checksum" {
    type = string
    default = "45f873de9f8cb637345d6e66a583762730bbea30277ef7b32c9c3bd6700a32b2"
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
    default = "9997"
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

source "proxmox-iso" "ubuntu-server" {

    # Proxmox Connection Settings
    proxmox_url = var.proxmox_api_url
    username = var.proxmox_api_token_id
    token = var.proxmox_api_token_secret
    insecure_skip_tls_verify = false

    # VM General Settings
    node = var.proxmox_node
    vm_id = var.vm_id
    vm_name = "ubuntu-server"
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
        firewall  = "false"
    }

    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = var.cloudinit_storage_pool

    # PACKER Boot Commands
    boot_command = [
        "<wait>",
        "e<wait>",
        "<down><down><down><end>",
        "<bs><bs><bs><bs><wait>",
        "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
        "<f10><wait>"
    ]
    boot = "c"
    boot_wait = "5s"

    # PACKER Autoinstall Settings
    http_directory = "ubuntu-2204/http" 
    ssh_username = "ubuntu"
    # ssh_private_key_file = "~/.ssh/id_ed25519"
    ssh_password = "packer" # temporary password
    ssh_timeout = "20m"
}

build {
    name = "ubuntu-server"
    sources = ["source.proxmox-iso.ubuntu-server"]

    provisioner "shell" {
        inline = [
            # Ubuntu stuff
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo apt-get -y install ${var.optional_packages}",
            "sudo apt-get -y autoremove --purge",
            "sudo apt-get -y clean",
            "sudo apt-get -y autoclean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo rm -f /etc/netplan/00-installer-config.yaml",
            # Identity
            "sudo rm -f /etc/machine-id /var/lib/dbus/machine-id",
            "sudo dbus-uuidgen --ensure=/etc/machine-id",
            "sudo dbus-uuidgen --ensure",
            "sudo cloud-init clean",
            # Login
            "sudo rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf"
            "sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config",
            "sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config",
            "sudo passwd -d root",
            "sudo passwd -d ubuntu",
            "sudo passwd -l root",
            # Cleaning up
            "sync"
        ]
    }

}