# Account Preparation
The below tasks are one time task to be performed on your AWS account to provide necessary permission to link your Redhat account to AWS

## Insall ROSA cli

## Generate to ROSA Offile Access Token

`rosa login`

## create Openshift Cluster Manger role

run the below command to create the [ocm-role](https://docs.openshift.com/rosa/rosa_architecture/rosa-sts-about-iam-resources.html#rosa-sts-understanding-ocm-role_rosa-sts-about-iam-resources)

`rosa create ocm-role --mode auto`

# rosa-terraform

## Supported ROSA deployement Architecture

1. Single AZ Public Cluster

2. Single AZ Private Cluster (Private link)

3. Multi AZ Public Cluster

4. Multi AZ Public Cluster (Private link)


# Troubleshooting

## Logs for creating or deletion of rosa cluster

The error logs for the creation and deletion og rosa cluster are pushed to the below location

`$HOME/.terraform-rosa/logs/create-rosa-cluster`

`$HOME/.terraform-rosa/logs/delete-rosa-cluster`

## Issues with creating or deletion of rosa cluster

If there is issue with the creation or deletion to get detailed error set `debug = true`

update `main.tf`

````
resource "shell_script" "rosa_cluster" {
  lifecycle_commands {
    create = templatefile("${path.module}/script-templates/create-cluster.tftpl",
        {
          ..
          ..
          debug = true
          ..
          ..
        }
    )
    read = templatefile("${path.module}/script-templates/read-cluster.tftpl",
        {
          ..
          ..
          debug = true
          ..
          ..
        }
    )
    # update = file("${path.module}/scripts/update.sh")
    delete = templatefile("${path.module}/script-templates/delete-cluster.tftpl",
        {
          ..
          ..
          debug = true
          ..
          ..
        }
    )
  }

  environment = {}

  sensitive_environment = {
    ROSA_OFFLINE_ACCESS_TOKEN = var.ROSA_TOKEN
  }

  interpreter = ["/bin/bash", "-c"]
}
````
