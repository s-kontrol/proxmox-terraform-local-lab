variable "vms" {
  description = "Configuration for the VM"
  type = map(object({
    name    = string
    machine = optional(string, "q35")
    cpu = object({
      cores = number
      type  = string
    })
    agent = object({
      enabled = optional(bool, false)
    })
    memory = object({
      dedicated      = number
      balloon_factor = optional(number, 1) # 1 disabled. 
    })
    storage = object({
      os_drive = object({
        pool        = string
        source      = string
        size        = optional(number)
        clone_id    = number
        clone_mode  = optional(bool, false)
        interface   = optional(string, "scsi0")
        file_format = optional(string, "raw")
        ssd         = optional(bool, true)

      })
      data_drive = object({
        enabled     = optional(bool, false)
        size        = optional(number)
        pool        = optional(string)
        interface   = optional(string, "scsi1")
        file_format = optional(string, "raw")
        ssd         = optional(bool, true)
      })
    })
    # Changed from a single object to a map/list of objects
    networks = map(object({
      bridge      = string
      mac_address = optional(string)
      firewall    = optional(bool, false)
      model       = optional(string, "virtio")
      vlan_id     = optional(number)
    }))

    cloud_init = optional(object({
      user_account = optional(object({
        username = optional(string)
        password = optional(string)
        ssh_keys = optional(list(string))
      }))

      # List allows sequential mapping to multiple network devices
      ip_configs = optional(list(object({
        ipv4 = optional(object({
          address = string           # e.g., "dhcp" or "10.0.0.10/24"
          gateway = optional(string) # e.g., "10.0.0.1"
        }))
        ipv6 = optional(object({
          address = string
          gateway = optional(string)
        }))
      })))
    }))


  }))
}

variable "pve_node" {
  description = "Proxmox node name"
  default     = "pve-home"
  type        = string
}
