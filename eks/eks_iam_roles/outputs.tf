output "iam_cluster_arn" {
  value = "${aws_iam_role.cluster.arn}"
}

output "iam_instance_profile" {
  value = "${aws_iam_instance_profile.node.name}"
}

output "iam_node_arn" {
  value = "${aws_iam_role.node.arn}"
}
