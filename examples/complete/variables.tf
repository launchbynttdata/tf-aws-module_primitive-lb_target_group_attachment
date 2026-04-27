// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

variable "logical_product_family" {
  description = "Logical product family the resources belong to."
  type        = string
  default     = "launch"
}

variable "logical_product_service" {
  description = "Logical product service the resources belong to."
  type        = string
  default     = "lbatt"
}

variable "class_env" {
  description = "Environment class (e.g. dev, qa, prod)."
  type        = string
  default     = "dev"
}

variable "instance_env" {
  description = "Numeric instance environment identifier (0-999)."
  type        = number
  default     = 0
}

variable "instance_resource" {
  description = "Numeric instance resource identifier (0-100)."
  type        = number
  default     = 0
}

variable "resource_names_map" {
  description = "Map of resource name suffixes and length budgets used by the resource_name module."
  type = map(object({
    name       = string
    max_length = optional(number, 60)
  }))
  default = {
    vpc = {
      name       = "vpc"
      max_length = 60
    }
    subnet = {
      name       = "sub"
      max_length = 60
    }
    target_group = {
      name       = "tg"
      max_length = 32
    }
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet that hosts the registered target."
  type        = string
  default     = "10.0.1.0/24"
}

variable "target_ip" {
  description = "IP address to register with the target group. Must lie within `subnet_cidr`."
  type        = string
  default     = "10.0.1.100"
}

variable "target_port" {
  description = "Port on which the target receives traffic and on which the target group listens."
  type        = number
  default     = 80
}

variable "availability_zone" {
  description = "Availability Zone in which to register the target. Set to `all` for cross-zone IP registration. Use `null` to let AWS infer the AZ from `target_ip`."
  type        = string
  default     = null
}

variable "quic_server_id" {
  description = "QUIC server ID for the target. Must be `null` unless the target group's protocol is `QUIC` or `TCP_QUIC`. The example creates an HTTP target group, so the default is `null`."
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags applied to created resources."
  type        = map(string)
  default     = {}
}
