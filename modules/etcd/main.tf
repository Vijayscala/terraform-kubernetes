data "template_file" "cloud-config" {
  template = "${file("${path.module}/userdata/etcd.yaml.tpl")}"

  vars {
    discovery_token = "${var.etcd_discovery_url}"
  }
}

resource "aws_instance" "etcd" {
  count                       = "${var.ectd_node_count}"
  ami                         = "${lookup(var.amis, var.aws_region)}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.aws_key_name}"
  vpc_security_group_ids      = ["${aws_security_group.all_open.id}"]
  subnet_id                   = "${var.subnet_ids}"
  associate_public_ip_address = true
  source_dest_check           = false
  user_data                   = "${data.template_file.cloud-config.rendered}"

  tags {
    Name = "etcd-${count.index}"
  }
}
