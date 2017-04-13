resource "tls_private_key" "ca" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.ca.private_key_pem}"

  subject {
    common_name = "kube-ca"
  }

  allowed_uses = [
    "server_auth",
    "client_auth",
    "digital_signature",
    "key_encipherment",
    "cert_signing",
  ]

  validity_period_hours = "24000"
  early_renewal_hours   = "720"
  is_ca_certificate     = "true"
}
