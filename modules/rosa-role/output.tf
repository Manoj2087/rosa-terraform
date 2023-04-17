output "installer_role_arn" {
  value = "${aws_iam_role.installer_role.arn}"
}

output "support_role_arn" {
  value = "${aws_iam_role.support_role.arn}"
}

output "controlplane_role_arn" {
  value = "${aws_iam_role.controlplane_role.arn}"
}

output "worker_role_arn" {
  value = "${aws_iam_role.worker_role.arn}"
}