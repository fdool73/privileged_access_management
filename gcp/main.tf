# Cloud Resource Manager API must be enabled in GCP project
# google_organization cannot be created via Terraform

# Create a VPC network
resource "google_compute_network" "vpc_network" {
  name = var.vpc_name
}

# Create a subnet within the network
resource "google_compute_subnetwork" "private_subnet" {
  name          = var.subnetwork_name
  ip_cidr_range = var.ip_cidr_range
  network       = google_compute_network.vpc_network.self_link
  region        = var.gcp_region
}

# Create a firewall rule to allow SSH from IAP
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.source_range] # Cisco VPN IP range
}

# Create a role for Privileged Access Manager (PAM)
resource "google_project_iam_custom_role" "pam_role" {
  role_id     = "pam_ssh"
  title       = "Privileged Access Manager SSH"
  description = "Role for Privileged Access Manager SSH access"

  permissions = [
    # Correct permission for IAP SSH
    "roles/iap.tunnelResourceAccessor"
  ]
}

# Create a VM instance
resource "google_compute_instance" "vm_instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.gcp_zone
  tags         = ["iap-ssh"]

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.self_link
    access_config {}
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro"]
  }
}

# Assign the role to the VM instance
resource "google_project_iam_member" "vm_pam_member" {
  role   = google_project_iam_custom_role.pam_role.id
  member = "serviceAccount:${google_compute_instance.vm_instance.service_account.0.email}"
  project = var.gcp_project_id
}

# Enable logging for VM instance
resource "google_logging_project_sink" "vm_logging_sink" {
  name        = "vm-logging-sink"
  destination = "pubsub.googleapis.com/projects/${var.gcp_project_id}/topics/vm-logs"
  filter      = "resource.type=gce_instance AND resource.labels.instance_id=${google_compute_instance.vm_instance.id}"
}

# Identity-Aware Proxy configuration for SSH access
resource "google_iap_tunnel_instance_iam_binding" "iap_ssh_binding" {
  project  = var.gcp_project_id
  zone     = var.gcp_zone
  instance = google_compute_instance.vm_instance.name

  role    = "roles/iap.tunnelResourceAccessor"
  members = [
    "serviceAccount:${google_service_account.iap_service_account.email}"
  ]
}

# Ensure the Cloud Identity-Aware Proxy API is enabled
resource "google_project_service" "iap_api" {
  project = var.gcp_project_id
  service = "iap.googleapis.com"
  disable_dependent_services = true
}

# Ensure the oslogin API is enabled and disable dependent services
resource "google_project_service" "oslogin" {
  project = var.gcp_project_id
  service = "oslogin.googleapis.com"
  disable_dependent_services = true
}

# Service account for IAP
resource "google_service_account" "iap_service_account" {
  account_id   = "iap-service-account"
  display_name = "IAP Service Account"
}

# Grant necessary permissions to the service account
resource "google_project_iam_binding" "iap_service_account_binding" {
  project = var.gcp_project_id

  role    = "roles/iap.httpsResourceAccessor"
  members = [
    "serviceAccount:${google_service_account.iap_service_account.email}"
  ]
}
