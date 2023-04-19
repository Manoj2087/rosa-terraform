# Account Preparation
The below tasks are one time task to be performed on your AWS account to provide necessary permission to link your Redhat account to AWS

## Insall ROSA cli

## Login to ROSA cli

`rosa login`

## create Openshift Cluster Manger role

run the below command to create the [ocm-role](https://docs.openshift.com/rosa/rosa_architecture/rosa-sts-about-iam-resources.html#rosa-sts-understanding-ocm-role_rosa-sts-about-iam-resources)

`rosa create ocm-role --mode auto`

# rosa-terraform