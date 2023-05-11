# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block       = var.EGRESS_VPC_CIDR
  instance_tenancy = "default"
	enable_dns_support = "true"
	enable_dns_hostnames = "true"

  tags = {
    Name = "${format("%s",var.NAME)}"
  }
}

# Create internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${format("%s",var.NAME)}"
  }
}
