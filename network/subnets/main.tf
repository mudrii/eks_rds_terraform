# Create a external facing subnets in us-west-2a AZ
data "aws_availability_zones" "available" {}

resource "aws_subnet" "subnet" {
  count                   = "${length(data.aws_availability_zones.available.names)}"
  cidr_block              = "${cidrsubnet(var.vpc_cidr_block, 8, count.index)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id                  = "${var.vpc_id}"
  map_public_ip_on_launch = true

  tags = "${
    map(
     "Name", "terraform-eks-${terraform.workspace}",
     "kubernetes.io/cluster/${var.eks_cluster_name}-${terraform.workspace}", "shared",
    )
  }"
}
