module "network" {
  source = "./modules/network"
  CLUSTER_PREFIX = "${var.CLUSTER_PREFIX}"
  VPC_CIDR = "${var.VPC_CIDR}"
  MULTI_AZ = "${var.MULTI_AZ}"
}