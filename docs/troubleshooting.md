# Troubleshooting Guide for Proxmox VM Terraform Examples

This guide covers common issues when deploying virtual machines on your local Proxmox setup. The examples here are from my personal homelab experiments - these patterns work for me, and I've included notes about what to watch out for.

## Quick Start: Test Your Setup First

Before running `terraform apply`, verify these basics:

```bash
# 1. Can you reach the Proxmox API?
curl -k "https://your-proxmox:8006/api2/json/access/session" \
  -u root@pam:<token_or_password>

# 2. Check your storage pools exist
curl -k "https://your-proxmox:8006/api2/json/storage?content=lvm" \
  -u root@pam:<token_or_password> | jq '.data'

# 3. What VMs/templates do you have cloned?
curl -k "https://your-proxmox:8006/api2/json/resources/qemu?node=pve" \
  -u root@pam:<token_or_password> | jq '.data[] | select(.vmid>=100)'

# 4. SSH key accessible from where you run terraform?
ls -la ~/.ssh/proxmox
cat ~/.ssh/proxmox | grep -q "-----BEGIN" && echo "✓ Valid SSH key format"
```

---

## 📡 Proxmox API Connection Issues

### ❌ Error: "Failed to authenticate"

**What it means:** The provider can't log in to your Proxmox API.

**Check these things:**

1. **API token expired or invalid**
   ```bash
   # Create a new token if needed (via Proxmox GUI or CLI):
   # pveum user add root@pam --password <new-password>
   # pveum token add root root@pam --description 'Terraform' --privs='Data=* VMs=* Resources=* Users=Create'
   
   # Then set the env var:
   export PROXMOX_VE_API_TOKEN="root@pam!your_token=your_secret"
   ```

2. **Firewall blocking port 8006**
   ```bash
   telnet your-proxmox-ip 8006
   # Or: timeout 5 bash -c "echo >/dev/tcp/ip/8006"
   ```

3. **SSL certificate warning (self-signed is normal)**
   ```bash
   # The `-k` flag tells curl to skip cert verification
   # If you get real errors (not just warnings), check:
   openssl s_client -connect your-proxmox:8006 -showcerts | head -20
   ```

### ❌ Error: "API connection timed out"

**What it means:** Network latency or the node is overloaded.

**Try this:**

```bash
# In provider config (main.tf), increase timeout:
provider "proxmox" {
  insecure = true
  ssh { agent = true; private_key = file("~/.ssh/proxmox") }
  # Optional: timeout setting if supported by your provider version
}
```

---

## 👤 Cloud-Init User Account Problems

### ❌ Error: "User account already exists"

**What it means:** The template VM you're cloning has a user with that name.

**Solutions:**

1. **Use a unique username**
   ```bash
   # Instead of common names like 'ubuntu' or 'admin':
   terraform apply -var-file=terraform.tfvars \
     -var='vm_config.cloud_init.user_account.username="dev-user-00"'
   ```

2. **Or remove the conflict from templates**
   ```bash
   # Via Proxmox GUI: Edit template → Cloud-Init → Remove user from Users list
   # Or via CLI if you know what you're doing:
   ssh root@your-proxmox "pveum set <vmid> 'user_account.username=null'"
   ```

### ❌ Error: "Cloud-init cannot write SSH key"

**What it means:** Permissions are wrong on the VM's filesystem.

**Try this in your cloud-init user-data:**

```yaml
#cloud-config
package_update: true
package_upgrade: true

write_files:
  - path: /home/dev-user-00/.ssh/authorized_keys
    content: |
      ssh-rsa AAAAB3...your_key_here
    permissions: '0600'  # Important!
    
users:
  - name: dev-user-00
    ssh_authorized_keys:
      - ssh-rsa AAAAB3...your_key_here
    lock_passwd: true   # Security: no password needed
```

---

## 🌐 Network Device Ordering Failures

### ❌ Error: "Network device already exists with same MAC"

**What it means:** You're trying to assign IPs to more network interfaces than exist.

**Check the counts match:**

```bash
# In terraform.tfvars, your networks list should have N entries
networks = {
  lan = { bridge = "vmbr0" }
  wan = { bridge = "vmbr1" }
}

# And cloud_init.ip_configs should also have N entries (or be null for DHCP)
cloud_init = {
  user_account = { username = "dev", password = "..." }
  ip_configs = [
    { ipv4 = { address = "dhcp" } },       # → matches lan bridge
    { ipv4 = { address = "10.0.0.50/24" } }  # → matches wan bridge
  ]
}

# ❌ DON'T do this:
# 2 network devices but 3 IP configs - that will fail!
```

### ❌ Error: "Cannot assign IP to non-dynamic network interface"

**What it means:** You're trying to use cloud-init IPs without enabling the initialization block.

**Enable it properly:**

```bash
# Set cloud_init to a non-null object
vm_config.cloud_init = {
  user_account = { username = "dev", password = "..." }
  # If you don't need static IPs, leave ip_configs as null
  # The dynamic block will handle what you give it
}
```

---

## 💾 Storage Pool Not Found Errors

### ❌ Error: "Pool 'local-lvm' not found on this node"

**What it means:** The storage pool you configured doesn't exist on the target Proxmox node.

**Fixes:**

1. **List available pools:**
   ```bash
   curl -k "https://your-proxmox:8006/api2/json/storage" \
     -u root@pam:<token> | jq '.data'
   
   # Or check via API for specific content type:
   curl -k "https://your-proxmox:8006/api2/json/storage/local-lvm?content=lvm" \
     -u root@pam:<token> 2>&1 || echo "Pool doesn't exist or is offline"
   ```

2. **Create the pool first:**
   ```bash
   # Example: Create LVM thin pool
   ssh root@your-proxmox "vgcreate vg_local /dev/disk/by-id/*-hd* && \
     lvcreate --type thin-pool -L 50G -n thin_pool vg_local"
   ```

3. **Make sure the pool is online:**
   ```bash
   curl -k -X PUT "https://your-proxmox:8006/api2/json/storage/local-lvm/content" \
     -u root@pam:<token>
   ```

### ❌ Error: "Template VM doesn't exist or can't be cloned"

**What it means:** The `clone_id` you specified points to a non-existent template.

**Fixes:**

1. **List available templates:**
   ```bash
   curl -k "https://your-proxmox:8006/api2/json/resources/qemu?node=pve" \
     -u root@pam:<token> | jq '.data[] | select(.vmid>=100)'
   ```

2. **Disable cloning if you want a fresh VM:**
   ```bash
   terraform apply -var='vm_config.storage.os_drive.clone_id=null' \
                   -var='vm_config.storage.os_drive.full=false'
   ```
   
   *Note: This expects an existing disk or different setup.*

---

## 🌐 IP Configuration Assignments

### ❌ Error: "IP configuration 0 doesn't match any network device"

**What it means:** cloud-init's `ip_configs` list is misaligned with your network devices.

**Remember the order matters:**

```bash
# If you have 2 network devices:
networks = {
  lan = { bridge = "vmbr0" }
  wan = { bridge = "vmbr1" }
}

# Then ip_configs must match that order (or use null for DHCP):
cloud_init = {
  user_account = { username = "dev", password = "..." }
  ip_configs = [
    { ipv4 = { address = "dhcp" } },       # Index 0 → vmbr0/lan
    { ipv4 = { address = "10.0.0.50/24" } }  # Index 1 → vmbr1/wan
  ]
}

# ❌ DON'T add a 3rd IP config if you only have 2 network devices!
```

### Debug: See what interfaces Terraform created

```bash
# After deployment, check the VM's network config:
virsh domiflist <vm-id>

# And see the XML definition:
virsh dumpxml <vm-id> | grep -A3 "<interface>"

# If IPs aren't visible yet (qemu-agent not installed):
# Install inside the VM: apt install qemu-guest-agent && reboot
```

---

## 🗺️ State Management Issues

### ❌ Error: "Module not found or state invalid"

**What it means:** Terraform's internal map doesn't match what Proxmox actually has.

**Options:**

1. **Re-initialize Terraform (if you moved directories):**
   ```bash
   cd examples/windows
   rm -rf .terraform/
   terraform init -upgrade
   terraform plan  # Check it matches before applying again
   ```

2. **Import existing VM into Terraform:**
   ```bash
   # If the VM exists but isn't tracked by Terraform:
   terraform import proxmox_virtual_environment_vm.vm <vm-id-from-proxmox>
   terraform apply
   ```

3. **Reset state (nuclear option - backup first!):**
   ```bash
   # ⚠️ WARNING: This deletes all tracked resources from Terraform's memory
   # Only do this if you know what VMs you want to keep
   
   terraform state list > /tmp/backup.txt  # Keep record of what existed
   rm .terraform.lock.hcl                  # Remove lock file
   terraform init -upgrade -reset-state
    
   # Re-deploy your new configuration:
   terraform apply
   ```

---

## 🛠️ Quick Reference: Common Messages and Fixes

| Error Message | What to Check | Where |
|--------------|---------------|-------|
| "Failed to authenticate" | API token / SSH key permissions | Proxmox user tokens section |
| "User account already exists" | Username conflicts with template users | Cloud-init user-data in main.tf |
| "Pool not found" | Storage pool name matches Proxmox node's pools | Your Proxmox GUI → Storage tab |
| "Network device mismatch" | IP configs count = networks map entries | terraform.tfvars file |
| "Template doesn't exist" | clone_id points to valid VDI template | Proxmox resources/qemu API |
| "Module not found" | Terraform state diverged from Proxmox | Run `terraform plan` to see drift |

---

## 🔍 General Debugging Tips

### Enable verbose provider output

Add this to your `provider "proxmox"` block temporarily:

```bash
# In main.tf - only for debugging!
provider "proxmox" {
  insecure = true
  ssh { 
    agent = true 
    private_key = file("~/.ssh/proxmox")
    verbose = true  # Uncomment only for debugging
  }
}
```

Then run:
```bash
terraform apply -verbose
```

### Check the Terraform state file

```bash
cd examples/windows
terraform state list        # See what's tracked
terraform state show vm     # Full details on one resource
```

---

## 📚 More Help

If you've gone through this guide and still stuck:

1. **Check Proxmox Provider GitHub:** https://github.com/bpg/terraform-provider-proxmox/issues
2. **Proxmox docs:** https://pve.proxmox.com/pve-docs/
3. **Terraform registry provider page:** https://registry.terraform.io/providers/bpg/proxmox/latest/docs

---

## 💡 Remember

These examples came from my personal experiments - not production environments. If something doesn't work, it might be:

- My specific Proxmox setup quirks
- Provider version differences (0.101.1 is what I've been using)
- Storage pool naming conventions
- Network bridge names on my hardware

Feel free to adapt these patterns to your setup! The key concepts (multi-VM deployments, cloud-init automation, storage cloning) remain the same.
