resource "shell_script" "rosa_cluster" {
  lifecycle_commands {
    create = templatefile("${path.module}/script-templates/create-cluster.tftpl",
        {
          cluster_prefix = var.CLUSTER_PREFIX,
          installer_role_arn = module.role.installer_role_arn,
          support_role_arn = module.role.support_role_arn,
          controlplane_role_arn = module.role.controlplane_role_arn,
          worker_role_arn = module.role.worker_role_arn,
          ocp_version = var.OCP_VERSION,
          multi_az = var.MULTI_AZ,
          subnet_ids = var.PRIVATE_CLUSTER ? join(",", module.network.private_subnet_id) : join(",", module.network.public_subnet_id, module.network.private_subnet_id),
          private_cluster = var.PRIVATE_CLUSTER,
          worker_machine_type = var.WORKER_MACHINE_TYPE[var.ENV],
          worker_replica = var.WORKER_MACHINE_REPLICA[var.ENV],
          machine_cidr = var.VPC_CIDR,
          service_cidr = var.SERVICE_CIDR,
          pod_cidr = var.POD_CIDR,
          host_prefix = var.HOST_PREFIX,
          aws_region = var.AWS_REGION,
          debug = false,
        }
    )
    read = templatefile("${path.module}/script-templates/read-cluster.tftpl",
        {
          cluster_prefix = var.CLUSTER_PREFIX
        }
    )
    # update = file("${path.module}/scripts/update.sh")
    delete = templatefile("${path.module}/script-templates/delete-cluster.tftpl",
        {
          cluster_prefix = var.CLUSTER_PREFIX,
          debug = false
        }
    )
  }

  environment = {}

  sensitive_environment = {
    ROSA_OFFLINE_ACCESS_TOKEN = var.ROSA_TOKEN
  }

  interpreter = ["/bin/bash", "-c"]
  depends_on = [
    module.network,
    module.role
  ]

}