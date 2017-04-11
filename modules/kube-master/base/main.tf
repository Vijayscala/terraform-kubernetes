data "template_file" "cloud-config" {
  template = "${file("${path.module}/userdata/kube-master.yaml.tpl")}"

  vars {
    discovery_token  = "${var.etcd_discovery_url}"
    ETCD_ENDPOINTS   = "${var.etcd_endpoints}"
    K8S_VER          = "v1.5.4_coreos.0"
    ADVERTISE_IP     = "$private_ipv4"
    DNS_SERVICE_IP   = "${var.dns_service_ip}"
    SERVICE_IP_RANGE = "${var.service_ip_range}"
    POD_NETWORK      = "${var.pod_network}"

    #NETWORK_PLUGIN    = ""
  }
}

resource "aws_instance" "kube-master" {
  count                       = "${var.kube_master_node_count}"
  ami                         = "${lookup(var.amis, var.aws_region)}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.aws_key_name}"
  vpc_security_group_ids      = ["${aws_security_group.all_open.id}"]
  subnet_id                   = "${var.subnet_ids}"
  associate_public_ip_address = true
  source_dest_check           = false
  user_data                   = "${data.template_file.cloud-config.rendered}"

  tags {
    Name = "etcd master ${var.kube_master_node_count}"
  }
}
