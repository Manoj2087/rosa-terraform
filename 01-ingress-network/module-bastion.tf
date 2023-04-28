module "bastion" {
  source = "./modules/bastion"
  LINUX_BASTION_CONFIG = "${var.LINUX_BASTION_CONFIG}"
  WINDOWS_BASTION_CONFIG = "${var.WINDOWS_BASTION_CONFIG}"
  SUBNET_ID = "${module.egress-network.private_subnet_id}"
}