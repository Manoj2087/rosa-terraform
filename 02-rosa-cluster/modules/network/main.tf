# fetch the AZvailability Zone
data "aws_availability_zones" "azs" {}

# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block       = var.VPC_CIDR
  instance_tenancy = "default"
	enable_dns_support = "true"
	enable_dns_hostnames = "true"

  tags = {
    Name = "${format("%s-%s-%s",var.CLUSTER_PREFIX,var.ENV,var.AWS_REGION_SHORT)}"
  }
}

# Create internet Gateway
# Skip if Transit gateway is used for egress VPC
resource "aws_internet_gateway" "igw" {
  count = "${var.TRANSIT_GATEWAY_USED ? 0 : 1}"
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${format("%s-%s-%s",var.CLUSTER_PREFIX,var.ENV,var.AWS_REGION_SHORT)}"
  }
}

# Create public subnets
# create 3 subnets over 3 az if multi-ax is true else one subnet on 1 az
# Skip if Transit gateway is used for egress VPC
resource "aws_subnet" "public_subnet" {
  count = "${var.TRANSIT_GATEWAY_USED ?  0 : (var.MULTI_AZ ? 3 : 1)}"
  vpc_id     = aws_vpc.vpc.id

  cidr_block = "${cidrsubnet(var.VPC_CIDR, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.azs.names[count.index]}"
  tags = {
    Name = "${format("%s-%s-%s-public-%s",var.CLUSTER_PREFIX,var.ENV,var.AWS_REGION_SHORT,data.aws_availability_zones.azs.names[count.index])}"
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
    Name = "${format("%s-%s-%s-private-%s",var.CLUSTER_PREFIX,var.ENV,var.AWS_REGION_SHORT,data.aws_availability_zones.azs.names[count.index])}"
  }
}

# Create NATGW and its EIP
# Skip if Transit gateway is used for egress VPC
resource "aws_eip" "nat_gw_eip" {
  count = "${var.TRANSIT_GATEWAY_USED ?  0 : (var.MULTI_AZ ? 3 : 1)}"
  vpc      = true
  tags = {
    Name = "${format("%s-%s-%s-nat-gw-%d",var.CLUSTER_PREFIX,var.ENV,var.AWS_REGION_SHORT,count.index )}"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  count = "${var.TRANSIT_GATEWAY_USED ?  0 : (var.MULTI_AZ ? 3 : 1)}"
  allocation_id = aws_eip.nat_gw_eip[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id

  tags = {
    Name = "${format("%s-%s-%s-%s",var.CLUSTER_PREFIX,var.ENV,var.AWS_REGION_SHORT,data.aws_availability_zones.azs.names[count.index])}"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

# Create VPC Enpoint for S3
resource "aws_vpc_endpoint" "vpc_endpoint_s3" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "${format("com.amazonaws.%s.s3",var.AWS_REGION)}"
  vpc_endpoint_type = "Gateway"
  tags = {
    Name = "${format("%s-%s-%s-s3",var.CLUSTER_PREFIX,var.ENV,var.AWS_REGION_SHORT)}"
  }
}

# Create public Route Table and its routes
# Associate Public Route table to public subnets
# Skip if Transit gateway is used for egress VPC
resource "aws_route_table" "public_rt" {
  count = "${var.TRANSIT_GATEWAY_USED ?  0 : 1}"
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${format("%s-%s-%s-public",var.CLUSTER_PREFIX,var.ENV,var.AWS_REGION_SHORT)}"
  }
}
#Routes to igw
resource "aws_route" "public_igw" {
  count = "${var.TRANSIT_GATEWAY_USED ? 0 : 1}"
  route_table_id            = aws_route_table.public_rt[count.index].id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.igw[count.index].id
}
#route to vpc s3 endpoint
resource "aws_vpc_endpoint_route_table_association" "public_private_endpoint_s3" {
  count = "${var.TRANSIT_GATEWAY_USED ? 0 : 1}"
  route_table_id  = aws_route_table.public_rt[count.index].id
  vpc_endpoint_id = aws_vpc_endpoint.vpc_endpoint_s3.id
}
#associate route to public subnets
resource "aws_route_table_association" "public_rt_association" {
  count = "${var.TRANSIT_GATEWAY_USED ?  0 : (var.MULTI_AZ ? 3 : 1)}"
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt[0].id
}

# Create Private Route Table and its routes
# Associate Private Route table to Private subnets
# Associate Private Route table to private subnets
# Create private Route Table
resource "aws_route_table" "private_rt" {
  count = "${var.MULTI_AZ ? 3 : 1}"
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${format("%s-%s-%s-private-%s",var.CLUSTER_PREFIX,var.ENV,var.AWS_REGION_SHORT,data.aws_availability_zones.azs.names[count.index])}"
  }
}
# route to NATGW - Skip if Transit gateway is used for egress VPC
resource "aws_route" "private_natgw" {
  count = "${var.TRANSIT_GATEWAY_USED ?  0 : (var.MULTI_AZ ? 3 : 1)}"
  route_table_id            = aws_route_table.private_rt[count.index].id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = aws_nat_gateway.nat_gw[count.index].id
}
# route Transit GW - only if Transit gateway is used for egress VPC
resource "aws_route" "private_transitgw" {
  count = "${var.TRANSIT_GATEWAY_USED ?  (var.MULTI_AZ ? 3 : 1) : 0}"
  route_table_id            = aws_route_table.private_rt[count.index].id
  destination_cidr_block    = "0.0.0.0/0"
  transit_gateway_id        =  var.TRANSIT_GATEWAY_ID
}
# route to S3 private endpoint
resource "aws_vpc_endpoint_route_table_association" "private_private_endpoint_s3" {
  count = "${var.MULTI_AZ ? 3 : 1}"
  route_table_id  = aws_route_table.private_rt[count.index].id
  vpc_endpoint_id = aws_vpc_endpoint.vpc_endpoint_s3.id
}
# associate private rt to private subnets
resource "aws_route_table_association" "private_rt_association" {
  count = "${var.MULTI_AZ ? 3 : 1}"
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}

# Create transit gateway attachment - to vpc private subnet - only if Transit gateway is used for egress VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc" {
  count = "${var.TRANSIT_GATEWAY_USED ? 1 : 0}"
  subnet_ids         = aws_subnet.private_subnet.*.id
  transit_gateway_id = var.TRANSIT_GATEWAY_ID
  vpc_id             = aws_vpc.vpc.id
  appliance_mode_support = "disable"
  dns_support = "enable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true
  tags = {
    Name = "${format("%s-%s-%s-vpc",var.CLUSTER_PREFIX,var.ENV,var.AWS_REGION_SHORT)}"
  }
}