output "kube_master_public_ips" {
  value = "${join(",",aws_instance.kube-master.*.public_ip)}"
}

output "kube_master_private_ips" {
  value = "${join(",",aws_instance.kube-master.*.private_ip)}"
}
