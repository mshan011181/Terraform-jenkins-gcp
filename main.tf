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
    ports    = ["22"]
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



resource "google_compute_instance" "vm_instance" {
  name         = "test-instance"
  machine_type = "e2-medium"
  tags = ["test-instance"]
       
 boot_disk {
    initialize_params {
      image = "debian-12-bookworm-v20240312"
      }
     }
 
 network_interface {
    network = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.private_network.self_link  
    
    access_config {
        nat_ip = google_compute_address.static-ip.address
            }
         } 
     metadata_startup_script = <<-EOF
     #!/bin/bash
     echo "${google_compute_project_metadata_item.ssh-keys.value}" >> /home/shandba90/.ssh/authorized_keys
     EOF
}

data "terraform_remote_state" "ssh_keys" {
  backend = "gcs"

  config = {
    bucket = "your_bucket_name"
    prefix = "terraform/state"
  }
}

resource "google_compute_project_metadata_item" "ssh-keys" {
  key   = "ssh-keys"
  value = "${data.terraform_remote_state.ssh_keys.outputs.ssh_keys}"
}

output "instance_ip" {
  value = google_compute_instance.vm_instance.network_interface.0.access_config.0.assigned_nat_ip
}

resource "null_resource" "ansible_provisioner" {
  triggers = {
    instance_ip = google_compute_instance.vm_instance.network_interface.0.access_config.0.assigned_nat_ip
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i '${google_compute_instance.vm_instance.network_interface.0.access_config.0.assigned_nat_ip},' app_install_playbook.yaml"
  }
}




  
