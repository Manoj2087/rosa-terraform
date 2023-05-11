resource "aws_networkfirewall_rule_group" "block_domains" {
  capacity = 100
  name     = "block-domains"
  type     = "STATEFUL"
  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [var.SPOKE_EGRESS_VPC_CIDR_BLOCKS]
        }
      }
    }
    rules_source {
      rules_source_list {
        generated_rules_type = "DENYLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = [".facebook.com", ".twitter.com"]
      }
    }
  }

}

resource "aws_networkfirewall_rule_group" "allow_rosa_domains" {
  capacity = 100
  name     = "allow-rosa-domains"
  type     = "STATEFUL"
  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [var.SPOKE_EGRESS_VPC_CIDR_BLOCKS]
        }
      }
    }
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = [
          # Refer https://docs.openshift.com/rosa/rosa_install_access_delete_clusters/rosa_getting_started_iam/rosa-aws-prereqs.html#osd-aws-privatelink-firewall-prerequisites_prerequisites
          "registry.redhat.io",
          ".quay.io",
          "sso.redhat.com",
          "quay-registry.s3.amazonaws.com",
          "ocm-quay-production-s3.s3.amazonaws.com",
          "quayio-production-s3.s3.amazonaws.com",
          "cart-rhcos-ci.s3.amazonaws.com",
          "openshift.org",
          "registry.access.redhat.com",
          "console.redhat.com",
          "pull.q1w2.quay.rhcloud.com",
          ".q1w2.quay.rhcloud.com",
          "www.okd.io",
          "www.redhat.com",
          "aws.amazon.com",
          "catalog.redhat.com"
        ]
      }
    }
  }
}

resource "aws_networkfirewall_rule_group" "allow_domains" {
  capacity = 100
  name     = "allow-domains"
  type     = "STATEFUL"
  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [var.SPOKE_EGRESS_VPC_CIDR_BLOCKS]
        }
      }
    }
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = [".google.com"]
      }
    }
  }
}

resource "aws_networkfirewall_rule_group" "alert_all" {
  capacity = 1
  name     = "alert-all-https"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      stateful_rule {
        action = "ALERT"
        header {
          destination      = "ANY"
          destination_port = "ANY"
          direction        = "FORWARD"
          protocol         = "TLS"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["40"]
        }
      }
    }
  }
}

resource "aws_networkfirewall_rule_group" "block_all" {
  capacity = 1
  name     = "block-all"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      stateful_rule {
        action = "DROP"
        header {
          destination      = "ANY"
          destination_port = "ANY"
          direction        = "ANY"
          protocol         = "IP"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["50"]
        }
      }
    }
  }
}