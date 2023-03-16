locals {
  str_f = "_"
  str_r = "-"
}

resource "google_service_account" "compute" {
  account_id   = format(lower(replace(var.name_format, local.str_f, local.str_r)), "sa")
  display_name = "Service Account for compute resources"
  project      = var.project_id
}

resource "google_project_iam_member" "compute" {
  for_each = toset([
    "roles/compute.admin",
    "roles/osconfig.osPolicyAssignmentAdmin",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/storage.objectAdmin",
    "roles/bigquery.admin"
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.compute.email}"
}
