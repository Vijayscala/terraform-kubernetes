variable "aws_key_file" {}
variable "ca_cert_pem" {}
variable "kube_worker_dns_s" {}
variable "worker_ips" {}
variable "worker_nodes_count" {}

variable "kube_worker_cert_pem_list" {
  type = "list"
}

variable "kube_worker_private_key_pem_list" {
  type = "list"
}
