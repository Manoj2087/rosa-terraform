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

variable "SPOKE_EGRESS_VPC_CIDR_BLOCKS" {
  type = list
  default = [
    "10.0.0.0/16",
    "10.1.0.0/16"
  ]
}


variable "LINUX_WORKSTATION_CONFIG" {
  type = map
  default = {
    count = 1,
    instance_type = "t3a.micro",
    volume_type = "gp3",
    volume_size = 50,
  }
}

variable "WINDOWS_WORKSTATION_CONFIG" {
  type = map
  default = {
    count = 1,
    instance_type = "t3.large",
    volume_type = "gp3",
    volume_size = 200,
  }
}


