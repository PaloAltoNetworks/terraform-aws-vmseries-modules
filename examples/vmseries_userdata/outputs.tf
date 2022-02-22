output "mgmt_eip" {
  description = "The Elastic IP of the VM-Series Management interface."
  value       = module.vmseries["vmseries01"].instance.public_ip
}
