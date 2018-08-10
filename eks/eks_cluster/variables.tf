variable "eks_cluster_name" {}

variable "iam_cluster_arn" {}

variable "iam_node_arn" {}

variable "subnets" {
  type = "list"
}

variable "security_group_cluster" {}
