module "egress-network" {
  source = "./modules/egress-network"
  NAME = "${var.NAME}"
  VPC_CIDR = "${var.VPC_CIDR}"
  MULTI_AZ = "${var.MULTI_AZ}"
  TRANSIT_GATEWAY_ASN = "${var.TRANSIT_GATEWAY_ASN}"
}