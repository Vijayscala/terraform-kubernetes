output "vpc_id" {
  value = "${aws_vpc.default.id}"
}

output "subnet_ids" {
  value = "${join(",",aws_subnet.eu-west-1-public.*.id)}"
}
