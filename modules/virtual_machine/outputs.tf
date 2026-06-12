output "ip" {
  value       = proxmox_virtual_environment_vm.vm.ipv4_addresses
  description = "The IP addresses of this specific VM (Requires qemu-guest-agent installed in the VM)"
}
