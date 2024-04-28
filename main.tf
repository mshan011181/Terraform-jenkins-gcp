locals {
  project_id = var.project_id
}

provider "google" {
  project = local.project_id
  region  = "us-west1"
  zone    = "us-west1-b"
  credentials = "/home/shandba90/jenkins-gce.json"
}

resource "google_project_service" "compute_service" {
  project = local.project_id
  service = "compute.googleapis.com"
  disable_dependent_services = true
   lifecycle {
  prevent_destroy = true
    }
}

resource "google_compute_network" "vpc_network" {
  name                    = "terraform-network"
  auto_create_subnetworks = false
  delete_default_routes_on_create = true
   depends_on = [
    google_project_service.compute_service
  ]
 }

resource "google_compute_subnetwork" "private_network" {
  name          = "private-network"
  ip_cidr_range = "10.2.0.0/16"
  network       = google_compute_network.vpc_network.self_link 
}

resource "google_compute_firewall" "firewall" {
  provider = google
  name    = "firewall"
  network = google_compute_network.vpc_network.self_link 

  allow {
    protocol = "icmp"
      }

 source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
      }
}

resource "google_compute_router" "router" {
  name    = "quickstart-router"
  network = google_compute_network.vpc_network.self_link
}

resource "google_compute_router_nat" "nat" {
  name                               = "quickstart-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_route" "private_network_internet_route" {
  name             = "private-network-internet"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc_network.self_link
  next_hop_gateway = "default-internet-gateway"
  priority    = 100
}


resource "google_compute_address" "static-ip" {
  provider = google
  name = "static-ip"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}


resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_output" {
  sensitive_content = tls_private_key.example.private_key_pem
  filename          = "/bitnami/jenkins/home/workspace/create_infra_VM_using_terraform_jenkins2/private_key.pem"
}

output "public_key" {
  value     = tls_private_key.example.public_key_openssh
  sensitive = true
}

output "private_key" {
  value     = tls_private_key.example.private_key_pem
  sensitive = true
}




resource "google_compute_instance" "vm_instance" {
  name         = "test-instance"
  machine_type = "e2-medium"
  tags = ["test-instance"]
       
 boot_disk {
    initialize_params {
      image = "debian-12-bookworm-v20240312"
      size = 50
      }
     }
 
 network_interface {
    network = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.private_network.self_link  
    
    access_config {
        nat_ip = google_compute_address.static-ip.address
            }
         }     
    metadata = {
     # other metadata
     ssh-keys = "jenkins:${file("/bitnami/jenkins/home/.ssh/id_rsa.pub")}"
     json_key = base64encode(file("/path/to/gcp_sa_key.json"))
      }     
}

# Output the instances' public IP addresses as a list
output "instance_public_ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}


 
