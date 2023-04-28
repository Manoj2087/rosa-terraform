module "workstation-network" {
  source = "./modules/workstation-network"
  LINUX_WORKSTATION_CONFIG = "${var.LINUX_WORKSTATION_CONFIG}"
  WINDOWS_WORKSTATION_CONFIG = "${var.WINDOWS_WORKSTATION_CONFIG}"
  SUBNET_ID = "${module.egress-network.private_subnet_id}"
}