# output "firewalls_created" {
#   description = "List of firewalls created"
#   value       = zipmap(var.name, var.management_elastic_ip_addresses)
# }

# output "untrust_elastic_ip_addresses" {
#   description = "List of Firewall Untrust Elastic IPs"
#   value       = var.untrust_elastic_ip_addresses
# }

# output "management_elastic_ip_addresses" {
#   description = "List of Firewall Management Elastic IPs"
#   value       = var.management_elastic_ip_addresses
# }

# output "customer_gw_asn" {
#   description = "Firewall BGP ASNs to be used for customer gw"
#   value       = var.customer_gw_asn
# }

# output "firewall_ids" {
#   description = "ID of firewall instances"
#   value       = [aws_instance.pa-vm-series.*]
# }


output "firewalls" {
  value = {
    for k, f in aws_instance.pa-vm-series :
    k => f
  }
}

