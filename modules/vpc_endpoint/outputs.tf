output "endpoint" {
  description = "The created `aws_vpc_endpoint` object. Alternatively, the data resource if the input `create` is false."
  value       = local.vpc_endpoint
}
