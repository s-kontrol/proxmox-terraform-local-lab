terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.101.1"
    }
  }
}

provider "proxmox" {
  # It is good practice not to hardcode credentials here. Use environment variables:
  # export PROXMOX_VE_ENDPOINT="https://ip:8006/"
  # export PROXMOX_VE_API_TOKEN="root@pam!your_token=your_secret"
  insecure  = true # Homelab setting: ignores Proxmox self-signed certificates

  ssh {
    agent       = true # qemu agent to see VM ips.
    username    = "root" # proxmox user
    private_key = file("~/.ssh/proxmox") # Provider needs ssh access for some operations
  }
}

module "virtual_machines" {
  source   = "../../modules/virtual_machine"
  for_each = var.vms

  pve_node = "pve-home"

  # Because the child module expects a single object that perfectly matches 
  # the structure of each.value, we can just pass the whole thing in one line!
  vm_config = each.value
}
