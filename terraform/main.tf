provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_service_account" "gke_node_sa" {
  account_id   = var.gke_node_sa_name
  display_name = var.gke_node_sa_name
}

resource "google_project_iam_member" "gke_node_sa_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
  ])
  project = var.project_id
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
  role    = each.value
}


resource "google_compute_router" "nat_router" {
  name    = var.cluster_name
  network = var.network
  region  = var.region
}

resource "google_compute_router_nat" "nat_config" {
  name                        = var.cluster_name
  router                      = google_compute_router.nat_router.name
  region                      = var.region
  nat_ip_allocate_option      = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

}


resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location           = var.zone
  network            = var.network
  initial_node_count = 1
  remove_default_node_pool = true

  private_cluster_config {
    enable_private_nodes    = true
    #master_ipv4_cidr_block  = var.master_ipv4_cidr Only for using kubctl inside the network with an allowed network
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  datapath_provider = "ADVANCED_DATAPATH"
  enable_shielded_nodes = true
}

resource "google_container_node_pool" "primary_nodes" {
  cluster    = google_container_cluster.primary.name
  location   = var.zone
  node_count = 1

  node_config {
    machine_type = "n2d-standard-4"
    service_account = google_service_account.gke_node_sa.email
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    disk_size_gb = 50
    disk_type = "pd-standard"

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}



resource "google_compute_firewall" "default" {
  name    = "${var.cluster_name}-firewall"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}
module "cloud_armor_policy" {
  source                = "./modules/cloud_armor_policy"
  policy_name           = "ddos-and-waf-protection-policy"
  description           = "A security policy to protect against DDOS attacks and common web attacks"
  ddos_protection_rule  = ["1.2.3.4/32", "5.6.7.8/32"]
}
resource "google_monitoring_notification_channel" "channel" {
  display_name = "GKE_Alerting"
  type         = "email"

  labels = {
    email_address = "juandllanom@gmail.com"
  }
}


resource "google_monitoring_alert_policy" "cpu_alert" {
  display_name         = "cpu_alert"
  project              = var.project_id
  notification_channels = [google_monitoring_notification_channel.channel.name]
  combiner             = "OR"  # Specify the combiner, can be "AND" or "OR"
  conditions {
    display_name  = "High cpu"
    condition_threshold {
      filter      = "metric.type=\"kubernetes.io/container/cpu/core_usage_time\" AND resource.type=\"k8s_container\""
      comparison  = "COMPARISON_GT"
      threshold_value = 1
      duration     = "60s"  
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"  
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }
}
