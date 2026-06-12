vms = {
  "workstation-00" = {
    agent = { enabled = true }
    name  = "workstation-00"
    cpu = {
      cores = 8
      type  = "host"
    }
    memory = {
      dedicated      = 16384
      balloon_factor = 1
    }
    storage = {
      os_drive = {
        pool       = "local-lvm"
        source     = "local-lvm:base-9010-disk-0"
        size       = 120
        clone_id   = 9011
        clone_mode = false
      }
      data_drive = {
        enabled = false
        size    = 40
        pool    = "local-lvm"
      }
    }
    networks = {
      lan = {
        bridge = "vmbr10"
      }
      wan = {
        bridge = "vmbr0"
      }

    }
    cloud_init = {
      user_account = {
        username = "kontrol"
        password = "asdasd123!A"
      }
    }
  }
  "test-home-00" = {
    agent = { enabled = true }
    name  = "test-home-00"
    cpu = {
      cores = 4
      type  = "x86-64-v2-AES"
    }
    memory = {
      dedicated      = 2048
      balloon_factor = 1
    }
    storage = {
      os_drive = {
        pool       = "local-lvm"
        source     = "local-lvm:base-9010-disk-0"
        size       = 32
        clone_id   = 9011
        clone_mode = false
      }
      data_drive = {
        enabled = true
        size    = 40
        pool    = "local-lvm"
      }
    }
    networks = {
      lan = {
        bridge = "vmbr10"
      }
      wan = {
        bridge = "vmbr0"
      }

    }
    cloud_init = {
      user_account = {
        username = "kontrol"
        password = "asdasd123!A"
      }
    }
  }

}
