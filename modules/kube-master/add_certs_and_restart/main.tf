resource "null_resource" "add_kube_master_certs_and_restart" {
  count = "${var.master_nodes_count}"

  triggers {
    kubelet_count       = "${var.ca_cert_pem}"
    kubelet_private_key = "${var.kube_apiserver_cert_pem}"
    kubelet_certs_pem   = "${var.kube_apiserver_private_key_pem}"
    ip_addresses        = "${var.master_ips}"
  }

  connection {
    type        = "ssh"
    user        = "core"
    private_key = "${file(var.aws_key_file)}"
    host        = "${element(split(",",var.master_ips), count.index)}"
  }

  provisioner "remote-exec" {
    inline = [
      "if [ ! -d /etc/kubernetes/ssl/ ]; then sudo mkdir -m 644 -p /etc/kubernetes/ssl/;fi",
      "echo '${var.ca_cert_pem}' | sudo tee /etc/kubernetes/ssl/ca.pem",
      "echo '${var.kube_apiserver_cert_pem}' | sudo tee /etc/kubernetes/ssl/apiserver.pem",
      "echo '${var.kube_apiserver_private_key_pem}' | sudo tee /etc/kubernetes/ssl/apiserver-key.pem",
      "sudo chmod 600 /etc/kubernetes/ssl/*.pem",
      "sudo chown root /etc/kubernetes/ssl/*.pem",
      "sudo systemctl daemon-reload",
    ]
  }
}
