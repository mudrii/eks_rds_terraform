data "aws_availability_zones" "available" {}

resource "aws_db_subnet_group" "db_sub_gr" {
  description = "terrafom db subnet group"
  name        = "main_subnet_group"
  subnet_ids  = ["${var.subnets}"]

  #  subnet_ids = [
  #    "${var.api_dev_int_subnet_ids}"]
  tags {
    Name = "${terraform.workspace}"
  }
}

resource "aws_db_instance" "db" {
  identifier        = "${var.identifier}"
  storage_type      = "${var.storage_type}"
  allocated_storage = "${var.allocated_storage[terraform.workspace]}"
  engine            = "${var.db_engine}"
  engine_version    = "${var.engine_version}"
  instance_class    = "${var.instance_class[terraform.workspace]}"
  name              = "${terraform.workspace}"
  username          = "${var.db_username}"
  password          = "${var.db_password}"

  vpc_security_group_ids = [
    "${var.sec_grp_rds}",
  ]

  db_subnet_group_name = "${aws_db_subnet_group.db_sub_gr.id}"
  storage_encrypted    = false
  skip_final_snapshot  = true
  publicly_accessible  = false
  multi_az             = false

  tags {
    Name = "${terraform.workspace}"
  }
}
