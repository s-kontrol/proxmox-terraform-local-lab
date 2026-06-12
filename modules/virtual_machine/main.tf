terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.101.1"
    }
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.vm_config.name
  node_name = var.pve_node
  machine   = var.vm_config.machine

  cpu {
    cores = var.vm_config.cpu.cores
    type  = var.vm_config.cpu.type
  }

  memory {
    dedicated = var.vm_config.memory.dedicated
    # floating   = floor(var.vm_config.memory.dedicated / var.vm_config.memory.balloon_factor)  # Removed: balloon_factor deprecated
  }

  agent {
    enabled = var.vm_config.agent.enabled
  }

  # Boot Disk
  clone {
    vm_id = var.vm_config.storage.os_drive.clone_id
    full  = var.vm_config.storage.os_drive.clone_mode
  }

  disk {
    datastore_id = var.vm_config.storage.os_drive.pool
    interface    = var.vm_config.storage.os_drive.interface
    size         = var.vm_config.storage.os_drive.size
    file_format  = var.vm_config.storage.os_drive.file_format
    ssd          = var.vm_config.storage.os_drive.ssd
  }

  dynamic "disk" {
    for_each = var.vm_config.storage.data_drive.enabled ? [1] : []
    content {
      datastore_id = var.vm_config.storage.data_drive.pool
      interface    = var.vm_config.storage.data_drive.interface
      size         = var.vm_config.storage.data_drive.size
      file_format  = var.vm_config.storage.data_drive.file_format
      ssd          = var.vm_config.storage.data_drive.ssd
    }
  }

  # Dynamic Network Interfaces
  dynamic "network_device" {
    for_each = var.vm_config.networks
    content {
      bridge      = network_device.value.bridge
      mac_address = network_device.value.mac_address # Leaves as null to let Proxmox auto-generate
      firewall    = network_device.value.firewall
      model       = network_device.value.model
      vlan_id     = network_device.value.vlan_id
    }
  }

  # Dynamic Cloud-Init
  dynamic "initialization" {
    for_each = var.vm_config.cloud_init != null ? [var.vm_config.cloud_init] : []
    content {

      dynamic "user_account" {
        for_each = initialization.value.user_account != null ? [initialization.value.user_account] : []
        content {
          username = user_account.value.username
          password = user_account.value.password
          keys     = user_account.value.ssh_keys
        }
      }

      # Handles multiple IP configurations (maps to ipconfig0, ipconfig1, etc.)
      dynamic "ip_config" {
        for_each = initialization.value.ip_configs != null ? initialization.value.ip_configs : []
        content {

          dynamic "ipv4" {
            for_each = ip_config.value.ipv4 != null ? [ip_config.value.ipv4] : []
            content {
              address = ipv4.value.address
              gateway = ipv4.value.gateway
            }
          }

          dynamic "ipv6" {
            for_each = ip_config.value.ipv6 != null ? [ip_config.value.ipv6] : []
            content {
              address = ipv6.value.address
              gateway = ipv6.value.gateway
            }
          }

        }
      }
    }
  }
}
