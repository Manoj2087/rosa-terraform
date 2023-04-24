output "private_subnet_id" {
  value = "${aws_subnet.private_subnet.*.id}"
}

output "public_subnet_id" {
  value = "${aws_subnet.public_subnet.*.id}"
}

output "private_natgw_route_id" {
  value = "${aws_route.private_natgw.*.id}"
}