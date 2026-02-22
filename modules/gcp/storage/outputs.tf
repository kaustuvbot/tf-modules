output "bucket_name" {
  description = "Name of the GCS bucket"
  value       = google_storage_bucket.this.name
}

output "bucket_url" {
  description = "URL of the GCS bucket"
  value       = "gs://${google_storage_bucket.this.name}"
}

output "bucket_id" {
  description = "ID of the GCS bucket"
  value       = google_storage_bucket.this.id
}

output "bucket_self_link" {
  description = "Self link of the GCS bucket"
  value       = google_storage_bucket.this.self_link
}
