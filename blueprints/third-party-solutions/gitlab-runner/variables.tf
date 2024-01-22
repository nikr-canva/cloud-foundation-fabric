/**
 * Copyright 2023 Google LLC
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

variable "gitlab_config" {
  type = object({
    hostname    = optional(string, "gitlab.gcp.example.com")
    ca_cert_pem = optional(string, null)
  })
}

variable "gitlab_runner_config" {
  description = "Gitlab Runner config."
  type = object({
    authentication_token = string
    executors_config = object({
      docker_autoscaler = optional(object({
        gcp_project_id = string
        zone           = optional(string, "europe-west1-b")
        mig_name       = optional(string, "gitlab-runner")
        machine_type   = optional(string, "g1-small")
        machine_image  = optional(string, "coreos-cloud/global/images/family/coreos-stable")
        network_tags   = optional(list(string), ["gitlab-runner"])
      }), null)
      docker = optional(object({
        tls_verify = optional(bool, true)
      }), null)
    })
  })
  validation {
    condition = (
      (try(var.gitlab_runner_config.executors_config.docker_autoscaler, null) == null ? 0 : 1) +
      (try(var.gitlab_runner_config.executors_config.dockerx, null) == null ? 0 : 1) <= 1
    )
    error_message = "Only one type of gitlab runner can be configured at a time."
  }
}

variable "network_config" {
  description = "Shared VPC network configurations to use for Gitlab Runner VM."
  type = object({
    host_project      = optional(string)
    network_self_link = string
    subnet_self_link  = string
  })
}

variable "project_id" {
  description = "GCP Project id."
  type        = string
}

variable "vm_config" {
  type = object({
    boot_disk_size = optional(number, 100)
    name           = optional(string, "gitlab-runner-0")
    instance_type  = optional(string, "e2-standard-2")
    network_tags   = optional(list(string), [])
    zone           = optional(string, "europe-west1-b")
  })
}
