##########################
### AWS Variables      ###
##########################
region = "ca-central-1"

global_tags = {
  managed-by = "Terraform"
  foo        = "bar"
}

vpc_id              = "vpc-12345"
elb_subnet_ids      = ["subnet-12345", "subnet-12345", "subnet-12345"]
target_instance_ids = ["i-12345", "i-12345"]

// Define each NLB, and the applications associatd with each
// Names for ELBs in AWS are not tags, thus name change will force replacement
// There can only be one app for each nlb with the same Listener Port. Use multiple NLBs for multiple inbound applications using same port
nlbs = {
  nlb01 = {
    name                             = "nlb01-inbound"
    internal                         = false
    eips                             = true
    enable_cross_zone_load_balancing = true
    apps = {
      app01 = {
        name          = "inbound-nlb01-app01-ssh"
        protocol      = "TCP"
        listener_port = "22"
        target_port   = "5001"
      }
      app02 = {
        name          = "inbound-nlb01-app02-https"
        protocol      = "TCP"
        listener_port = "443"
        target_port   = "5002"
      }
    }
  }
  nlb02 = {
    name                             = "nlb02-inbound"
    internal                         = false
    eips                             = false
    enable_cross_zone_load_balancing = true
    apps = {
      app01 = {
        name          = "inbound-nlb02-app1-ssh"
        protocol      = "TCP"
        listener_port = "22"
        target_port   = "5003"
      }
    }
  }
}

// ALBs can be reused for mutltiple inbound apps with differnet listeners for host header or URI path


albs = {
  alb01 = {
    name                        = "alb01-inbound"
    internal                    = false
    http_listener               = true
    http_listener_port          = "80"
    https_listener              = true
    https_listener_port         = "443"
    default_certificate_arn     = "arn:aws:acm:12345"
    additional_certificate_arns = ["arn:aws:acm:12345"]
    security_groups             = ["sg-12345"]
    apps = {
      app01 = {
        name              = "inbound-alb01-app01-http-path"
        listener_protocol = "HTTP"
        target_protocol   = "HTTP"
        target_port       = "6001"
        rule_type         = "path"
        rule_patterns     = ["/foo/*", "/bar/*"]
      }
      app02 = {
        name              = "inbound-alb01-app02-http-host"
        listener_protocol = "HTTP"
        target_protocol   = "HTTP"
        target_port       = "6002"
        rule_type         = "host_header"
        rule_patterns     = ["foo.bar.com", "bar.foo.com"]
      }
      app03 = {
        name              = "inbound-alb01-app03-https-host"
        listener_protocol = "HTTPS"
        target_protocol   = "HTTPS"
        target_port       = "6003"
        rule_type         = "host_header"
        rule_patterns     = ["foo.bar.com", "bar.foo.com"]
      }
      app04 = {
        name              = "inbound-alb01-app03-https-to-http-host"
        listener_protocol = "HTTPS"
        target_protocol   = "HTTP"
        target_port       = "6004"
        rule_type         = "host_header"
        rule_patterns     = ["foo.bar.com", "bar.foo.com"]
      }
    }
  }
}