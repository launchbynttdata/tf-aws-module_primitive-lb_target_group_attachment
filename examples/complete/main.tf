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

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

module "resource_names" {
  source  = "terraform.registry.launch.nttdata.com/module_library/resource_name/launch"
  version = "~> 2.0"

  for_each = var.resource_names_map

  logical_product_family  = var.logical_product_family
  logical_product_service = var.logical_product_service
  region                  = join("", split("-", data.aws_region.current.name))
  class_env               = var.class_env
  cloud_resource_type     = each.value.name
  instance_env            = var.instance_env
  instance_resource       = var.instance_resource
  maximum_length          = each.value.max_length
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = module.resource_names["vpc"].standard
  })
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(var.tags, {
    Name = module.resource_names["subnet"].standard
  })
}

resource "aws_lb_target_group" "tg" {
  name        = module.resource_names["target_group"].minimal_random_suffix
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"
  port        = var.target_port
  protocol    = "HTTP"

  tags = var.tags
}

module "attachment" {
  source = "../.."

  target_group_arn  = aws_lb_target_group.tg.arn
  target_id         = var.target_ip
  port              = var.target_port
  availability_zone = var.availability_zone
  quic_server_id    = var.quic_server_id
}
