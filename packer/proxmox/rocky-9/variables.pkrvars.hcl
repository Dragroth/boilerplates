###  ISO ###
# You can use either iso_file or iso_url
iso_file        = "local:iso/Rocky-9.3-x86_64-minimal.iso"
# iso_url         = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso"
iso_checksum    = "013f5b44670d81280b5b1bc02455842b250df2f0c6763398feb69af1a805a14f"

### PVE ###
proxmox_node            = "hv01"
storage_pool            = "local-lvm"
cloudinit_storage_pool  = "local-lvm"

### VM ###
cpu_type        = "host"
vm_id           = "8030"
bridge_name     = "vmbr100"
cores           = "2"
memory          = "2048"
disk_size       = "10G"
swap_size       = "2G"
optional_packages = "vim less nano"