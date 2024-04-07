# Define variables for GCP provider configuration
variable "project_id" {
  description = "The ID of the Google Cloud Platform project"
  type        = string
  default     = "devops-project1-418302"
}

variable "region" {
  description = "The region where resources will be created"
  type        = string
  default     = ""
}

variable "zone" {
  description = "The zone where resources will be created"
  type        = string
  default     = ""
}

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
  default     = "my-network"
}

variable "subnet_name" {
  description = "The name of the subnet within the VPC network"
  type        = string
  default     = "my-subnet"
}
