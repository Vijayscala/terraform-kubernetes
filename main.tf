module "vpc" {
  source = "./modules/vpc"

  vpc_name          = "${var.vpc_name}"
  vpc_cidr          = "${var.vpc_cidr}"
  public_subnet_map = "${var.public_subnet_map}"
}

module "etcd" {
  source = "./modules/etcd"

  aws_region         = "${var.aws_region}"
  aws_key_name       = "${var.aws_key_name}"
  subnet_ids         = "${module.vpc.subnet_ids}"
  vpc_id             = "${module.vpc.vpc_id}"
  etcd_discovery_url = "${var.etcd_discovery_url}"
  ectd_node_count    = "${var.ectd_node_count}"
}

module "tls_ca" {
  source = "./modules/tls/kube-ca"
}

module "kube_master" {
  source = "./modules/kube-master/base"

  aws_region             = "${var.aws_region}"
  aws_key_name           = "${var.aws_key_name}"
  subnet_ids             = "${module.vpc.subnet_ids}"
  vpc_id                 = "${module.vpc.vpc_id}"
  etcd_discovery_url     = "${var.etcd_discovery_url}"
  kube_master_node_count = "${var.kube_master_node_count}"
  etcd_endpoints         = "${join(",",formatlist("http://%s:2379",split(",",module.etcd.etcd_ips)))}"
  dns_service_ip         = "${var.dns_service_ip}"
  service_ip_range       = "${var.service_ip_range}"
  pod_network            = "${var.pod_network}"
}

module "tls_kube_apiserver" {
  source = "./modules/tls/kube-apiserver"

  ca_private_key_pem = "${module.tls_ca.private_key_pem}"
  ca_cert_pem        = "${module.tls_ca.cert_pem}"
  etcd_ips           = "${module.etcd.etcd_ips}"
  k8s_service_ip     = "${var.k8s_service_ip}"
  master_ips         = "${module.kube_master.kube_master_private_ips}"
}

module "kube_master_add_certs_and_restart" {
  source = "./modules/kube-master/add_certs_and_restart"

  master_ips                     = "${module.kube_master.kube_master_public_ips}"
  master_nodes_count             = "${var.kube_master_node_count}"
  aws_key_file                   = "${var.aws_key_file}"
  ca_cert_pem                    = "${module.tls_ca.cert_pem}"
  kube_apiserver_cert_pem        = "${module.tls_kube_apiserver.cert_pem}"
  kube_apiserver_private_key_pem = "${module.tls_kube_apiserver.private_key_pem}"
}

module "kube_workers" {
  source = "./modules/kube-worker/base"

  aws_region             = "${var.aws_region}"
  aws_key_name           = "${var.aws_key_name}"
  subnet_ids             = "${module.vpc.subnet_ids}"
  vpc_id                 = "${module.vpc.vpc_id}"
  etcd_discovery_url     = "${var.etcd_discovery_url}"
  kube_worker_node_count = "${var.kube_worker_node_count}"
  etcd_endpoints         = "${join(",",formatlist("http://%s:2379",split(",",module.etcd.etcd_ips)))}"
  dns_service_ip         = "${var.dns_service_ip}"
  master_ip              = "${element(split(",",module.kube_master.kube_master_private_ips), 0)}"
}

module "tls_kube_worker" {
  source = "./modules/tls/kube-worker"

  worker_node_count  = "${var.kube_worker_node_count}"
  ca_private_key_pem = "${module.tls_ca.private_key_pem}"
  ca_cert_pem        = "${module.tls_ca.cert_pem}"
  worker_ips         = "${module.kube_workers.kube_worker_private_ips}"
  worker_dns_s       = "${module.kube_workers.kube_worker_private_dns_s}"
}

module "kube_worker_add_certs_and_restart" {
  source = "./modules/kube-worker/add_certs_and_restart"

  worker_ips                       = "${module.kube_master.kube_master_public_ips}"
  worker_nodes_count               = "${var.kube_master_node_count}"
  aws_key_file                     = "${var.aws_key_file}"
  ca_cert_pem                      = "${module.tls_ca.cert_pem}"
  kube_worker_cert_pem_list        = "${module.tls_kube_worker.cert_pems}"
  kube_worker_private_key_pem_list = "${module.tls_kube_worker.private_key_pems}"
  kube_worker_dns_s                = "${module.kube_workers.kube_worker_private_dns_s}"
}

module "tls_kube_adminr" {
  source = "./modules/tls/kube-admin"

  ca_private_key_pem = "${module.tls_ca.private_key_pem}"
  ca_cert_pem        = "${module.tls_ca.cert_pem}"
}
