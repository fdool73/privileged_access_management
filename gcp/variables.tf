variable "email" {
  description = "The email address for IAM member"
  type        = string
}

variable "vpc_name" {
  description = "Name of the network"
  type        = string
}

variable "subnetwork_name" {
  description = "Name of the subnetwork"
  type        = string
}

variable "region" {
  description = "GCP region for the subnetwork"
  type        = string
}

variable "ip_cidr_range" {
  description = "CIDR range for the subnetwork"
  type        = string
}

variable "instance_name" {
  description = "Name of the compute instance"
  type        = string
}

variable "machine_type" {
  description = "Type of machine for the compute instance"
  type        = string
}

variable "zone" {
  description = "GCP zone for the compute instance"
  type        = string
}

variable "image" {
  description = "Boot disk image for the compute instance"
  type        = string
}

variable "gcp_credentials_file" {
  description = "Path to the GCP credentials file"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_project_name" {
  description = "GCP project name"
  type        = string
}

variable "gcp_project_number" {
  description = "GCP project number"
  type        = string
}

variable "gcp_organization" {
  description = "GCP organization"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
}

variable "gcp_zone" {
  description = "GCP zone"
  type        = string
}

variable "source_range" {
  description = "CIDR block for Cisco VPN IP"
  type        = string
}