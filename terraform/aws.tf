provider "aws" {
  profile = "cdl_tftuto"
  region = "ca-central-1"
}

resource "aws_instance" "oasis_aws" {
  ami           = "ami-01b60a3259250381b"
  instance_type = "t2.micro"
}
