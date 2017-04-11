output "etcd_ips" {
  value = "${join(",",aws_instance.etcd.*.public_ip)}"
}
