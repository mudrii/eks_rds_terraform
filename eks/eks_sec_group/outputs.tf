output "security_group_cluster" {
  value = "${aws_security_group.cluster.id}"
}

output "security_group_node" {
  value = "${aws_security_group.node.id}"
}
