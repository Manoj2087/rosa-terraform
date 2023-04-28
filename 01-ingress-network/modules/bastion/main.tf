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

#Create IAM Instance Profile for the BAstion instance
resource "aws_iam_role" "linux_bastion_instance" {
  name_prefix = "linux-bastion-instance-"
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
    name = "linux-bastion-instance"
  }
}
resource "aws_iam_role_policy_attachment" "linux_bastion_instance" {
  role       = aws_iam_role.linux_bastion_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "linux_bastion_instance" {
	name_prefix = "linux-bastion-instance-"
	role = "${aws_iam_role.linux_bastion_instance.name}"
}

resource "aws_instance" "linux-bastion" {
	count = "${lookup(var.LINUX_BASTION_CONFIG, "count")}"
	ami = "${data.aws_ami.amazon-linux-2.id}"
	instance_type = "${lookup(var.LINUX_BASTION_CONFIG, "instance_type")}"
	# key_name = "${aws_key_pair.ec2-keypair-bastion.key_name}"
	user_data = templatefile("${path.module}/templates/linux-bastion-init.tftpl", {
    hostnames   = format("linux-bastion-%d",count.index + 1)
  })
	iam_instance_profile = "${aws_iam_instance_profile.linux_bastion_instance.name}"
  subnet_id = "${var.SUBNET_ID[count.index]}"
	tags = {
		Name = "${format("linux-bastion-%d",count.index + 1)}"
	}
	volume_tags = {
		Name = "${format("linux-bastion-%d",count.index + 1)}"
	}
	root_block_device {
		volume_type = "${lookup(var.LINUX_BASTION_CONFIG, "volume_type")}"
		volume_size = "${lookup(var.LINUX_BASTION_CONFIG, "volume_size")}"
	}
	# lifecycle {
	# 	ignore_changes = ["subnet_id","user_data","ami","network_interface"]
	# }
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

#Create secret for windows-bastion 'rdp-user' password
data "aws_secretsmanager_random_password" "windows-bastion-rdp-user" {
  password_length = 20
  exclude_numbers = true
}
resource "aws_secretsmanager_secret" "windows-bastion-rdp-user" {
  name_prefix                = "windows-bastion-rdp-user-"
}
resource "aws_secretsmanager_secret_version" "windows-bastion-rdp-user" {
  secret_id = aws_secretsmanager_secret.windows-bastion-rdp-user.id
  secret_string = <<EOF
{
"username":"rdp-user",
"password":"${data.aws_secretsmanager_random_password.windows-bastion-rdp-user.random_password}"
}
EOF
	lifecycle {
		ignore_changes = [secret_string]
	}
}

#Create IAM Instance Profile for the BAstion instance
resource "aws_iam_role" "windows_bastion_instance" {
  name_prefix = "windows-bastion-instance-"
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
    name = "windows-bastion-instance"
  }
}
resource "aws_iam_policy" "windows_bastion_secrets" {
  name_prefix = "windows-bastion-secret-access-"
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
                aws_secretsmanager_secret.windows-bastion-rdp-user.arn
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
resource "aws_iam_role_policy_attachment" "windows_bastion_instance-ssm" {
  role       = aws_iam_role.windows_bastion_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "windows_bastion_instance-secrets" {
  role       = aws_iam_role.windows_bastion_instance.name
  policy_arn = "${aws_iam_policy.windows_bastion_secrets.arn}"
}
resource "aws_iam_instance_profile" "windows_bastion_instance" {
	name_prefix = "windows-bastion-instance-"
	role = "${aws_iam_role.windows_bastion_instance.name}"
}



resource "aws_instance" "windows-bastion" {
	count = "${lookup(var.WINDOWS_BASTION_CONFIG, "count")}"
	ami = "${data.aws_ami.windows-server-2022.id}"
	instance_type = "${lookup(var.WINDOWS_BASTION_CONFIG, "instance_type")}"
	user_data = templatefile("${path.module}/templates/windows-bastion-init.tftpl", 
    {
      windowsBastionSecretARN = aws_secretsmanager_secret.windows-bastion-rdp-user.arn
    })
	iam_instance_profile = "${aws_iam_instance_profile.windows_bastion_instance.name}"
  subnet_id = "${var.SUBNET_ID[count.index]}"
	tags = {
		Name = "${format("windows-bastion-%d",count.index + 1)}"
	}
	volume_tags = {
		Name = "${format("windows-bastion-%d",count.index + 1)}"
	}
	root_block_device {
		volume_type = "${lookup(var.WINDOWS_BASTION_CONFIG, "volume_type")}"
		volume_size = "${lookup(var.WINDOWS_BASTION_CONFIG, "volume_size")}"
	}
	# lifecycle {
	# 	ignore_changes = ["subnet_id","user_data","ami","network_interface"]
	# }
}