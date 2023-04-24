output "installer_role_arn" {
  value = "${module.role.installer_role_arn}"
}

output "support_role_arn" {
  value = "${module.role.support_role_arn}"
}

output "controlplane_role_arn" {
  value = "${module.role.controlplane_role_arn}"
}

output "worker_role_arn" {
  value = "${module.role.worker_role_arn}"
}

output "private_subnet_id" {
  value = "${join(",", module.network.private_subnet_id)}"
}

output "all_subnet_id" {
  value = "${join(",", module.network.public_subnet_id)},${join(",", module.network.private_subnet_id)}"
}

output "rosa_console_url" {
  value = "${module.rosa-cluster.rosa_console_url.url}"
}

output "rosa_console_id" {
  value = "${module.rosa-cluster.rosa_cluster_id}"
}