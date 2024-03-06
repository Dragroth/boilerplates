resource "proxmox_virtual_environment_vm" "name" {
	name		= "name"
	description = "Description"
	tags 		= ["debian", "terraform"]

	node_name	= "node"
	vm_id		= 502

	agent {
		enabled = true
	}

	clone {
		# Cloned template data
		datastore_id	= "local-lvm"
		retries			= 3
		vm_id			= 8010
		full			= true
	}

	cpu {
		# Number of cores (and type)
		cores	= 2
		type	= "host"
	}

	memory {
		# Memory size
		dedicated = 1024
	}

	network_device {
		# Bridge name
    	bridge = "vmbr100"
  	}

	disk {
		# Disk size and datastore (this is cloned disk, it allows managing it via terraform later)
    	datastore_id	= "local-lvm"
    	interface		= "scsi0"
		size			= "8"
  	}

	vga {
		enabled	= true
		memory	= 16
	}

	# Cloud-init
	initialization {
		ip_config {
			ipv4 {
				address = "0.0.0.0/0"
				gateway = "gateway"
			}
    	}

		user_account {
			username = "debian"
			keys	 = ["key", "key2"]
		}
	}
}