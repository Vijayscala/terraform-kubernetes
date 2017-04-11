output "private_key_pems" {
  value = ["${tls_private_key.kube-worker.*.private_key_pem}"]
}

output "cert_request_pems" {
  value = ["${tls_cert_request.kube-worker.*.cert_request_pem}"]
}

output "cert_pems" {
  value = ["${tls_locally_signed_cert.kube-worker.*.cert_pem}"]
}
