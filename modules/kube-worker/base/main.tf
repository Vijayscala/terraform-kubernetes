data "template_file" "cloud-config" {
  template = "${file("${path.module}/userdata/kube-worker.yaml.tpl")}"

  vars {
    discovery_token = "${var.etcd_discovery_url}"
    MASTER_HOST     = "${var.master_ip}"
    ADVERTISE_IP    = "$private_ipv4"
    DNS_SERVICE_IP  = "${var.dns_service_ip}"
    K8S_VER         = "v1.5.4_coreos.0"
    ETCD_ENDPOINTS  = "${var.etcd_endpoints}"
  }
}

resource "aws_instance" "kube-worker" {
  count                       = "${var.kube_worker_node_count}"
  ami                         = "${lookup(var.amis, var.aws_region)}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.aws_key_name}"
  vpc_security_group_ids      = ["${aws_security_group.all_open.id}"]
  subnet_id                   = "${var.subnet_ids}"
  associate_public_ip_address = true
  source_dest_check           = false
  user_data                   = "${data.template_file.cloud-config.rendered}"

  tags {
    Name = "etcd master ${var.kube_worker_node_count}"
  }
}
