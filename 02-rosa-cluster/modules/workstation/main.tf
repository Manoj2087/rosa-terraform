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

#Create SSM VPC endpoint
resource "aws_vpc_endpoint" "ssm_endpoint" {
  vpc_id            = "${var.VPC_ID}"
  service_name      = "${format("com.amazonaws.%s.ssm",var.AWS_REGION)}"
  vpc_endpoint_type = "Interface"
  subnet_ids        = "${var.PRIVATE_SUBNET}"
  private_dns_enabled = true
  tags = {
    Name = "${format("%s-ssm-endpoint",var.NAME)}"
  }
}
resource "aws_vpc_endpoint" "ssm_messages_endpoint" {
  vpc_id            = "${var.VPC_ID}"
  service_name      = "${format("com.amazonaws.%s.ssmmessages",var.AWS_REGION)}"
  vpc_endpoint_type = "Interface"
  subnet_ids        = "${var.PRIVATE_SUBNET}"
  private_dns_enabled = true
  tags = {
    Name = "${format("%s-ssm-messages-endpoint",var.NAME)}"
  }
}
resource "aws_vpc_endpoint" "ec2_messages_endpoint" {
  vpc_id            = "${var.VPC_ID}"
  service_name      = "${format("com.amazonaws.%s.ec2messages",var.AWS_REGION)}"
  vpc_endpoint_type = "Interface"
  subnet_ids        = "${var.PRIVATE_SUBNET}"
  private_dns_enabled = true
  tags = {
    Name = "${format("%s-ec2-messages-endpoint",var.NAME)}"
  }
}

#Create IAM Instance Profile for the workstation instance
resource "aws_iam_role" "linux_workstation_instance" {
  name_prefix = "${format("%s-linux-",var.NAME)}"
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
    Name = "${format("%s-linux",var.NAME)}"
  }
}
resource "aws_iam_role_policy_attachment" "linux_workstation_instance" {
  role       = aws_iam_role.linux_workstation_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "linux_workstation_instance" {
	name_prefix = "${format("%s-linux-",var.NAME)}"
	role = "${aws_iam_role.linux_workstation_instance.name}"
}

resource "aws_instance" "linux-workstation" {
	ami = "${data.aws_ami.amazon-linux-2.id}"
	instance_type = "${lookup(var.LINUX_WORKSTATION_CONFIG, "instance_type")}"
	user_data = templatefile("${path.module}/templates/linux-workstation-init.tftpl", {
    hostnames   = format("%s-linux",var.NAME)
  })
	iam_instance_profile = "${aws_iam_instance_profile.linux_workstation_instance.name}"
  subnet_id = "${var.PRIVATE_SUBNET[0]}"
	tags = {
		Name = "${format("%s-linux",var.NAME)}"
	}
	volume_tags = {
		Name = "${format("%s-linux",var.NAME)}"
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
  password_length = 25
  # exclude_numbers = true
  exclude_punctuation = true
}
resource "aws_secretsmanager_secret" "windows-workstation-rdp-user" {
  name_prefix  = format("%s-windows-rdp-user-",var.NAME)
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
  name_prefix = format("%s-windows-",var.NAME)
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
    Name = format("%s-windows",var.NAME)
  }
}
resource "aws_iam_policy" "windows_workstation_secrets" {
  name_prefix = format("%s-windows-",var.NAME)
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
	name_prefix = format("%s-windows-",var.NAME)
	role = "${aws_iam_role.windows_workstation_instance.name}"
}



resource "aws_instance" "windows-workstation" {
	ami = "${data.aws_ami.windows-server-2022.id}"
	instance_type = "${lookup(var.WINDOWS_WORKSTATION_CONFIG, "instance_type")}"
	user_data = templatefile("${path.module}/templates/windows-workstation-init.tftpl", 
    {
      windowsWorkstationSecretARN = aws_secretsmanager_secret.windows-workstation-rdp-user.arn
    })
	iam_instance_profile = "${aws_iam_instance_profile.windows_workstation_instance.name}"
  subnet_id = "${var.PRIVATE_SUBNET[0]}"
	tags = {
		Name = "${format("%s-windows",var.NAME)}"
	}
	volume_tags = {
		Name = "${format("%s-windows",var.NAME)}"
	}
	root_block_device {
		volume_type = "${lookup(var.WINDOWS_WORKSTATION_CONFIG, "volume_type")}"
		volume_size = "${lookup(var.WINDOWS_WORKSTATION_CONFIG, "volume_size")}"
	}
}