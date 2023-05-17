# fetch the AZvailability Zone - exclude local zones
data "aws_availability_zones" "azs" {
  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}