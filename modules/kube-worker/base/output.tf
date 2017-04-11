output "kube_worker_public_ips" {
  value = "${join(",",aws_instance.kube-worker.*.public_ip)}"
}

output "kube_worker_private_ips" {
  value = "${join(",",aws_instance.kube-worker.*.private_ip)}"
}

output "kube_worker_public_dns_s" {
  value = "${join(",",aws_instance.kube-worker.*.public_dns)}"
}

output "kube_worker_private_dns_s" {
  value = "${join(",",aws_instance.kube-worker.*.private_dns)}"
}
