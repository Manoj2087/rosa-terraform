module "rosa-role" {
  source = "./modules/rosa-role"
  CLUSTER_PREFIX = "${var.CLUSTER_PREFIX}"
  ENV = "${var.ENV}"
  AWS_REGION = "${data.aws_region.current_region.name}"
  AWS_REGION_SHORT = "${var.AWS_REGION_SHORT[data.aws_region.current_region.name]}"
}