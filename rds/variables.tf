variable "subnets" {
  type = "list"
}

variable "identifier" {}

variable "storage_type" {}

variable "allocated_storage" {
  type = "map"
}

variable "db_engine" {}

variable "engine_version" {}

variable "instance_class" {
  type = "map"
}

variable "db_username" {}

variable "db_password" {}

variable "sec_grp_rds" {}
