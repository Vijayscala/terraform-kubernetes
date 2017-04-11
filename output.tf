output "etcd_ids" {
  value = "${split(",",module.etcd.etcd_ips)}"
}

output "kube_master_ips" {
  value = "${split(",",module.kube_master.kube_master_public_ips)}"
}

output "kube_worker_public_ips" {
  value = "${split(",",module.kube_workers.kube_worker_public_ips)}"
}
