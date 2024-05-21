variable "project_id" {
  description = "The project ID to deploy to"
}

variable "region" {
  description = "The region to deploy to"
}

variable "zone" {
  description = "The zone to deploy to"
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  default     = "gke"
}

variable "network" {
  description = "The VPC network to use for the GKE cluster"
  default     = "default"
}

variable "master_ipv4_cidr" {
  description = "The CIDR block for the GKE master network"
  default     = "172.16.0.32/28"
}

variable "gke_node_sa_name" {
  description = "The name of the GKE node service account"
  default     = "gke-node-sa"
}

