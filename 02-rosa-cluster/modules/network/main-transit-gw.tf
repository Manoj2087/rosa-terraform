# Other VPC CIDR to add to route via Transit GW
resource "aws_route" "transit_gw_route_1" {
  count = "${var.TRANSIT_GATEWAY_USED ?  (var.MULTI_AZ ? 3 : 1) : 0}"
  route_table_id            = aws_route_table.private_rt[count.index].id
  destination_cidr_block    = "10.1.0.0/16"
  nat_gateway_id            =  var.TRANSIT_GATEWAY_ID
}
resource "aws_route" "transit_gw_route_egress" {
  count = "${var.TRANSIT_GATEWAY_USED ?  (var.MULTI_AZ ? 3 : 1) : 0}"
  route_table_id            = aws_route_table.private_rt[count.index].id
  destination_cidr_block    = "10.100.0.0/16"
  nat_gateway_id            =  var.TRANSIT_GATEWAY_ID
}