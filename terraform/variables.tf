variable "profile" {}
variable "instance_type" {
    default = "t2.micro"
}
variable ami {
    default = "ami-01b60a3259250381b"
}
variable "region" {
  default = "ca-central-1"
}
