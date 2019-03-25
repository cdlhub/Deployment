provider "aws" {
  profile = "${var.profile}"
  region = "${var.region}"

  provisioner "local-exec" {
    command = "echo ${aws_instance.oasis_aws.public_ip} > ip_address.txt"
  }
}

resource "aws_vpc" "oasis" {
  cidr_block = "10.0.0.0/16" # Defines overall VPC address space
  enable_dns_hostnames = true # Enable DNS hostnames for this VPC
  enable_dns_support = true # Enable DNS resolving support for this VPC
  tags{
      Name = "vpc-oasis-aws" # Tag VPC with name
  }
}

resource "aws_subnet" "oasis-public" {
  availability_zone = "${var.region}"
  cidr_block = "10.0.1.0/24" # Define CIDR-block for subnet
  map_public_ip_on_launch = true # Map public IP to deployed instances in this VPC
  vpc_id = "${aws_vpc.oasis.id}" # Link Subnet to VPC
  tags {
      Name = "subnet-oasis-public" # Tag subnet with name
  }
}

resource "aws_internet_gateway" "inetgw" {
  vpc_id = "${aws_vpc.oasis.id}"
  tags {
      Name = "igw-vpc-oasis-aws-default"
  }
}

resource "aws_route_table" "oasis-default" {
  vpc_id = "${aws_vpc.oasis.id}"

  route {
      cidr_block = "0.0.0.0/0" # Defines default route 
      gateway_id = "${aws_internet_gateway.inetgw.id}" # via IGW
  }

  tags {
      Name = "route-table-default"
  }
}

resource "aws_route_table_association" "oasis-rt-public" {
  subnet_id = "${aws_subnet.oasis-public.id}"
  route_table_id = "${aws_route_table.oasis-default.id}"
}

resource "aws_security_group" "oasis-sg"
{
    name = "oasis-sg"
    vpc_id = "${aws_vpc.oasis.id}"
    description = "Security group for Oasis UI"
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow incoming HTTP traffic to 8080 from anywhere"
    }
    ingress {
        from_port = 8000
        to_port = 8000
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow incoming HTTP traffic to 8000 from anywhere"
    }

    egress {
        from_port = 8080
        to_port = 8080
        protocol = "TCP"
    }

    egress {
        from_port = 8000
        to_port = 8000
        protocol = "TCP"
    }

    tags
    {
        Name = "sg-oasis-ui"
    }
}

resource "aws_instance" "oasis_aws" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  tags {
      Name = "ec2-oasis-aws"
  }
  subnet_id = "${aws_subnet.oasis-public.id}"
  key_name = "${aws_key_pair.keypair.key_name}"
  vpc_security_group_ids = ["${aws_security_group.oasis-ui.id}"]
}
