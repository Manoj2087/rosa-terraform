module "rosa-cluster" {
  source = "./modules/rosa-cluster"
  CLUSTER_PREFIX = "${var.CLUSTER_PREFIX}"
  ROSA_TOKEN = "${var.ROSA_TOKEN}"
  INSTALLER_ROLE_ARN = "${module.role.installer_role_arn}"
  SUPPORT_ROLE_ARN = "${module.role.support_role_arn}"
  CONTROLPLANE_ROLE_ARN = "${module.role.controlplane_role_arn}"
  WORKER_ROLE_ARN = "${module.role.worker_role_arn}"
  ALL_SUBNET_ID = "${join(",", module.network.public_subnet_id)},${join(",", module.network.private_subnet_id)}"
  PRIVATE_SUBNET_ID = "${join(",", module.network.private_subnet_id)}"
  MACHINE_CIDR = "${var.VPC_CIDR}"
  AWS_REGION = "${var.AWS_REGION}"
  PRIVATE_CLUSTER = "${var.PRIVATE_CLUSTER}"
  ENV = "${var.ENV}"
  MULTI_AZ = "${var.MULTI_AZ}"
  /* this variable is only created as dependency to ensure the NATGW 
  and its route are created in the network module before this module starts */
  PRIVATE_NATGW_ROUTE_ID = "${join(",", module.network.private_natgw_route_id)}"

  # depends_on = [
  #   module.role
  # ]
}