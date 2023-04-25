variable "NAME" {
  default = "egress"
}

variable "MULTI_AZ" {
  default = false
}

variable "VPC_CIDR" {
  default = "10.100.0.0/16"
}

variable "TRANSIT_GATEWAY_ASN" {
  default = 64512
}


