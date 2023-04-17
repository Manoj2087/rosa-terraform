output "private_subnet_id" {
  value = "${aws_subnet.private_subnet.*.id}"
}

output "test" {
  value = "${aws_vpc_endpoint.vpc_endpoint_s3.id}"
}