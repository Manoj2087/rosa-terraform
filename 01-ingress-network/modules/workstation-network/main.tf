# workstation Network
# fetch the AZvailability Zone
data "aws_availability_zones" "azs" {}

data "aws_region" "current_region" {}

# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block       = var.WORKSTATION_VPC_CIDR
  instance_tenancy = "default"
	enable_dns_support = "true"
	enable_dns_hostnames = "true"

  tags = {
    Name = "${format("%s",var.NAME)}"
  }
}

# Create private subnets
# create 2 private subnets over 2 az if multi-az is true else one subnet on 1 az
resource "aws_subnet" "private_subnet" {
  count = "${var.MULTI_AZ ? 2 : 1}"
  vpc_id     = aws_vpc.vpc.id

  cidr_block = "${cidrsubnet(var.WORKSTATION_VPC_CIDR, 8, count.index + 3)}"
  availability_zone = "${data.aws_availability_zones.azs.names[count.index]}"
  tags = {
    Name = "${format("%s-private-%s",var.NAME,data.aws_availability_zones.azs.names[count.index])}"
  }
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
# route all traffic via Transit GW to  egress VPC
resource "aws_route" "private_transitgw" {
  count = "${var.MULTI_AZ ? 2 : 1}"
  route_table_id            = aws_route_table.private_rt[count.index].id
  destination_cidr_block    = "0.0.0.0/0"
  transit_gateway_id        =  var.TRANSIT_GATEWAY_ID
}
# associate private rt to private subnets
resource "aws_route_table_association" "private_rt_association" {
  count = "${var.MULTI_AZ ? 2 : 1}"
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}

# Create transit gateway attachment - to vpc private subnet
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc" {
  subnet_ids         = aws_subnet.private_subnet.*.id
  transit_gateway_id = var.TRANSIT_GATEWAY_ID
  vpc_id             = aws_vpc.vpc.id
  appliance_mode_support = "disable"
  dns_support = "enable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true
  tags = {
    Name = "${format("%s-vpc",var.NAME)}"
  }
}


# Lookup Amazon Linux 2 ami
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

#Create IAM Instance Profile for the workstation instance
resource "aws_iam_role" "linux_workstation_instance" {
  name_prefix = "linux-workstation-instance-"
  assume_role_policy = jsonencode(
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
  )
  tags = {
    name = "linux-workstation-instance"
  }
}
resource "aws_iam_role_policy_attachment" "linux_workstation_instance" {
  role       = aws_iam_role.linux_workstation_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "linux_workstation_instance" {
	name_prefix = "linux-workstation-instance-"
	role = "${aws_iam_role.linux_workstation_instance.name}"
}

resource "aws_instance" "linux-workstation" {
	count = "${lookup(var.LINUX_WORKSTATION_CONFIG, "count")}"
	ami = "${data.aws_ami.amazon-linux-2.id}"
	instance_type = "${lookup(var.LINUX_WORKSTATION_CONFIG, "instance_type")}"
	user_data = templatefile("${path.module}/templates/linux-workstation-init.tftpl", {
    hostnames   = format("linux-workstation-%d",count.index + 1)
  })
	iam_instance_profile = "${aws_iam_instance_profile.linux_workstation_instance.name}"
  subnet_id = "${aws_subnet.private_subnet[count.index].id}"
	tags = {
		Name = "${format("linux-workstation-%d",count.index + 1)}"
	}
	volume_tags = {
		Name = "${format("linux-workstation-%d",count.index + 1)}"
	}
	root_block_device {
		volume_type = "${lookup(var.LINUX_WORKSTATION_CONFIG, "volume_type")}"
		volume_size = "${lookup(var.LINUX_WORKSTATION_CONFIG, "volume_size")}"
	}
}


#Lookup windows ami
data "aws_ami" "windows-server-2022" {
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
}

#Create secret for windows-workstation 'rdp-user' password
data "aws_secretsmanager_random_password" "windows-workstation-rdp-user" {
  password_length = 20
  exclude_numbers = true
}
resource "aws_secretsmanager_secret" "windows-workstation-rdp-user" {
  name_prefix                = "windows-workstation-rdp-user-"
}
resource "aws_secretsmanager_secret_version" "windows-workstation-rdp-user" {
  secret_id = aws_secretsmanager_secret.windows-workstation-rdp-user.id
  secret_string = <<EOF
{
"username":"rdp-user",
"password":"${data.aws_secretsmanager_random_password.windows-workstation-rdp-user.random_password}"
}
EOF
	lifecycle {
		ignore_changes = [secret_string]
	}
}

#Create IAM Instance Profile for the Windows workstation instance
resource "aws_iam_role" "windows_workstation_instance" {
  name_prefix = "windows-workstation-instance-"
  assume_role_policy = jsonencode(
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
  )
  tags = {
    name = "windows-workstation-instance"
  }
}
resource "aws_iam_policy" "windows_workstation_secrets" {
  name_prefix = "windows-workstation-secret-access-"
  policy = jsonencode(
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": [
                aws_secretsmanager_secret.windows-workstation-rdp-user.arn
            ]
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:ListSecrets",
            "Resource": "*"
        }
    ]
}
  )
}
resource "aws_iam_role_policy_attachment" "windows_workstation_instance-ssm" {
  role       = aws_iam_role.windows_workstation_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "windows_workstation_instance-secrets" {
  role       = aws_iam_role.windows_workstation_instance.name
  policy_arn = "${aws_iam_policy.windows_workstation_secrets.arn}"
}
resource "aws_iam_instance_profile" "windows_workstation_instance" {
	name_prefix = "windows-workstation-instance-"
	role = "${aws_iam_role.windows_workstation_instance.name}"
}



resource "aws_instance" "windows-workstation" {
	count = "${lookup(var.WINDOWS_WORKSTATION_CONFIG, "count")}"
	ami = "${data.aws_ami.windows-server-2022.id}"
	instance_type = "${lookup(var.WINDOWS_WORKSTATION_CONFIG, "instance_type")}"
	user_data = templatefile("${path.module}/templates/windows-workstation-init.tftpl", 
    {
      windowsWorkstationSecretARN = aws_secretsmanager_secret.windows-workstation-rdp-user.arn
    })
	iam_instance_profile = "${aws_iam_instance_profile.windows_workstation_instance.name}"
  subnet_id = "${aws_subnet.private_subnet[count.index].id}"
	tags = {
		Name = "${format("windows-workstation-%d",count.index + 1)}"
	}
	volume_tags = {
		Name = "${format("windows-workstation-%d",count.index + 1)}"
	}
	root_block_device {
		volume_type = "${lookup(var.WINDOWS_WORKSTATION_CONFIG, "volume_type")}"
		volume_size = "${lookup(var.WINDOWS_WORKSTATION_CONFIG, "volume_size")}"
	}
}

# resource "aws_vpc_endpoint" "ssm" {
#   vpc_id            = aws_vpc.vpc.id
#   service_name      = "${format("com.amazonaws.%s.ssm",data.aws_region.current_region.name)}"
#   vpc_endpoint_type = "Interface"
#   # security_group_ids = [
#   #   aws_security_group.sg1.id,
#   # ]
#   private_dns_enabled = true
#   tags = {
#     Name = "${format("%s-ssm",var.NAME)}"
#   }
# }

# resource "aws_vpc_endpoint" "ec2messages" {
#   vpc_id            = aws_vpc.vpc.id
#   service_name      = "${format("com.amazonaws.%s.ec2messages",data.aws_region.current_region.name)}"
#   vpc_endpoint_type = "Interface"
#   private_dns_enabled = true
#   tags = {
#     Name = "${format("%s-ec2messages",var.NAME)}"
#   }
# }

# resource "aws_vpc_endpoint" "ssmmessages" {
#   vpc_id            = aws_vpc.vpc.id
#   service_name      = "${format("com.amazonaws.%s.ssmmessages",data.aws_region.current_region.name)}"
#   vpc_endpoint_type = "Interface"
#   private_dns_enabled = true
#   tags = {
#     Name = "${format("%s-ssmmessages",var.NAME)}"
#   }
# }