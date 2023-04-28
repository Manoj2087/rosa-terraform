# workstation Network


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
  subnet_id = "${var.SUBNET_ID[count.index]}"
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
  subnet_id = "${var.SUBNET_ID[count.index]}"
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