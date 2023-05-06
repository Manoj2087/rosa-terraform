variable "NAME" {
  default = "egress"
}

variable "MULTI_AZ" {
  default = false
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
  type = list
  default = [
    "10.0.0.0/8",
  ]
}



