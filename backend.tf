terraform {
  backend "s3" {
    bucket = "terra-state-bucket"
    key    = "tfstate"
    region = "us-west-2"
  }
}
