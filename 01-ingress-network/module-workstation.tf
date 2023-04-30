module "workstation-network" {
  source = "./modules/workstation-network"
  LINUX_WORKSTATION_CONFIG = "${var.LINUX_WORKSTATION_CONFIG}"
  WINDOWS_WORKSTATION_CONFIG = "${var.WINDOWS_WORKSTATION_CONFIG}"
  WORKSTATION_VPC_CIDR = "${var.WORKSTATION_VPC_CIDR}"
  NAME = "${var.WORKSTATION_NAME}"
  MULTI_AZ = "${var.MULTI_AZ}"
  TRANSIT_GATEWAY_ID = "${module.egress-network.transit_gateway_id}"
}