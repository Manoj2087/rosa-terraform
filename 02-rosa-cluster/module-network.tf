module "network" {
  source = "./modules/network"
  CLUSTER_PREFIX = "${var.CLUSTER_PREFIX}"
  VPC_CIDR = "${var.VPC_CIDR}"
  MULTI_AZ = "${var.MULTI_AZ}"
  ENV = "${var.ENV}"
  AWS_REGION = "${data.aws_region.current_region.name}"
  AWS_REGION_SHORT = "${var.AWS_REGION_SHORT[data.aws_region.current_region.name]}"
}