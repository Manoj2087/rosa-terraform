# Create Network Firewall policy if DEPLOY_FIREWALL is true
resource "aws_networkfirewall_firewall_policy" "firewall_policy" {
  count = "${var.DEPLOY_FIREWALL ? 1 : 0 }"
  name = "${format("%s",var.NAME)}"
  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.block_domains.arn
    }
    # stateful_rule_group_reference {
    #   resource_arn = aws_networkfirewall_rule_group.block_all.arn
    # }
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.allow_rosa_domains.arn
    }
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.alert_all.arn
    }
  }
}

# Create Network Firewall if DEPLOY_FIREWALL is true
resource "aws_networkfirewall_firewall" "firewall" {
  count = "${var.DEPLOY_FIREWALL ? 1 : 0 }"
  name                = "${format("%s",var.NAME)}"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.firewall_policy[count.index].arn
  vpc_id              = aws_vpc.vpc.id
  dynamic "subnet_mapping" {
    for_each = aws_subnet.fw_subnet[*].id
    content {
      subnet_id = subnet_mapping.value
      ip_address_type = "IPV4"
    }
  }

  tags = {
    Name = "${format("%s",var.NAME)}"
  }
}

# Create cloudwatch log group to store Network firewall alerts if DEPLOY_FIREWALL is true
resource "aws_cloudwatch_log_group" "firewall_alert_log_group" {
  count = "${var.DEPLOY_FIREWALL ? 1 : 0 }"
  name = "${format("/aws/network-firewall/%s/alert",var.NAME)}"
}

# Create bucket to store Network firewall flow logs if DEPLOY_FIREWALL is true
resource "aws_s3_bucket" "firewall_flow_log_bucket" {
  count = "${var.DEPLOY_FIREWALL ? 1 : 0 }"
  bucket_prefix      = "${format("%s-firewall-flowlog-bucket-",var.NAME)}"
  force_destroy = true
}
resource "aws_s3_bucket_server_side_encryption_configuration" "firewall_flow_log_bucket" {
  count = "${var.DEPLOY_FIREWALL ? 1 : 0 }"
  bucket = aws_s3_bucket.firewall_flow_log_bucket[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}
resource "aws_s3_bucket_public_access_block" "firewall_flow_log_bucket" {
  count = "${var.DEPLOY_FIREWALL ? 1 : 0 }"
  bucket = aws_s3_bucket.firewall_flow_log_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Configure Network Firewall logging if DEPLOY_FIREWALL is true
resource "aws_networkfirewall_logging_configuration" "anfw_alert_logging_configuration" {
  count = "${var.DEPLOY_FIREWALL ? 1 : 0 }"
  firewall_arn = aws_networkfirewall_firewall.firewall[0].arn
  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.firewall_alert_log_group[0].name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
    log_destination_config {
      log_destination = {
        bucketName = aws_s3_bucket.firewall_flow_log_bucket[0].bucket
      }
      log_destination_type = "S3"
      log_type             = "FLOW"
    }
  }
}