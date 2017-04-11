#VPC
resource "aws_vpc" "default" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags {
    Name = "${var.vpc_name}"
  }
}

#Public Subnets
resource "aws_subnet" "eu-west-1-public" {
  count  = "${length(list(var.public_subnet_map))}"
  vpc_id = "${aws_vpc.default.id}"

  cidr_block        = "${element(values(var.public_subnet_map), count.index)}"
  availability_zone = "${element(keys(var.public_subnet_map), count.index)}"

  tags {
    Name = "Public Subnet - ${element(values(var.public_subnet_map), count.index)}"
  }
}

#IGW
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

#Route table
resource "aws_route_table" "eu-west-1-public" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags {
    Name = "Public Subnet"
  }
}

#Connect subnets to route table
resource "aws_route_table_association" "eu-west-1-public" {
  count          = "${length(list(var.public_subnet_map))}"
  subnet_id      = "${element(aws_subnet.eu-west-1-public.*.id, count.index)}"
  route_table_id = "${aws_route_table.eu-west-1-public.id}"
}
