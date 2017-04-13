output "etcd_public_ips" {
  value = "${join(",",aws_instance.etcd.*.public_ip)}"
}

output "etcd_private_ips" {
  value = "${join(",",aws_instance.etcd.*.private_ip)}"
}
