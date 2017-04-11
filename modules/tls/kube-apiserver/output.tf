output "private_key_pem" {
  value = "${tls_private_key.kube-apiserver.private_key_pem}"
}

output "cert_request_pem" {
  value = "${tls_cert_request.kube-apiserver.cert_request_pem}"
}

output "cert_pem" {
  value = "${tls_locally_signed_cert.kube-apiserver.cert_pem}"
}
