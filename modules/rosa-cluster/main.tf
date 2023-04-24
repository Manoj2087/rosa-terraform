resource "shell_script" "rosa_cluster" {
  lifecycle_commands {
    create = templatefile("${path.module}/script-templates/create-cluster.tftpl",
        {
          cluster_prefix = var.CLUSTER_PREFIX,
          installer_role_arn = var.INSTALLER_ROLE_ARN,
          support_role_arn = var.SUPPORT_ROLE_ARN,
          controlplane_role_arn = var.CONTROLPLANE_ROLE_ARN,
          worker_role_arn = var.WORKER_ROLE_ARN,
          ocp_version = var.OCP_VERSION,
          multi_az = var.MULTI_AZ,
          subnet_ids = var.PRIVATE_CLUSTER ? var.PRIVATE_SUBNET_ID : var.ALL_SUBNET_ID,
          private_cluster = var.PRIVATE_CLUSTER,
          worker_machine_type = var.WORKER_MACHINE_TYPE[var.ENV],
          worker_replica = var.WORKER_MACHINE_REPLICA[var.ENV],
          machine_cidr = var.MACHINE_CIDR,
          service_cidr = var.SERVICE_CIDR,
          pod_cidr = var.POD_CIDR,
          host_prefix = var.HOST_PREFIX,
          aws_region = var.AWS_REGION,
          debug = false,
          /* this variable is only created as dependency to ensure the NATGW 
          and its route are created in the network module before this module starts */
          private_natgw_route_id = var.PRIVATE_NATGW_ROUTE_ID
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
          debug = false,
          /* this variable is only created as dependency to ensure the NATGW 
          and its route are created in the network module before this module starts */
          installer_role_arn = var.INSTALLER_ROLE_ARN,
          support_role_arn = var.SUPPORT_ROLE_ARN,
          controlplane_role_arn = var.CONTROLPLANE_ROLE_ARN,
          worker_role_arn = var.WORKER_ROLE_ARN,
          private_natgw_route_id = var.PRIVATE_NATGW_ROUTE_ID
        }
    )
  }

  environment = {}

  sensitive_environment = {
    ROSA_OFFLINE_ACCESS_TOKEN = var.ROSA_TOKEN
  }

  interpreter = ["/bin/bash", "-c"]


}