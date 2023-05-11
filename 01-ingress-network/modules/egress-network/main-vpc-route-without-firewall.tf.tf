# Create Nat Route Table and its routes
# Associate Route table to Nat subnets
resource "aws_route_table" "nofw_nat_subnet_rt" {
  count = "${var.DEPLOY_FIREWALL ? 0 : 1 }"
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${format("%s-nat-subnet-rt",var.NAME)}"
  }
}
#Routes to igw
resource "aws_route" "nofw_nat_igw" {
  count = "${var.DEPLOY_FIREWALL ? 0 : 1 }"
  route_table_id            = aws_route_table.nofw_nat_subnet_rt[0].id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.igw.id
}
#Routes to Spoke VPC via Transit GW
resource "aws_route" "nofw_spokevpc_tgw" {
  count = "${var.DEPLOY_FIREWALL ? 0 : 1 }"
  # for_each = toset( var.SPOKE_EGRESS_VPC_CIDR_BLOCKS )
  route_table_id            = aws_route_table.nofw_nat_subnet_rt[0].id
  destination_cidr_block    = var.SPOKE_EGRESS_VPC_CIDR_BLOCKS
  transit_gateway_id        = aws_ec2_transit_gateway.egress_transit_gateway.id
}
#associate route to nat subnets
resource "aws_route_table_association" "nofw_nat_subnet_rt_association" {
  count = "${var.DEPLOY_FIREWALL ? 0 : (var.MULTI_AZ ? 3 : 1) }"
  subnet_id      = aws_subnet.nat_subnet[count.index].id
  route_table_id = aws_route_table.nofw_nat_subnet_rt[0].id
}

# Create transit gw Route Table and its routes
# Associate transit gw Route table to transit gw subnets
# Associate transit gw  Route table to ptransit gw  subnets
# Create transit gw Route Table
resource "aws_route_table" "nofw_tgw_subnet_rt" {
  count = "${var.DEPLOY_FIREWALL ? 0 : (var.MULTI_AZ ? 3 : 1) }"
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${format("%s-tgw-subnet-rt-%s",var.NAME,data.aws_availability_zones.azs.names[count.index])}"
  }
}
# route to NATGW
resource "aws_route" "nofw_private_natgw" {
  count = "${var.DEPLOY_FIREWALL ? 0 : (var.MULTI_AZ ? 3 : 1) }"
  route_table_id            = aws_route_table.nofw_tgw_subnet_rt[count.index].id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = aws_nat_gateway.nat_gw[count.index].id
}
# associate private rt to private subnets
resource "aws_route_table_association" "nofw_tgw_subnet_rt_association" {
  count = "${var.DEPLOY_FIREWALL ? 0 : (var.MULTI_AZ ? 3 : 1) }"
  subnet_id      = aws_subnet.tgw_subnet[count.index].id
  route_table_id = aws_route_table.tgw_subnet_rt[count.index].id
}
