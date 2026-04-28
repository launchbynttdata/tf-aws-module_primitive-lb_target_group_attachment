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

variable "target_group_arn" {
  description = "ARN of the target group with which to register the target."
  type        = string
}

variable "target_id" {
  description = <<-EOT
    Identifier of the target to register. The expected value depends on the target group's `target_type`:
      - `instance` : EC2 instance ID.
      - `ip`       : IP address (must fall within the VPC CIDR, RFC 1918 ranges, or 100.64.0.0/10).
      - `lambda`   : Lambda function ARN.
      - `alb`      : Application Load Balancer ARN.
  EOT
  type        = string
}

variable "port" {
  description = "Port on which the target receives traffic. Required when the target group's `target_type` is `instance`, `ip`, or `alb`. Must be omitted when `target_type` is `lambda`."
  type        = number
  default     = null

  validation {
    condition     = var.port == null ? true : (var.port >= 1 && var.port <= 65535)
    error_message = "port must be between 1 and 65535."
  }
}

variable "availability_zone" {
  description = "Availability Zone in which to register the target. Set to `all` to register an IP target outside the VPC subnet (cross-zone). Only valid when the target group's `target_type` is `ip`."
  type        = string
  default     = null
}

variable "region" {
  description = "AWS region in which to manage the target group attachment. Set to `null` to inherit the region from the AWS provider configuration. Use this only when the calling stack manages multiple regions and you need to override the provider default per-attachment."
  type        = string
  default     = null
}

variable "quic_server_id" {
  description = "Server ID for the target. Must be the literal `0x` prefix followed by exactly 16 hexadecimal characters and unique at the listener level. Required when the target group's protocol is `QUIC` or `TCP_QUIC`; must be omitted for any other protocol. Modifying this value forces replacement of the attachment."
  type        = string
  default     = null

  validation {
    condition     = var.quic_server_id == null ? true : can(regex("^0x[0-9a-fA-F]{16}$", var.quic_server_id))
    error_message = "quic_server_id must start with `0x` and be followed by exactly 16 hexadecimal characters."
  }
}
