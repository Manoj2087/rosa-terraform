variable "NAME" {
  default = "rosa-egress"
}

variable "MULTI_AZ" {
  type = bool
  default = true
}

variable "DEPLOY_FIREWALL" {
  type = bool
  default = true
}

variable "EGRESS_VPC_CIDR" {
  default = "172.31.0.0/16"
}

variable "TRANSIT_GATEWAY_ASN" {
  default = 64512
}

#Add the CIDR Range block for each VPC Part of the Transit gateway spoke
# This required for the return trffic from the internet GW back to the respective vpc
variable "SPOKE_EGRESS_VPC_CIDR_BLOCKS" {
  default = "10.0.0.0/8"
}



