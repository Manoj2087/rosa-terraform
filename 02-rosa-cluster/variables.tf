variable "ROSA_TOKEN" {
  type = string
  sensitive = true
}

variable "ENV" {
  type = string
  default = "tst"
  validation {
    condition     = contains(["tst","dev", "prd"], var.ENV) && length(var.ENV) < 4
    error_message = "Valid values for var: ENV are (tst - Test, dev - Development , prd - Production). And max 3 characters"
  } 
}

variable "MULTI_AZ" {
  type = bool
}

variable "PRIVATE_CLUSTER" {
  type = bool
}

variable "DEPLOY_WORKSTATION" {
  type = bool
  default = false
}

variable "TRANSIT_GATEWAY_USED" {
  type = bool
}

variable "TRANSIT_GATEWAY_ID" {
  type = string
  default = ""
}

variable "CLUSTER_PREFIX" {
  type = string
  default = "rosa"
  validation {
    condition     = length(var.CLUSTER_PREFIX) < 6
    error_message = "And max 5 characters"
  } 
}

# List of supported regions
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

/*
Start of ROSA Cluster Speicific variables
*/
variable "VPC_CIDR" {
  default = "10.0.0.0/16"
}

variable "OCP_VERSION" {
  default = "4.12.12"
}

variable "WORKER_MACHINE_TYPE" {
  default = "t3a.xlarge"
}

variable "WORKER_MACHINE_REPLICA" {
  default = 2
  validation {
    condition     = var.WORKER_MACHINE_REPLICA > 1
    error_message = "Min 2 for Single AZ or Min 3 for Multi AZ cluster"
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
/*
End of ROSA Cluster Speicific variables
*/

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


