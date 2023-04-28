output "transit_gateway_id" {
  value = "${aws_ec2_transit_gateway.egress_transit_gateway.id}"
}

output "private_subnet_id" {
  value = "${aws_subnet.private_subnet.*.id}"
}