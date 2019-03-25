provider "aws" {
  profile = "cdl_tftuto"
  region = "${var.region}"

  provisioner "local-exec" {
    command = "echo ${aws_instance.oasis_aws.public_ip} > ip_address.txt"
  }
}

resource "aws_instance" "oasis_aws" {
  ami           = "ami-01b60a3259250381b"
  instance_type = "t2.micro"
}
