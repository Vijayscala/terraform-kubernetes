resource "tls_private_key" "kube-worker" {
  algorithm = "RSA"
}

resource "tls_cert_request" "kube-worker" {
  count           = "${var.worker_node_count}"
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.kube-worker.private_key_pem}"

  subject {
    common_name = "${element(split(",",var.worker_dns_s),count.index)}"
  }

  ip_addresses = [
    "${element(split(",",var.worker_ips),count.index)}",
  ]
}

resource "tls_locally_signed_cert" "kube-worker" {
  count                 = "${var.worker_node_count}"
  cert_request_pem      = "${element(tls_cert_request.kube-worker.*.cert_request_pem,count.index)}"
  ca_key_algorithm      = "RSA"
  ca_private_key_pem    = "${var.ca_private_key_pem}"
  ca_cert_pem           = "${var.ca_cert_pem}"
  validity_period_hours = "8760"
  early_renewal_hours   = "720"

  allowed_uses = [
    "server_auth",
    "client_auth",
    "digital_signature",
    "key_encipherment",
  ]
}
