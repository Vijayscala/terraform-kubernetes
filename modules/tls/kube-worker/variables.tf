variable "worker_dns_s" {}
variable "worker_ips" {}
variable "ca_private_key_pem" {}
variable "ca_cert_pem" {}

variable "worker_node_count" {
  description = "How many kube worker nodes?"
  default     = "3"
}
