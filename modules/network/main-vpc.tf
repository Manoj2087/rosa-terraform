# fetch the AZvailability Zone
data "aws_availability_zones" "azs" {}

data "aws_region" "current_region" {}

data "aws_ec2_managed_prefix_list" "managed_prefix_list_s3" {
  name = "${format("com.amazonaws.%s.s3",data.aws_region.current_region.name)}"
}

# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block       = var.VPC_CIDR
  instance_tenancy = "default"
	enable_dns_support = "true"
	enable_dns_hostnames = "true"

  tags = {
    Name = "${format("%s-vpc",var.CLUSTER_PREFIX)}"
  }
}

# Create internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${format("%s-igw",var.CLUSTER_PREFIX)}"
  }
}

# Create public subnets
# create 3 subnets over 3 az if multi-ax is true else one subnet on 1 az
resource "aws_subnet" "public_subnet" {
  count = "${var.MULTI_AZ ? 3 : 1}"
  vpc_id     = aws_vpc.vpc.id

  cidr_block = "${cidrsubnet(var.VPC_CIDR, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.azs.names[count.index]}"
  tags = {
    Name = "${format("%s-public-subnet-%s",var.CLUSTER_PREFIX, data.aws_availability_zones.azs.names[count.index])}"
  }
}

# Create private subnets
# create 3 subnets over 3 az if multi-ax is true else one subnet on 1 az
resource "aws_subnet" "private_subnet" {
  count = "${var.MULTI_AZ ? 3 : 1}"
  vpc_id     = aws_vpc.vpc.id

  cidr_block = "${cidrsubnet(var.VPC_CIDR, 8, count.index + 3)}"
  availability_zone = "${data.aws_availability_zones.azs.names[count.index]}"
  tags = {
    Name = "${format("%s-private-subnet-%s",var.CLUSTER_PREFIX, data.aws_availability_zones.azs.names[count.index])}"
  }
}

# Create NATGW and its EIP
resource "aws_eip" "nat_gw_eip" {
  vpc      = true
  tags = {
    Name = "${format("%s-nat-gw-eip",var.CLUSTER_PREFIX)}"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gw_eip.id
  subnet_id     = aws_subnet.private_subnet[0].id

  tags = {
    Name = "${format("%s-nat-gw",var.CLUSTER_PREFIX)}"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

# Create VPC Enpoint for S3
resource "aws_vpc_endpoint" "vpc_endpoint_s3" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "${format("com.amazonaws.%s.s3",data.aws_region.current_region.name)}"
  vpc_endpoint_type = "Gateway"
  tags = {
    Name = "${format("%s-vpc-endpoint-s3",var.CLUSTER_PREFIX)}"
  }
}

# Create public Route Table and its routes
# Associate Public Route table to public subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${format("%s-public-rt",var.CLUSTER_PREFIX)}"
  }
}
#Routes to igw
resource "aws_route" "public_igw" {
  route_table_id            = aws_route_table.public_rt.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.igw.id
}
#route to vpc s3 endpoint
resource "aws_vpc_endpoint_route_table_association" "public_private_endpoint_s3" {
  route_table_id  = aws_route_table.public_rt.id
  vpc_endpoint_id = aws_vpc_endpoint.vpc_endpoint_s3.id
}
#associate route to public subnets
resource "aws_route_table_association" "public_rt_association" {
  count = "${var.MULTI_AZ ? 3 : 1}"
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Create Private Route Table and its routes
# Associate Private Route table to Private subnets
# Associate Private Route table to private subnets
# Create private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${format("%s-private-rt",var.CLUSTER_PREFIX)}"
  }
}
# route to NATGW
resource "aws_route" "private_natgw" {
  route_table_id            = aws_route_table.private_rt.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = aws_nat_gateway.nat_gw.id
}
# route to S3 private endpoint
resource "aws_vpc_endpoint_route_table_association" "private_private_endpoint_s3" {
  route_table_id  = aws_route_table.private_rt.id
  vpc_endpoint_id = aws_vpc_endpoint.vpc_endpoint_s3.id
}
# associate private rt to private subnets
resource "aws_route_table_association" "private_rt_association" {
  count = "${var.MULTI_AZ ? 3 : 1}"
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt.id
}