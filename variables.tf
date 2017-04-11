variable "aws_credentials_file" {}
variable "aws_profile" {}
variable "aws_key_name" {}
variable "aws_key_file" {}
variable "dns_service_ip" {}
variable "service_ip_range" {}
variable "pod_network" {}
variable "k8s_service_ip" {}

variable "aws_region" {
  description = "EC2 Region for the VPC"
  default     = "eu-west-1"
}

variable "vpc_name" {
  description = "Name of VPC"
}

variable "vpc_cidr" {
  description = "CIDR for the whole VPC"
}

variable "public_subnet_map" {
  description = "Public Subnet Mapping - { Zone = CIDR .... }"
  type        = "map"
}

variable "etcd_discovery_url" {
  description = "input result from https://discovery.etcd.io/new?size=<size>"
}

variable "ectd_node_count" {
  description = "How many etcd nodes?"
}

variable "kube_master_node_count" {
  description = "How many kubernetes master nodes?"
}

variable "kube_worker_node_count" {
  description = "How many kubernetes worker nodes?"
}
