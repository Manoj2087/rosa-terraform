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

# Create Nat public subnets
# create 3 subnets over 3 az if multi-ax is true else one subnet on 1 az
resource "aws_subnet" "nat_public_subnet" {
  count = "${var.MULTI_AZ ? 2 : 1}"
  vpc_id     = aws_vpc.vpc.id

  cidr_block = "${cidrsubnet(var.EGRESS_VPC_CIDR, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.azs.names[count.index]}"
  tags = {
    Name = "${format("%s-nat-public-%s",var.NAME,data.aws_availability_zones.azs.names[count.index])}"
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
  subnet_id     = aws_subnet.nat_public_subnet[count.index].id

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
  subnet_ids         = aws_subnet.private_subnet.*.id
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

# Create Nat public Route Table and its routes
# Associate Public Route table to public subnets
resource "aws_route_table" "nat_public_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${format("%s-nat-public",var.NAME)}"
  }
}
#Routes to igw
resource "aws_route" "public_igw" {
  route_table_id            = aws_route_table.nat_public_rt.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.igw.id
}
#Routes to Spoke VPC via Transit GW
resource "aws_route" "spokevpc_tgw" {
  for_each = toset( var.SPOKE_EGRESS_VPC_CIDR_BLOCKS )
  route_table_id            = aws_route_table.nat_public_rt.id
  destination_cidr_block    = each.key
  transit_gateway_id        = aws_ec2_transit_gateway.egress_transit_gateway.id
}
#associate route to public subnets
resource "aws_route_table_association" "public_rt_association" {
  count = "${var.MULTI_AZ ? 2 : 1}"
  subnet_id      = aws_subnet.nat_public_subnet[count.index].id
  route_table_id = aws_route_table.nat_public_rt.id
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


# Create Firewall public subnets if DEPLOY_FIREWALL is true
# create 2 subnets over 2az if multi-ax is true else one subnet on 1 az 
resource "aws_subnet" "firewall_public_subnet" {
  count = "${var.DEPLOY_FIREWALL ? (var.MULTI_AZ ? 2 : 1) : 0 }"
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "${cidrsubnet(var.EGRESS_VPC_CIDR, 8, count.index + 6 )}"
  availability_zone = "${data.aws_availability_zones.azs.names[count.index]}"
  tags = {
    Name = "${format("%s-firewall-public-%s",var.NAME,data.aws_availability_zones.azs.names[count.index])}"
  }
}

resource "aws_networkfirewall_firewall_policy" "firewall_policy" {
  count = "${var.DEPLOY_FIREWALL ? 1 : 0 }"
  name = "${format("%s",var.NAME)}"
  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
  }
}

# Create Network Firewall if DEPLOY_FIREWALL is true
resource "aws_networkfirewall_firewall" "firewall" {
  count = "${var.DEPLOY_FIREWALL ? 1 : 0 }"
  name                = "${format("%s",var.NAME)}"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.firewall_policy[count.index].arn
  vpc_id              = aws_vpc.vpc.id
  dynamic "subnet_mapping" {
    for_each = aws_subnet.firewall_public_subnet[*].id

    content {
      subnet_id = subnet_mapping.value
      ip_address_type = "IPV4"
    }
  }

  tags = {
    Name = "${format("%s",var.NAME)}"
  }
}

# Create cloudwatch log group to store Network firewall alerts if DEPLOY_FIREWALL is true
resource "aws_cloudwatch_log_group" "firewall_alert_log_group" {
  count = "${var.DEPLOY_FIREWALL ? 1 : 0 }"
  name = "${format("/aws/network-firewall/%s/alert",var.NAME)}"
}

# Create bucket to store Network firewall flow logs if DEPLOY_FIREWALL is true
resource "aws_s3_bucket" "firewall_flow_log_bucket" {
  count = "${var.DEPLOY_FIREWALL ? 1 : 0 }"
  bucket_prefix      = "${format("%s-firewall-flowlog-bucket-",var.NAME)}"
  force_destroy = true
}
resource "aws_s3_bucket_server_side_encryption_configuration" "firewall_flow_log_bucket" {
  count = "${var.DEPLOY_FIREWALL ? 1 : 0 }"
  bucket = aws_s3_bucket.firewall_flow_log_bucket[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}
resource "aws_s3_bucket_public_access_block" "firewall_flow_log_bucket" {
  count = "${var.DEPLOY_FIREWALL ? 1 : 0 }"
  bucket = aws_s3_bucket.firewall_flow_log_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Configure Network Firewall logging if DEPLOY_FIREWALL is true
resource "aws_networkfirewall_logging_configuration" "anfw_alert_logging_configuration" {
  count = "${var.DEPLOY_FIREWALL ? 1 : 0 }"
  firewall_arn = aws_networkfirewall_firewall.firewall[0].arn
  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.firewall_alert_log_group[0].name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
    log_destination_config {
      log_destination = {
        bucketName = aws_s3_bucket.firewall_flow_log_bucket[0].bucket
      }
      log_destination_type = "S3"
      log_type             = "FLOW"
    }
  }
}


# pass http $HOME_NET any -> $EXTERNAL_NET 80 (http.host; dotprefix; content:".example.com"; endswith; msg:"Allowed HTTP domain"; priority:1; sid:102120; rev:1;)
# pass http $HOME_NET any -> $EXTERNAL_NET 80 (http.host; dotprefix; content:".mydomain.test"; endswith; msg:"Allowed HTTP domain"; priority:1; sid:102121; rev:1;)
# drop http $HOME_NET any -> $EXTERNAL_NET 80 (msg:"Drop HTTP traffic"; priority:1; sid:102122; rev:1;)
