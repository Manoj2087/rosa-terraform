variable "ENV" {
  type = string
  default = "prd"
  validation {
    condition     = contains(["dev", "prd"], var.ENV) && length(var.ENV) < 4
    error_message = "Valid values for var: ENV are (dev - Development , prd - Production). And max 3 characters"
  } 
}

# variable "AWS_REGION" {
#   type = string
#   default = "ap-southeast-2"
#   validation {
#     condition     = contains(["ap-northeast-1","ap-northeast-2","ap-northeast-3","ap-south-1","ap-southeast-1","ap-southeast-2","ca-central-1","eu-central-1","eu-north-1","eu-west-1","eu-west-2","eu-west-3","sa-east-1","us-east-1","us-east-2","us-west-2"], var.AWS_REGION)
#     error_message = "Valid values for var: ENV are (ap-northeast-1,ap-northeast-2,ap-northeast-3,ap-south-1,ap-southeast-1,ap-southeast-2,ca-central-1,eu-central-1,eu-north-1,eu-west-1,eu-west-2,eu-west-3,sa-east-1,us-east-1,us-east-2,us-west-2)."
#   } 
# }

variable "AWS_REGION_SHORT" {
  type = map
  default = {
    ap-northeast-1 = "apne1"
    ap-northeast-2 = "apne2"
    ap-northeast-3 = "apne3"
    ap-south-1 = "aps1"
    ap-southeast-1 = "apse1"
    ap-southeast-2 = "apse2"
    ca-central-1 = "cac1"
    eu-central-1 = "euc1"
    eu-north-1 = "eun1"
    eu-west-1 = "euw1"
    eu-west-2 = "euw2"
    eu-west-3 = "euw3"
    sa-east-1 = "sae1"
    us-east-1 = "use1"
    us-east-2 = "use2"
    us-west-2 = "usw2"
  }
}

variable "CLUSTER_PREFIX" {
  type = string
  default = "rosa"
  validation {
    condition     = length(var.CLUSTER_PREFIX) < 6
    error_message = "And max 5 characters"
  } 
}

variable "VPC_CIDR" {
  type = map
  default = {
    dev = "10.0.0.0/16"
    prd = "10.1.0.0/16"
  }
}


variable "MULTI_AZ" {
  type = map
  default = {
    dev = false
    prd = true
  }
}

variable "PRIVATE_CLUSTER" {
  type = bool
  default = false
}

variable "ROSA_TOKEN" {
  type = string
  sensitive = true
}

variable "OCP_VERSION" {
  default = "4.12.12"
}

variable "WORKER_MACHINE_TYPE" {
  type = map
  default = {
    dev = "t3a.xlarge"
    prd = "m5.xlarge"
  }
}

variable "WORKER_MACHINE_REPLICA" {
  type = map
  default = {
    dev = 2
    prd = 3
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

variable "TRANSIT_GATEWAY_USED" {
  type = bool
  default = false
}

variable "TRANSIT_GATEWAY_ID" {
  default = "tgw-xxxxxxxxxxxxxxxxx"
}