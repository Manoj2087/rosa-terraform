# Create Transit GW
resource "aws_ec2_transit_gateway" "egress_transit_gateway" {
  amazon_side_asn = var.TRANSIT_GATEWAY_ASN
  auto_accept_shared_attachments = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  description = "Egress Transit Gateway"
  dns_support = "enable"
  multicast_support = "disable"
  vpn_ecmp_support = "enable"

  tags = {
    Name = "${format("%s",var.NAME)}"
  }
}

# Create Egress Route Table
resource "aws_ec2_transit_gateway_route_table" "egress_route_table" {
  transit_gateway_id = aws_ec2_transit_gateway.egress_transit_gateway.id

  tags = {
    Name = "${format("%s-egress-route-table",var.NAME)}"
    #the below 2 tags are used in the spoke VPC creation do not delete or alter
    spoke-terraform-lookup = "true"
    type = "egress"
  }
}

# Create transit gateway attachment - to Egress vpc private subnet
# enable Appliance node
resource "aws_ec2_transit_gateway_vpc_attachment" "egress_vpc_attachment" {
  subnet_ids         = aws_subnet.tgw_subnet.*.id
  transit_gateway_id = aws_ec2_transit_gateway.egress_transit_gateway.id
  vpc_id             = aws_vpc.vpc.id
  appliance_mode_support = "enable"
  dns_support = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name = "${format("%s-vpc-attachment",var.NAME)}"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "egress_vpc_tgw_rt_association" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.egress_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress_route_table.id
}

# Create Spoke Route Table
resource "aws_ec2_transit_gateway_route_table" "spoke_route_table" {
  transit_gateway_id = aws_ec2_transit_gateway.egress_transit_gateway.id

  tags = {
    Name = "${format("%s-spoke-route-table",var.NAME)}"
    #the below 2 tags are used in the spoke VPC creation do not delete or alter
    spoke-terraform-lookup = "true"
    type = "spoke"
  }
}

resource "aws_ec2_transit_gateway_route" "spoke_route_table_default_route" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.egress_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_route_table.id
}