output nlb_eips {
  description = "Map of EIPs created for NLBs"
  value = {
    for k, v in aws_eip.nlb :
    k => v.public_ip
  }
}

output alb_dns {
  description = "Map of DNS Names for each ALB"
  value = {
    for k, v in aws_lb.alb :
    k => v.dns_name
  }
}

output nlb_dns {
  description = "Map of DNS Names for each NLB"
  value = {
    for k, v in aws_lb.nlb :
    k => v.dns_name
  }
}

output nlbs {
  description = "Full output of all NLBs"
  value = aws_lb.nlb
}

output albs {
  description = "Full output of all ALBs"
  value = aws_lb.alb
}