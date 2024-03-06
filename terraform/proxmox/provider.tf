terraform {
	required_version = ">= 0.13.0"

	required_providers {
		proxmox = {
			source = "bpg/proxmox"
			version = "0.48.1"
		}
	}
}

variable "proxmox_api_url" {
	type = string
}

variable "proxmox_api_token_secret" {
	type            = string
	sensitive       = true
}

provider "proxmox" {
endpoint  = var.proxmox_api_url
	api_token = var.proxmox_api_token_secret
	insecure  = false
	ssh {
		agent    = true
		username = "root"
	}
}
