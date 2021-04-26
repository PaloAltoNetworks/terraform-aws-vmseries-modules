output "nlb_eips" {
 value = {
    for k, v in aws_eip.nlb:
    k => v.public_ip
  }
}

# output "alb_dns" {
#   value = {
#     for alb in aws_lb.alb :
#     alb.name => alb.dns_name
#   }
# }
