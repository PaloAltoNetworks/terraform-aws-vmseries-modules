#output "nlb_eips" {
#  value = {
#    for eip in aws_eip.nlb:
#    eip.tags.Name => eip.public_ip
#  }
#}

# output "alb_dns" {
#   value = {
#     for alb in aws_lb.alb :
#     alb.name => alb.dns_name
#   }
# }

# output "panos_warning" {
#   value = "Changes to Panorama have not been committed. Please review and commit and push changes."
# }