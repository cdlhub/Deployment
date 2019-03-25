provider "aws" {
  profile = "${var.profile}"
  region = "${var.region}"

  provisioner "local-exec" {
    command = "echo ${aws_instance.oasis_aws.public_ip} > ip_address.txt"
  }
}

resource "aws_instance" "oasis_aws" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
}
