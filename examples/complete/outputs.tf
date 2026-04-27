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

output "id" {
  description = "Synthetic identifier of the target group attachment."
  value       = module.attachment.id
}

output "target_group_arn" {
  description = "ARN of the target group the attachment is registered with."
  value       = module.attachment.target_group_arn
}

output "target_id" {
  description = "Identifier of the registered target."
  value       = module.attachment.target_id
}

output "port" {
  description = "Port on which the registered target receives traffic."
  value       = module.attachment.port
}

output "availability_zone" {
  description = "Availability Zone in which the target is registered."
  value       = module.attachment.availability_zone
}

output "quic_server_id" {
  description = "QUIC server ID assigned to the target, if applicable."
  value       = module.attachment.quic_server_id
}

output "vpc_id" {
  description = "Identifier of the VPC created by the example."
  value       = aws_vpc.vpc.id
}

output "subnet_id" {
  description = "Identifier of the subnet created by the example."
  value       = aws_subnet.subnet.id
}
