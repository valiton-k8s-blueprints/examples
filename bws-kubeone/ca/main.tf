resource "tls_private_key" "ca_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "client_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "ca_crt" {
  private_key_pem   = tls_private_key.ca_key.private_key_pem
  is_ca_certificate = true
  allowed_uses      = ["cert_signing"]

  validity_period_hours = var.ca_crt_ttl

  subject {
    common_name = var.ca_cn
  }
}

resource "tls_cert_request" "client_csr" {
  private_key_pem = tls_private_key.client_key.private_key_pem

  subject {
    common_name  = "admin"
    organization = "system:masters"
  }
}

resource "tls_locally_signed_cert" "client_crt" {
  ca_cert_pem           = tls_self_signed_cert.ca_crt.cert_pem
  ca_private_key_pem    = tls_private_key.ca_key.private_key_pem
  cert_request_pem      = tls_cert_request.client_csr.cert_request_pem
  validity_period_hours = var.client_crt_ttl

  allowed_uses = ["client_auth"]

}

resource "local_file" "ca_key" {
  filename = "ca.key"
  content  = tls_private_key.ca_key.private_key_pem
}

resource "local_file" "ca_crt" {
  filename = "ca.crt"
  content  = tls_self_signed_cert.ca_crt.cert_pem
}

resource "local_file" "client_key" {
  filename = "client.key"
  content  = tls_private_key.client_key.private_key_pem
}

resource "local_file" "client_crt" {
  filename = "client.crt"
  content  = tls_locally_signed_cert.client_crt.cert_pem
}

