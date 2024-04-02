###  ISO ###
# You can use either iso_file or iso_url
# iso_file        = "local:iso/archlinux-2024.03.01-x86_64.iso"
iso_url         = "https://releases.ubuntu.com/jammy/ubuntu-22.04.4-live-server-amd64.iso"
iso_checksum    = "45f873de9f8cb637345d6e66a583762730bbea30277ef7b32c9c3bd6700a32b2"

### PVE ###
proxmox_node            = "hv01"
storage_pool            = "local-lvm"
cloudinit_storage_pool  = "local-lvm"

### VM ###
cpu_type        = "host"
vm_id           = "8000"
bridge_name     = "vmbr100"
cores           = "2"
memory          = "2048"
disk_size       = "10G"
swap_size       = "2G"
optional_packages = "vim intel-ucode less nano neofetch curl"