module "aws_elbs" {
  source              = "../../load_balancerr"
  global_tags         = var.global_tags
  vpc_id              = var.vpc_id
  elb_subnet_ids      = var.elb_subnet_ids
  target_instance_ids = var.target_instance_ids
  nlbs                = var.nlbs
  albs                = var.albs

}

output "test" {
  value = module.aws_elbs.test
}