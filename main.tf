locals {
  available_zones_count = length(data.aws_availability_zones.available.names)
  zone_count            = var.zone_count < local.available_zones_count ? var.zone_count : local.available_zones_count

  azs             = slice(data.aws_availability_zones.available.names, 0, local.zone_count)
  private_subnets = [for k, v in local.azs : cidrsubnet(var.cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.cidr, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(var.cidr, 8, k + 52)]
}

module "vpc" {
  source                               = "terraform-aws-modules/vpc/aws"
  name                                 = "${var.stack}-vpc"
  version                              = "5.17.0"
  cidr                                 = var.cidr
  azs                                  = slice(data.aws_availability_zones.available.names, 0, local.zone_count)
  private_subnets                      = local.private_subnets
  public_subnets                       = local.public_subnets
  intra_subnets                        = local.intra_subnets
  enable_nat_gateway                   = true
  enable_dns_hostnames                 = true
  enable_flow_log                      = true
  manage_default_network_acl           = false
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true
  tags                                 = var.tags
  public_subnet_tags = merge(
    { type = "public" },
    var.tags
  )
  private_subnet_tags = merge(
    { type = "private" },
    var.tags
  )
  intra_subnet_tags = merge(
    { type = "intra" },
    var.tags
  )
}
