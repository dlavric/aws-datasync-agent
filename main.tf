terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.38.0"
    }
  }
}

provider "aws" {
 region = "eu-west-2"
}

resource "aws_vpc" "test" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "daniela-vpc"
  }
}

resource "aws_subnet" "test" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "daniela-public-subnet"
  }
}

# Reference: https://docs.aws.amazon.com/datasync/latest/userguide/deploy-agents.html
data "aws_ssm_parameter" "aws_service_datasync_ami" {
  name = "/aws/service/datasync/ami"
}

resource "aws_internet_gateway" "test" {
  vpc_id = aws_vpc.test.id

  tags = {
    Name = "daniela-tag"
  }
}

resource "aws_route_table" "test" {
  vpc_id = aws_vpc.test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test.id
  }

  tags = {
    Name = "daniela-tag"
  }
}

resource "aws_route_table_association" "test" {
  subnet_id      = aws_subnet.test.id
  route_table_id = aws_route_table.test.id
}

resource "aws_security_group" "test" {
  name   = "daniela-tag"
  vpc_id = aws_vpc.test.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "daniela-tag"
  }
}

resource "aws_instance" "test" {
  depends_on = [aws_internet_gateway.test]

  ami                         = "ami-0e5f882be1900e43b"
  associate_public_ip_address = true
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.test.id]
  subnet_id                   = aws_subnet.test.id

  tags = {
    Name = "daniela-tag"
  }
}

resource "aws_datasync_agent" "test" {
  ip_address = aws_instance.test.public_ip
}

