# Create Nat Route Table and its routes
# Associate Route table to Nat subnets
resource "aws_route_table" "nat_subnet_rt" {
  count = "${var.DEPLOY_FIREWALL ? (var.MULTI_AZ ? 3 : 1) : 0}"
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${format("%s-nat-subnet-rt-%s",var.NAME,data.aws_availability_zones.azs.names[count.index])}"
  }
}
#Routes everything external to igw
resource "aws_route" "nat_subnet_rt_route_nat_igw" {
  count = "${var.DEPLOY_FIREWALL ? (var.MULTI_AZ ? 3 : 1) : 0}"
  route_table_id            = aws_route_table.nat_subnet_rt[count.index].id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.igw.id
}
# route everything internal to to Firewall Endpoints
resource "aws_route" "nat_subnet_rt_route_internal_firewallendpoint" {
  count = "${var.DEPLOY_FIREWALL ? (var.MULTI_AZ ? 3 : 1) : 0 }"
  route_table_id            = aws_route_table.nat_subnet_rt[count.index].id
  destination_cidr_block    = var.SPOKE_EGRESS_VPC_CIDR_BLOCKS
  # https://github.com/hashicorp/terraform-provider-aws/issues/16759
  vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.firewall[0].firewall_status[0].sync_states) : 
    ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.fw_subnet[count.index].id], 0)
}
#associate route to nat subnets
resource "aws_route_table_association" "nat_subnet_rt_association" {
  count = "${var.DEPLOY_FIREWALL ? (var.MULTI_AZ ? 3 : 1) : 0 }"
  subnet_id      = aws_subnet.nat_subnet[count.index].id
  route_table_id = aws_route_table.nat_subnet_rt[count.index].id
}

#---------------------------------------------
# Create firewall Route Table and its routes
# Associate firewall Route table to firewall subnets
# Create firewall Route Table
resource "aws_route_table" "fw_subnet_rt" {
  count = "${var.DEPLOY_FIREWALL ? (var.MULTI_AZ ? 3 : 1) : 0}"
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${format("%s-fw-subnet-rt-%s",var.NAME,data.aws_availability_zones.azs.names[count.index])}"
  }
}
# route to NATGW
resource "aws_route" "fw_subnet_rt_route_external_traffic_natgw" {
  count = "${var.DEPLOY_FIREWALL ? (var.MULTI_AZ ? 3 : 1) : 0}"
  route_table_id            = aws_route_table.fw_subnet_rt[count.index].id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = aws_nat_gateway.nat_gw[count.index].id
}
# Internal route back to TGW
resource "aws_route" "fw_subnet_rt_route_internal_traffic_tgw" {
  count = "${var.DEPLOY_FIREWALL ? (var.MULTI_AZ ? 3 : 1) : 0}"
  route_table_id            = aws_route_table.fw_subnet_rt[count.index].id
  destination_cidr_block    = var.SPOKE_EGRESS_VPC_CIDR_BLOCKS
  transit_gateway_id            = aws_ec2_transit_gateway.egress_transit_gateway.id
}
# associate rt to Firewall subnets
resource "aws_route_table_association" "fw_subnet_rt_association" {
  count = "${var.DEPLOY_FIREWALL ? (var.MULTI_AZ ? 3 : 1) : 0}"
  subnet_id      = aws_subnet.fw_subnet[count.index].id
  route_table_id = aws_route_table.fw_subnet_rt[count.index].id
}

#---------------------------------------------
# Create transit gw Route Table and its routes
# Associate transit gw Route table to transit gw subnets
# Associate transit gw  Route table to ptransit gw  subnets
# Create transit gw Route Table
resource "aws_route_table" "tgw_subnet_rt" {
  count = "${var.DEPLOY_FIREWALL ? (var.MULTI_AZ ? 3 : 1) : 0}"
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${format("%s-tgw-subnet-rt-%s",var.NAME,data.aws_availability_zones.azs.names[count.index])}"
  }
}
# route everything from  Transit GW subnet to Firewall Endpoints
resource "aws_route" "tgw_subnet_rt_everything_natgw" {
  count = "${var.DEPLOY_FIREWALL ? (var.MULTI_AZ ? 3 : 1) : 0}"
  route_table_id            = aws_route_table.tgw_subnet_rt[count.index].id
  destination_cidr_block    = "0.0.0.0/0"
  # https://github.com/hashicorp/terraform-provider-aws/issues/16759
  vpc_endpoint_id = element([
    for ss in tolist(aws_networkfirewall_firewall.firewall[0].firewall_status[0].sync_states)
      : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.fw_subnet[count.index].id
    ], 0)
}
# associate rt to Transit GW subnets
resource "aws_route_table_association" "tgw_subnet_rt_association" {
  count = "${var.DEPLOY_FIREWALL ? (var.MULTI_AZ ? 3 : 1) : 0}"
  subnet_id      = aws_subnet.tgw_subnet[count.index].id
  route_table_id = aws_route_table.tgw_subnet_rt[count.index].id
}