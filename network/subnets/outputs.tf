output "subnets" {
  value = ["${aws_subnet.subnet.*.id}"]
}
