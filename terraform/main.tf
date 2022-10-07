provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zones[0]
}

module "gcp-network" {
  source  = "terraform-google-modules/network/google"
  version = ">= 4.0.1, < 5.0.0"

  project_id   = var.project_id
  network_name = var.network

  subnets = [
    {
      subnet_name   = var.subnetwork
      subnet_ip     = "10.0.0.0/17"
      subnet_region = var.region
    },
  ]

  secondary_ranges = {
    (var.subnetwork) = [
      {
        range_name    = var.ip_range_pods_name
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = var.ip_range_services_name
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}



module "gke" {
  source     = "terraform-google-modules/kubernetes-engine/google"
  depends_on = [module.gcp-network]
  name       = "kedro-with-spark-on-k8s"
  project_id = var.project_id
  regional   = false
  region     = var.region
  zones      = var.zones

  network                = var.network
  subnetwork             = var.subnetwork
  ip_range_pods          = var.ip_range_pods_name
  ip_range_services      = var.ip_range_services_name
  create_service_account = true
  grant_registry_access  = true

  node_pools = [
    {
      name         = "default"
      machine_type = "e2-micro"
      min_count    = 1
      max_count    = 1
      auto_upgrade = true
    },
    {
      name         = "spark-drivers"
      machine_type = "n1-standard-2"
      min_count    = 0
      max_count    = 10
      disk_size_gb = 30
      disk_type    = "pd-standard"
    },
    {
      name         = "spark-executors"
      machine_type = "n1-standard-2"
      min_count    = 0
      max_count    = 10
      disk_size_gb = 30
      disk_type    = "pd-standard"
      preemptible  = true
    },
  ]

}


