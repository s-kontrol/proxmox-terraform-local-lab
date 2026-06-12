# Terraform Proxmox Virtual Machine Modules

A professional portfolio of Terraform infrastructure-as-code examples demonstrating VM provisioning, multi-VM orchestration, cloud-init automation, and patterns on Proxmox VE.

## 🎯 Purpose

This repository demonstrates **Terraform workflows** for homelab and personal use cases. It showcases expertise in:

- ✅ Multi-VM deployments with a single `terraform apply`
- ✅ Cloud-init automation for OS provisioning
- ✅ Flexible networking with multiple bridges and VLANs
- ✅ Storage cloning strategies (efficient templates + hot-swap data drives)
- ✅ qemu-guest-agent integration for live IP visibility
- ✅ Version-locked providers for reproducible builds

## 📁 Repository Structure

```
.
├── modules/                    # Reusable Terraform modules
│   └── virtual_machine/        # Core VM provisioning module
│       ├── main.tf            # VM resource definition with dynamic blocks
│       ├── outputs.tf         # IP addresses, health checks
│       └── variables.tf       # Schema with full documentation
├── examples/                   # deployment templates
│   ├── windows/               # Windows workstation + test lab examples
│   │   ├── main.tf           # Provider config + VM module orchestration
│   │   ├── variables.tf      # Type-safe VM configuration schema
│   │   ├── terraform.tfvars  # Example VM specs (workstation, test)
│   │   └── README.md         # Deployment guide and capabilities
│   └── [more examples...]     # Additional scenarios welcome!
├── docs/                       # Usage guides and troubleshooting
│   ├── usage-guide.md         # 5 common deployment scenarios
│   ├── troubleshooting.md     # 7 major issue categories with fixes
│   └── ...                    # More documentation coming
└── .gitignore                  # Protects state files from accidental commits

```

## 🚀 Quick Start

### Prerequisites

1. **Terraform v1.5+**: `terraform --version`
2. **Proxmox VE** with:
   - API endpoint accessible (`https://<ip>:8006/`)
   - SSH access configured (`root@pam` user)
   - Storage pools created (e.g., `local-lvm`, ZFS, Ceph)
   - Base templates cloned for each OS type

### Set Environment Variables

```bash
# Proxmox API endpoint (use HTTPS with self-signed cert acceptable)
export PROXMOX_VE_ENDPOINT="https://192.168.1.100:8006/"

# API token with VM creation permissions
export PROXMOX_VE_API_TOKEN="root@pam!your_token=your_secret_long_string_here"

# SSH private key for Proxmox user (required for certain operations)
export PROXMOX_SSH_PRIVATE_KEY="$HOME/.ssh/proxmox"
```

### Deploy Example (Windows Multi-VM)

```bash
cd examples/windows

# Initialize Terraform (downloads provider, reads config)
terraform init

# Review what will be created
terraform plan

# Deploy multiple VMs at once
terraform apply
```

**Outputs after deployment:**

```
Outputs:
  ip = [
    "10.0.0.50",      # workstation-00 LAN IP (via qemu-agent)
    "192.168.1.100"   # workstation-00 WAN/Management IP
  ]
```

## 📊 Example: Windows Multi-VM Deployment

The `examples/windows` template demonstrates **multi-VM orchestration**:

| VM | Name | CPU Cores | RAM | Use Case |
|-----|------|-----------|-----|----------|
| Workstation | `workstation-00` | 8 (host-passthrough) | 16 GB | Video editing, compilation |
| Test Lab | `test-home-00` | 4 (x86-64-v2-AES) | 2 GB | Testing, light services |

**Both VMs deploy in one command**, demonstrating infrastructure scaling patterns.

### Key Capabilities Demonstrated:

- **Multi-resource orchestration**: Create multiple complex resources atomically
- **Cloud-init automation**: User accounts, SSH keys, network config (no drift!)
- **Dynamic networking**: Per-VM bridge/VLAN/firewall rules
- **Storage strategies**: Template cloning + hot-swap data drives
- **Agent integration**: Live IP visibility without manual scanning

## 📚 Documentation

| Doc | Location | Content |
|-----|----------|---------|
| **Usage Guide** | `docs/usage-guide.md` | 5 common scenarios: dev workstation, multi-role server, DB cache, VLAN office, disaster recovery |
| **Troubleshooting** | `docs/troubleshooting.md` | API auth errors, state conflicts, network binding failures, agent installation, more |
| **Example README** | `examples/README.md` | Detailed walkthrough of each example directory with architecture diagrams |

## 🛠️ How It Works

### Architecture:

```
┌─────────────────────────────────────────────────────────┐
│                    Terraform Config                       │
│  ┌──────────────────────┐    ┌───────────────────────┐   │
│  │  main.tf             │    │  variables.tf         │   │
│  │  - Provider setup    │    │  - Type-safe schema   │   │
│  │  - Module calls      │    │  - All VM fields      │   │
│  └──────────────────────┘    └───────────────────────┘   │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │  terraform.tfvars                                │    │
│  │  - Actual VM names, specs, networks              │    │
│  │  - Storage pools, clone IDs                      │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│              Proxmox Virtual Machine Module              │
│  ┌──────────────────────┐    ┌───────────────────────┐   │
│  │  Resource: proxmox_  │    │  Dynamic Blocks:      │   │
│  │  virtual_environment_ │    │  - disk (boot)        │   │
│  │    vm "vm"           │    │  - network_device[]   │   │
│  │                      │    │  - initialization[]   │   │
│  └──────────────────────┘    └───────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    Proxmox VE Hypervisor                  │
│  - Spawns VMs from base templates                        │
│  - Applies cloud-init on first boot                      │
│  - Registers IPs with qemu-guest-agent                   │
└─────────────────────────────────────────────────────────┘
```

### Module Design:

**Main Orchestrator** (`main.tf`):
- Declares Proxmox provider (SSH + API token auth)
- Iterates over `var.vms` map using `for_each` (declarative scaling!)
- Calls reusable `virtual_machine` module with complete config

**Core Module** (`modules/virtual_machine/main.tf`):
- Single VM resource with full Proxmox configuration
- Dynamic blocks for: storage disks, network interfaces, cloud-init
- Clean separation of concerns

## 🎯 Patterns Demonstrated

| Pattern | Location | Why It Matters |
|---------|----------|----------------|
| **Version locking** | `.terraform.lock.hcl` | Reproducible builds across teams/CI |
| **Module separation** | `modules/virtual_machine/` | Reusability, single responsibility |
| **Type safety** | `variables.tf` | Compile-time error catching (Terraform way) |
| **For_each scaling** | `main.tf line 23` | Declarative multi-resource creation |
| **Cloud-init automation** | Cloud-init blocks | Drift-free OS configurations |
| **State isolation** | Per-ENV folders | Safe parallel development/production |

## 🐛 Troubleshooting

See [`docs/troubleshooting.md`](docs/troubleshooting.md) for:

1. **SSH authentication failures** - Key permissions, user existence
2. **Provider not found** - Network access to registry.terraform.io
3. **VM already exists** - State file conflicts or clone mode issues
4. **IP addresses not returned** - qemu-guest-agent installation needed
5. **Network binding errors** - Bridge/VLAN configuration mismatches
6. **Storage pool offline** - Clone source validation
7. **Cloud-init timeout** - First-boot script timing

## 🔐 Security Best Practices

This portfolio demonstrates security-conscious patterns:

- ✅ **API tokens**: Never hardcode in code (use env vars)
- ✅ **SSH keys preferred**: Passwordless authentication
- ✅ **Principle of least privilege**: Provider permissions scoped to needs
- ✅ **State file protection**: `.gitignore` prevents committing secrets
- ✅ **2FA enabled**: Proxmox 2-layer authentication (token + 2FA)
- ✅ **SSH key distribution via cloud-init**: Not stored in terraform.tfvars

## 🔧 Development Notes

### Current Status:

- ✅ Core `virtual_machine` module working and tested
- ✅ Multiple examples demonstrated (Windows multi-VM)
- ✅ Documentation complete (usage guide, troubleshooting)
- 🟡 More examples welcome (Linux servers, containers, networks)
- 🟡 CI/CD integration (GitHub Actions, etc.) TBD

### Known Limitations:

- State management currently local (remote backend ready for production)
- Some provider version quirks with Terraform core versions
- No monitoring/alerting integration yet

## 📄 License

MIT License - Feel free to use, modify, and extend these examples!

## 🙏 Credits

- **Proxmox VE**: Open-source hypervisor (https://www.proxmox.com)
- **Terraform by HashiCorp**: Infrastructure as code (https://terraform.io)
- **bpg/proxmox Terraform provider**: Community-maintained Proxmox plugin

---

**Built with ❤️ for homelab.**
