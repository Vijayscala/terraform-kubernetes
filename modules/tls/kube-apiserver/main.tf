resource "tls_private_key" "kube-apiserver" {
  algorithm = "RSA"
}

resource "tls_cert_request" "kube-apiserver" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.kube-apiserver.private_key_pem}"

  subject {
    common_name = "kube-apiserver"
  }

  dns_names = [
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster.local",
  ]

  ip_addresses = ["${split(",",var.master_ips)}", "${split(",",var.etcd_ips)}"]
}

resource "tls_locally_signed_cert" "kube-apiserver" {
  cert_request_pem      = "${tls_cert_request.kube-apiserver.cert_request_pem}"
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
