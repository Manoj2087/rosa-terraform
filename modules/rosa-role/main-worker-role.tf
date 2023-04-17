resource "aws_iam_role" "worker_role" {
  name = "${format("%s-worker-role",var.CLUSTER_PREFIX)}"
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
    red-hat-managed = "true"
    rosa_openshift_version = "4.12"
    rosa_role_prefix = var.CLUSTER_PREFIX
    rosa_role_type = "instance_worker"
  }
}

resource "aws_iam_policy" "worker_role_policy" {
  name = "${format("%s-worker-role-policy",var.CLUSTER_PREFIX)}"
  policy = jsonencode(
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeRegions"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
  )
}

resource "aws_iam_role_policy_attachment" "worker_role" {
  role       = aws_iam_role.worker_role.name
  policy_arn = aws_iam_policy.worker_role_policy.arn
}