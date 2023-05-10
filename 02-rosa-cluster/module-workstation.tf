module "workstation" {
  count = "${var.DEPLOY_WORKSTATION ? 1 : 0}"
  source = "./modules/workstation"
  NAME = "${format("%s-%s-%s-workstation",var.CLUSTER_PREFIX,var.ENV,var.AWS_REGION_SHORT[data.aws_region.current_region.name])}"
  LINUX_WORKSTATION_CONFIG = "${var.LINUX_WORKSTATION_CONFIG}"
  WINDOWS_WORKSTATION_CONFIG = "${var.WINDOWS_WORKSTATION_CONFIG}"
  PRIVATE_SUBNET = "${module.network.private_subnet_id}"
  AWS_REGION = "${data.aws_region.current_region.name}"
  VPC_ID =  "${module.network.vpc_id}"
}