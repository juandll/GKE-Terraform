output "gke_cluster_name" {
  value = google_container_cluster.primary.name
}

output "gke_node_service_account" {
  value = google_service_account.gke_node_sa.email
}


output "firewall_name" {
  value = google_compute_firewall.default.name
}
output "gke_cluster_endpoint" {
  value = google_container_cluster.primary.endpoint
}