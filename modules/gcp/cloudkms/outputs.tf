output "key_ring_id" {
  description = "ID of the KMS key ring"
  value       = google_kms_key_ring.this.id
}

output "crypto_key_id" {
  description = "ID of the KMS crypto key"
  value       = google_kms_crypto_key.this.id
}

output "crypto_key_name" {
  description = "Name of the KMS crypto key"
  value       = google_kms_crypto_key.this.name
}

output "crypto_key_self_link" {
  description = "Self link of the KMS crypto key"
  value       = google_kms_crypto_key.this.self_link
}
