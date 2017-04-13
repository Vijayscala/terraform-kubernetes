resource "null_resource" "add_kube_worker_certs_and_restart" {
  count = "${var.worker_nodes_count}"

  triggers {
    kubelet_count       = "${var.ca_cert_pem}"
    kubelet_private_key = "${join(",",var.kube_worker_cert_pem_list)}"
    kubelet_certs_pem   = "${join(",",var.kube_worker_private_key_pem_list)}"
    ip_addresses        = "${var.worker_ips}"
  }

  connection {
    type        = "ssh"
    user        = "core"
    private_key = "${file(var.aws_key_file)}"
    host        = "${element(split(",",var.worker_ips), count.index)}"
  }

  provisioner "remote-exec" {
    inline = [
      "if [ ! -d /etc/kubernetes/ssl/ ]; then sudo mkdir -m 644 -p /etc/kubernetes/ssl/;fi",
      "echo '${var.ca_cert_pem}' | sudo tee /etc/kubernetes/ssl/ca.pem",
      "echo '${element(var.kube_worker_cert_pem_list,count.index)}' | sudo tee /etc/kubernetes/ssl/worker.pem",
      "echo '${element(var.kube_worker_private_key_pem_list,count.index)}' | sudo tee /etc/kubernetes/ssl/worker-key.pem",
      "sudo chmod 600 /etc/kubernetes/ssl/*.pem",
      "sudo chown root /etc/kubernetes/ssl/*.pem",
      "sudo systemctl daemon-reload",
    ]
  }
}
