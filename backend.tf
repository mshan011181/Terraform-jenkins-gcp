terraform {
 backend "gcs" {
   bucket  = "test-bucket-terraform"  
   prefix  = "terraform/state"
 }
}
