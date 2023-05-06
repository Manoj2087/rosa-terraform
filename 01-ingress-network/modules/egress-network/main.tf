# fetch the AZvailability Zone
data "aws_availability_zones" "azs" {}

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

# Create public subnets
# create 3 subnets over 3 az if multi-ax is true else one subnet on 1 az
resource "aws_subnet" "public_subnet" {
  count = "${var.MULTI_AZ ? 2 : 1}"
  vpc_id     = aws_vpc.vpc.id

  cidr_block = "${cidrsubnet(var.EGRESS_VPC_CIDR, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.azs.names[count.index]}"
  tags = {
    Name = "${format("%s-public-%s",var.NAME,data.aws_availability_zones.azs.names[count.index])}"
  }
}

# Create private subnets
# create 3 subnets over 3 az if multi-ax is true else one subnet on 1 az
resource "aws_subnet" "private_subnet" {
  count = "${var.MULTI_AZ ? 2 : 1}"
  vpc_id     = aws_vpc.vpc.id

  cidr_block = "${cidrsubnet(var.EGRESS_VPC_CIDR, 8, count.index + 3)}"
  availability_zone = "${data.aws_availability_zones.azs.names[count.index]}"
  tags = {
    Name = "${format("%s-private-%s",var.NAME,data.aws_availability_zones.azs.names[count.index])}"
  }
}

# Create NATGW and its EIP
resource "aws_eip" "nat_gw_eip" {
  count = "${var.MULTI_AZ ? 2 : 1}"
  vpc      = true
  tags = {
    Name = "${format("%s-nat-gw-%d",var.NAME,count.index )}"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  count = "${var.MULTI_AZ ? 2 : 1}"
  allocation_id = aws_eip.nat_gw_eip[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id

  tags = {
    Name = "${format("%s-%s",var.NAME,data.aws_availability_zones.azs.names[count.index])}"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

# Create Transit GW
resource "aws_ec2_transit_gateway" "egress_transit_gateway" {
  amazon_side_asn = var.TRANSIT_GATEWAY_ASN
  auto_accept_shared_attachments = "disable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  description = "Egress Transit Gateway"
  dns_support = "enable"
  multicast_support = "disable"
  vpn_ecmp_support = "enable"

  tags = {
    Name = "${format("%s",var.NAME)}"
  }
}

# Create transit gateway attachment - to Egress vpc private subnet
resource "aws_ec2_transit_gateway_vpc_attachment" "egress_vpc" {
  subnet_ids         = aws_subnet.private_subnet.*.id
  transit_gateway_id = aws_ec2_transit_gateway.egress_transit_gateway.id
  vpc_id             = aws_vpc.vpc.id
  appliance_mode_support = "disable"
  dns_support = "enable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true
  tags = {
    Name = "${format("%s-vpc",var.NAME)}"
  }
}

resource "aws_ec2_transit_gateway_route" "internet_egress" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.egress_vpc.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.egress_transit_gateway.association_default_route_table_id
}

# Create public Route Table and its routes
# Associate Public Route table to public subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${format("%s-public",var.NAME)}"
  }
}
#Routes to igw
resource "aws_route" "public_igw" {
  route_table_id            = aws_route_table.public_rt.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.igw.id
}
#Routes to Spoke VPC via Transit GW
resource "aws_route" "spokevpc_tgw" {
  for_each = toset( var.SPOKE_EGRESS_VPC_CIDR_BLOCKS )
  route_table_id            = aws_route_table.public_rt.id
  destination_cidr_block    = each.key
  transit_gateway_id        = aws_ec2_transit_gateway.egress_transit_gateway.id
}
#associate route to public subnets
resource "aws_route_table_association" "public_rt_association" {
  count = "${var.MULTI_AZ ? 2 : 1}"
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Create Private Route Table and its routes
# Associate Private Route table to Private subnets
# Associate Private Route table to private subnets
# Create private Route Table
resource "aws_route_table" "private_rt" {
  count = "${var.MULTI_AZ ? 2 : 1}"
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${format("%s-private-%s",var.NAME,data.aws_availability_zones.azs.names[count.index])}"
  }
}
# route to NATGW
resource "aws_route" "private_natgw" {
  count = "${var.MULTI_AZ ? 2 : 1}"
  route_table_id            = aws_route_table.private_rt[count.index].id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = aws_nat_gateway.nat_gw[count.index].id
}
# associate private rt to private subnets
resource "aws_route_table_association" "private_rt_association" {
  count = "${var.MULTI_AZ ? 2 : 1}"
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}

