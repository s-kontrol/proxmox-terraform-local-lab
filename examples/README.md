# Terraform Proxmox VM Examples

Terraform-based homelab templates for deploying virtual machines on Proxmox VE. This portfolio demonstrates production-ready infrastructure-as-code patterns used in real-world DevOps environments.

## ✨ Features

- **Multi-VM deployments**: Create multiple VMs with different specifications in one run
- **Cloud-init support**: Automatic OS setup with user accounts, SSH keys, and network configuration
- **Flexible networking**: Multiple network bridges with optional VLAN/firewall rules
- **Dynamic storage**: SSD/NVMe cloning with hot-swappable data drives
- **qemu-guest-agent**: Full visibility into VM IPs and health status

## 📦 Example Usage (Windows Multi-VM)

```bash
# Navigate to the example directory
cd examples/windows

# Deploy multiple VMs at once
terraform init
terraform plan    # Review what will be created
terraform apply   # Create all VMs
```

### What it deploys:

- **workstation-00**: 8-core host CPU, 16GB RAM, dual NIC (LAN/WAN)
- **test-home-00**: 4-core vCPU, 2GB RAM, dual NIC with additional data disk

Both VMs are automatically configured with cloud-init for user accounts and network settings.

### Output:

```
Outputs:
  ip = ["10.0.0.x", "192.168.x.x"]  # VM IPs after qemu-agent is installed
```

## 🛠️ Prerequisites

Before running any example, ensure you have:

1. **Proxmox VE cluster** with nodes configured
2. **SSH access** to Proxmox (`~/.ssh/proxmox` private key)
3. **API token** with VM creation permissions
4. **Storage pools** configured (e.g., `local-lvm`, ZFS, Ceph)
5. **Template base images** cloned for each OS type

### Environment Variables (Recommended):

```bash
export PROXMOX_VE_ENDPOINT="https://192.168.1.100:8006/"
export PROXMOX_VE_API_TOKEN="root@pam!your_token=your_secret"
```

## 📝 Configuration Files

| File | Purpose |
|------|---------|
| `main.tf` | Provider configuration and VM module orchestration |
| `variables.tf` | Schema definitions for VM specifications |
| `terraform.tfvars` | Actual values for VM deployment |
| `.terraform.lock.hcl` | Provider version locking (critical for reproducible builds) |

## 🚀 Quick Start

### 1. Clone and Navigate
```bash
git clone https://github.com/your-username/proxmox-terraform-local-lab.git
cd proxmox-terraform-local-lab/examples/windows
```

### 2. Set Environment Variables
```bash
export PROXMOX_VE_ENDPOINT="https://YOUR_PROXMOX_IP:8006/"
export PROXMOX_VE_USER="root@pam"
export PROXMOX_VE_TOKEN="root@pam!your_token=your_secret_value"
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Review the Plan
```bash
terraform plan
```
*Check that only your intended VMs will be created*

### 5. Deploy
```bash
terraform apply -auto-approve
```

## 📊 Example VM Configurations

The `terraform.tfvars` file demonstrates different VM use cases:

| VM | CPU | RAM | Use Case |
|-----|-----|------|----------|
| workstation-00 | 8 cores (host-passthrough) | 16 GB | Heavy workloads (video editing, compilation) |
| test-home-00 | 4 cores (x86-64-v2-AES) | 2 GB | Lightweight services (monitoring, web server) |

### Common Patterns:

```hcl
# Production VM with full disk encryption support
vm = {
  name    = "production-app"
  cpu = { cores = 8, type = "host-passthrough" }
  memory = { dedicated = 16384, balloon_factor = 0 }
  storage = { ... }
}

# Test/Dev VM with shared CPU pool
vm = {
  name    = "test-lab-01"
  cpu = { cores = 2, type = "kvm64" }
  memory = { dedicated = 4096, balloon_factor = 2 }
  storage = { ... }
}
```

## 🎯 Key Capabilities Demonstrated

### Multi-VM Orchestration
Create and manage multiple VMs with a single `terraform apply` - essential for:
- Scaling test environments
- Running service stacks (database + app + web)
- Disaster recovery replication

### Cloud-init Automation
Eliminate post-deployment configuration drift by automating:
- User account creation
- SSH key distribution
- Network interface configuration
- Static IP addressing

### Dynamic Storage Management
Supports:
- **Clone mode**: Efficient template-based deployments
- **Full clone**: Independent snapshots for testing
- **Hot-swap data drives**: Add storage without rebooting VMs

### Networking Flexibility
Configure per-VM:
- Multiple NICs with different bridge/VLAN combinations
- Port forwarding rules via firewall settings
- Bonding/team configurations (advanced)

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| "SSH authentication failed" | Ensure `~/.ssh/proxmox` key has read permissions (600) and Proxmox user exists |
| "Provider not found" | Run `terraform init` with network access to registry.terraform.io |
| "VM already exists" | Either destroy (`terraform destroy`) or use clone_mode = true |
| IP address not returned | Install qemu-guest-agent inside the VM and reboot |

## 📚 For Developers

This example demonstrates Terraform best practices:

- **Provider version pinning**: `.terraform.lock.hcl` ensures reproducibility
- **Module separation**: Clean separation between main orchestration and implementation
- **Type-safe configuration**: Strongly-typed `variables.tf` with full documentation
- **Immutable infrastructure**: State files prevent accidental modifications

## 🔐 Security Considerations

For production deployment, ensure:

1. **Rotate API tokens** after initial setup
2. **Use SSH keys instead of passwords** for cloud-init users
3. **Restrict provider permissions** to minimum required scope
4. **Enable Proxmox 2FA** in addition to API token authentication
5. **Never commit `.terraform/` or state files** to public repos (see `.gitignore`)

## 🌟 Portfolio Value

This example demonstrates:

- ✅ **Infrastructure-as-code mastery**: Complex resource orchestration
- ✅ **Production patterns**: Version locking, module separation, documentation
- ✅ **Real-world understanding**: Storage cloning, cloud-init, networking
- ✅ **Mentorship quality**: Troubleshooting guide, security best practices
- ✅ **Problem-solving**: Handles edge cases (existing VMs, agent installation)

## 📄 License

This portfolio is provided as-is for demonstration purposes. Modifications are encouraged for your own homelab!

---

*Generated as part of a professional DevOps portfolio - demonstrating expertise in infrastructure automation, cloud-native patterns, and production-grade Terraform workflows.*
