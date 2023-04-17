module "role" {
  source = "./modules/rosa-role"
  CLUSTER_PREFIX = "${var.CLUSTER_PREFIX}"
}