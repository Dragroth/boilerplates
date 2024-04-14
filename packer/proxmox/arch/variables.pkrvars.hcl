###  ISO ###
# You can use either iso_file or iso_url
iso_file        = "local:iso/archlinux-2024.03.01-x86_64.iso"
# iso_url         = "https://mirror2.evolution-host.com/archlinux/iso/2024.03.01/archlinux-x86_64.iso"
iso_checksum    = "0062e39e57d492672712467fdb14371fca4e3a5c57fed06791be95da8d4a60e3"

### PVE ###
proxmox_node            = "hv01"
storage_pool            = "local-lvm"
cloudinit_storage_pool  = "local-lvm"

### VM ###
cpu_type        = "host"
vm_id           = "8020"
bridge_name     = "vmbr100"
cores           = "2"
memory          = "2048"
disk_size       = "10G"
swap_size       = "2G"
country         = "country=PL" # used for mirrorlist
timezone        = "Europe/Warsaw"
language        = "en_US.UTF-8"
optional_packages = "vim intel-ucode less nano neofetch man"