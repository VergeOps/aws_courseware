provider "aws" {
  region     = "us-east-1"
}

resource "aws_security_group" "security_group_name" {
  name        = "security_group_name"
  description = "Allow port 8000"
  vpc_id      = "vpc-594fdb23"

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
