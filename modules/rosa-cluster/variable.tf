variable "CLUSTER_PREFIX" {}
variable "ROSA_TOKEN" {}
variable "INSTALLER_ROLE_ARN" {}
variable "SUPPORT_ROLE_ARN" {}
variable "CONTROLPLANE_ROLE_ARN" {}
variable "WORKER_ROLE_ARN" {}
variable "ALL_SUBNET_ID" {}
variable "PRIVATE_SUBNET_ID" {}
variable "MACHINE_CIDR" {}
variable "AWS_REGION" {}
variable "PRIVATE_CLUSTER" {}
variable "ENV" {}
variable "MULTI_AZ" {}
/* this variable is only created as dependency to ensure the NATGW 
and its route are created in the network module before this module starts */
variable "PRIVATE_NATGW_ROUTE_ID" {}

variable "OCP_VERSION" {
  default = "4.12.12"
}

variable "WORKER_MACHINE_TYPE" {
  type = map
  default = {
    dev = "t3a.xlarge"
    prod = "m5.xlarge"
  }
}

variable "WORKER_MACHINE_REPLICA" {
  type = map
  default = {
    dev = 2
    prod = 3
  }
}

variable "SERVICE_CIDR" {
  default = "172.30.0.0/16"
}

variable "POD_CIDR" {
  default = "10.128.0.0/14"
}

variable "HOST_PREFIX" {
  default = 23
}