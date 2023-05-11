# Create Nat subnets
# create 3 subnets over 3 az if multi-ax is true else one subnet on 1 az
resource "aws_subnet" "nat_subnet" {
  count = "${var.MULTI_AZ ? 3 : 1}"
  vpc_id     = aws_vpc.vpc.id

  cidr_block = "${cidrsubnet(var.EGRESS_VPC_CIDR, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.azs.names[count.index]}"
  tags = {
    Name = "${format("%s-nat-subnet-%s",var.NAME,data.aws_availability_zones.azs.names[count.index])}"
  }
}

# Create Firewall subnets if DEPLOY_FIREWALL is true
# create 2 subnets over 2az if multi-ax is true else one subnet on 1 az 
resource "aws_subnet" "fw_subnet" {
  count = "${var.DEPLOY_FIREWALL ? (var.MULTI_AZ ? 3 : 1) : 0 }"
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "${cidrsubnet(var.EGRESS_VPC_CIDR, 8, count.index + 6 )}"
  availability_zone = "${data.aws_availability_zones.azs.names[count.index]}"
  tags = {
    Name = "${format("%s-firewall-subnet-%s",var.NAME,data.aws_availability_zones.azs.names[count.index])}"
  }
}

# Create TGW subnets
# create 3 subnets over 3 az if multi-ax is true else one subnet on 1 az
resource "aws_subnet" "tgw_subnet" {
  count = "${var.MULTI_AZ ? 3 : 1}"
  vpc_id     = aws_vpc.vpc.id

  cidr_block = "${cidrsubnet(var.EGRESS_VPC_CIDR, 8, count.index + 3)}"
  availability_zone = "${data.aws_availability_zones.azs.names[count.index]}"
  tags = {
    Name = "${format("%s-tgw-subnet-%s",var.NAME,data.aws_availability_zones.azs.names[count.index])}"
  }
}
