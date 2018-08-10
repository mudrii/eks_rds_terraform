# Create new routing table without internet access for minin instances

data "aws_availability_zones" "available" {}

locals {
  network_count = "${length(data.aws_availability_zones.available.names)}"
}

resource "aws_default_route_table" "route" {
  default_route_table_id = "${var.main_route_table_id}"

  tags {
    Name = "${terraform.workspace}"
  }
}

resource "aws_route_table_association" "route_ass" {
  count          = "${local.network_count}"
  subnet_id      = "${element(var.subnets, count.index)}"
  route_table_id = "${var.main_route_table_id}"
}

# Internet access
resource "aws_route" "route_internet" {
  route_table_id         = "${var.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${var.gw_id}"
  depends_on             = ["aws_route_table_association.route_ass"]
}
