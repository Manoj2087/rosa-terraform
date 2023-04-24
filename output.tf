# output "installer_role_arn" {
#   value = "${module.rosa-role.installer_role_arn}"
# }

# output "support_role_arn" {
#   value = "${module.rosa-role.support_role_arn}"
# }

# output "controlplane_role_arn" {
#   value = "${module.rosa-role.controlplane_role_arn}"
# }

# output "worker_role_arn" {
#   value = "${module.rosa-role.worker_role_arn}"
# }

# output "private_subnet_id" {
#   value = "${join(",", module.network.private_subnet_id)}"
# }

# output "all_subnet_id" {
#   value = "${join(",", module.network.public_subnet_id)},${join(",", module.network.private_subnet_id)}"
# }

# output "rosa_console_url" {
#   value = "${module.rosa-cluster.rosa_console_url.url}"
# }

# output "rosa_console_id" {
#   value = "${module.rosa-cluster.rosa_cluster_id}"
# }

output "rosa_console_url" {
    value = "${jsondecode(shell_script.rosa_cluster.output.console)}"
}

output "rosa_cluster_id" {
    value = "${shell_script.rosa_cluster.output.id}"
}