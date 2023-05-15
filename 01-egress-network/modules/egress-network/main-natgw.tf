# Create NATGW and its EIP
resource "aws_eip" "nat_gw_eip" {
  count = "${var.MULTI_AZ ? 3 : 1}"
  vpc      = true
  tags = {
    Name = "${format("%s-nat-gw-%d",var.NAME,count.index )}"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  count = "${var.MULTI_AZ ? 3 : 1}"
  allocation_id = aws_eip.nat_gw_eip[count.index].id
  subnet_id     = aws_subnet.nat_subnet[count.index].id

  tags = {
    Name = "${format("%s-%s",var.NAME,data.aws_availability_zones.azs.names[count.index])}"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}