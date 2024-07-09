/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# tfdoc:file:description Main branch resources.

module "branch-folders" {
  source              = "../../../modules/folder"
  for_each            = local.branch_folders
  parent              = local.root_node
  name                = each.value.name
  contacts            = each.value.config.contacts
  firewall_policy     = each.value.config.firewall_policy
  logging_data_access = each.value.config.logging_data_access
  logging_exclusions  = each.value.config.logging_exclusions
  logging_settings    = each.value.config.logging_settings
  logging_sinks       = each.value.config.logging_sinks
  iam = {
    for k, v in each.value.config.iam : k => [
      for vv in v : try(
        module.branch-sa["${each.value.branch}/${vv}"].iam_email,
        vv
      )
    ]
  }
  iam_bindings = {
    for k, v in each.value.config.iam_bindings : k => merge(v, {
      member = try(
        module.branch-sa["${each.value.branch}/${v.member}"].iam_email,
        v.member
      )
    })
  }
  iam_bindings_additive = {
    for k, v in each.value.config.iam_bindings : k => merge(v, {
      member = try(
        module.branch-sa["${each.value.branch}/${v.member}"].iam_email,
        v.member
      )
    })
  }
  # dynamic keys are not supported here so don't look for substitutions
  iam_by_principals = each.value.config.iam_by_principals
  org_policies      = each.value.config.org_policies
  tag_bindings      = each.value.config.tag_bindings
}

module "branch-sa" {
  source                 = "../../../modules/iam-service-account"
  for_each               = local.branch_service_accounts
  project_id             = var.automation.project_id
  name                   = "resman-${each.value.name}"
  display_name           = "Terraform resman service account for ${each.value.branch}."
  prefix                 = var.prefix
  service_account_create = var.root_node == null
  iam = !each.value.cicd_enabled ? {} : {
    "roles/iam.serviceAccountTokenCreator" = [
      module.branch-cicd-sa["${each.key}-cicd"].iam_email
    ]
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = !endswith(each.key, "sa-rw") ? {} : {
    (var.automation.outputs_bucket) = ["roles/storage.objectAdmin"]
  }
}

module "branch-gcs" {
  source        = "../../../modules/gcs"
  for_each      = local.branch_buckets
  project_id    = var.automation.project_id
  name          = "prod-resman-${each.key}-0"
  prefix        = var.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin" = [
      module.branch-sa["${each.key}/sa-rw"].iam_email
    ]
    "roles/storage.objectViewer" = [
      module.branch-sa["${each.key}/sa-ro"].iam_email
    ]
  }
}