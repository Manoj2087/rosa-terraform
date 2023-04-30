module "egress-network" {
  source = "./modules/egress-network"
  NAME = "${var.NAME}"
  EGRESS_VPC_CIDR = "${var.EGRESS_VPC_CIDR}"
  MULTI_AZ = "${var.MULTI_AZ}"
  TRANSIT_GATEWAY_ASN = "${var.TRANSIT_GATEWAY_ASN}"
  SPOKE_EGRESS_VPC_CIDR_BLOCKS = "${var.SPOKE_EGRESS_VPC_CIDR_BLOCKS}"
  WORKSTATION_VPC_CIDR = "${var.WORKSTATION_VPC_CIDR}"
}