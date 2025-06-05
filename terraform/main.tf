# Configure the Google Cloud provider
provider "google" {
  credentials = file("./key.json")   
  project = var.project_id
  region  = var.region
}

# Enable required Google Cloud APIs
resource "google_project_service" "gke" {
  project = var.project_id
  service = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

# Create a GKE cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  depends_on = [
    google_project_service.gke,
    google_project_service.compute
  ]
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
    ]

    labels = {
      env = var.project_id
    }

    # Machine type for nodes
    machine_type = var.machine_type
    disk_size_gb = 50  # Reduce from default 100GB
    disk_type    = "pd-standard"  # Use HDD instead of SSD
    
    # Add tags if needed
    tags = ["gke-node", "${var.project_id}-gke"]
    
    # Set metadata for nodes
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

# Create a VPC network for the cluster
resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false
}

# Create a subnet in the VPC
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster_name}-subnet"
  ip_cidr_range = "10.2.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

data "google_client_config" "default" {}

# Deploy a Kubernetes deployment from Docker Hub
resource "kubernetes_deployment" "docker_hub_app" {
  metadata {
    name = var.app_name
    labels = {
      app = var.app_name
    }
  }

  spec {
    replicas = var.replica_count

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }

      spec {
        container {
          image = var.docker_image
          name  = var.app_name

          port {
            container_port = var.container_port
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }

  depends_on = [
    google_container_node_pool.primary_nodes
  ]
}

# Create a Kubernetes service to expose the deployment
resource "kubernetes_service" "app_service" {
  metadata {
    name = "${var.app_name}-service"
  }
  spec {
    selector = {
      app = kubernetes_deployment.docker_hub_app.metadata[0].labels.app
    }
    port {
      port        = 8545
      target_port = var.container_port
    }

    type = "LoadBalancer"
  }
}

# Output the service external IP
output "load_balancer_ip" {
  value = kubernetes_service.app_service.status[0].load_balancer[0].ingress[0].ip
}

# Variables
variable "project_id" {
  description = "The project ID to host the cluster in"
  type        = string
}

variable "region" {
  description = "The region to host the cluster in"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "The name for the GKE cluster"
  type        = string
  default     = "my-gke-cluster"
}

variable "node_count" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Machine type for nodes"
  type        = string
  default     = "e2-medium"
}

variable "app_name" {
  description = "geth node"
  type        = string
  default     = "go-ethereum-hell-contract"
}

variable "docker_image" {
  description = "Docker image to deploy from Docker Hub"
  type        = string
  default     = "nginx:latest"
}

variable "container_port" {
  description = "Port the container exposes"
  type        = number
  default     = 8545
}

variable "replica_count" {
  description = "Number of pod replicas"
  type        = number
  default     = 1
}