resource "aws_security_group" "all_open" {
  name        = "all_open_kube_master_sg"
  description = "Allow incoming HTTP connections."

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"] #${var.private_subnet_cidr}
  }

  vpc_id = "${var.vpc_id}"

  tags {
    Name = "all_open-sg"
  }
}
