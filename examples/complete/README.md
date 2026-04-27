# Complete example

This example creates the supporting infrastructure required to register an IP target with a target group and exercises the `tf-aws-module_primitive-lb_target_group_attachment` module against it. The created resources are:

- A VPC.
- A single subnet inside that VPC.
- An ELBv2 target group with `target_type = "ip"`.
- An attachment that registers an arbitrary IP from the subnet's CIDR range as a target of the target group.

## Usage

```hcl
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
```

## Run

```shell
terraform init
terraform plan -var-file=test.tfvars
terraform apply -var-file=test.tfvars
terraform destroy -var-file=test.tfvars
```

Sensible defaults are encoded in `test.tfvars`. Override any of them by passing additional `-var` flags or by editing the file in place.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.10 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.71, < 7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.42.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_resource_names"></a> [resource\_names](#module\_resource\_names) | terraform.registry.launch.nttdata.com/module_library/resource_name/launch | ~> 2.0 |
| <a name="module_attachment"></a> [attachment](#module\_attachment) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_lb_target_group.tg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_subnet.subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_logical_product_family"></a> [logical\_product\_family](#input\_logical\_product\_family) | Logical product family the resources belong to. | `string` | `"launch"` | no |
| <a name="input_logical_product_service"></a> [logical\_product\_service](#input\_logical\_product\_service) | Logical product service the resources belong to. | `string` | `"lbatt"` | no |
| <a name="input_class_env"></a> [class\_env](#input\_class\_env) | Environment class (e.g. dev, qa, prod). | `string` | `"dev"` | no |
| <a name="input_instance_env"></a> [instance\_env](#input\_instance\_env) | Numeric instance environment identifier (0-999). | `number` | `0` | no |
| <a name="input_instance_resource"></a> [instance\_resource](#input\_instance\_resource) | Numeric instance resource identifier (0-100). | `number` | `0` | no |
| <a name="input_resource_names_map"></a> [resource\_names\_map](#input\_resource\_names\_map) | Map of resource name suffixes and length budgets used by the resource\_name module. | <pre>map(object({<br/>    name       = string<br/>    max_length = optional(number, 60)<br/>  }))</pre> | <pre>{<br/>  "subnet": {<br/>    "max_length": 60,<br/>    "name": "sub"<br/>  },<br/>  "target_group": {<br/>    "max_length": 32,<br/>    "name": "tg"<br/>  },<br/>  "vpc": {<br/>    "max_length": 60,<br/>    "name": "vpc"<br/>  }<br/>}</pre> | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC. | `string` | `"10.0.0.0/16"` | no |
| <a name="input_subnet_cidr"></a> [subnet\_cidr](#input\_subnet\_cidr) | CIDR block for the subnet that hosts the registered target. | `string` | `"10.0.1.0/24"` | no |
| <a name="input_target_ip"></a> [target\_ip](#input\_target\_ip) | IP address to register with the target group. Must lie within `subnet_cidr`. | `string` | `"10.0.1.100"` | no |
| <a name="input_target_port"></a> [target\_port](#input\_target\_port) | Port on which the target receives traffic and on which the target group listens. | `number` | `80` | no |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | Availability Zone in which to register the target. Set to `all` for cross-zone IP registration. Use `null` to let AWS infer the AZ from `target_ip`. | `string` | `null` | no |
| <a name="input_quic_server_id"></a> [quic\_server\_id](#input\_quic\_server\_id) | QUIC server ID for the target. Must be `null` unless the target group's protocol is `QUIC` or `TCP_QUIC`. The example creates an HTTP target group, so the default is `null`. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags applied to created resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | Synthetic identifier of the target group attachment. |
| <a name="output_target_group_arn"></a> [target\_group\_arn](#output\_target\_group\_arn) | ARN of the target group the attachment is registered with. |
| <a name="output_target_id"></a> [target\_id](#output\_target\_id) | Identifier of the registered target. |
| <a name="output_port"></a> [port](#output\_port) | Port on which the registered target receives traffic. |
| <a name="output_availability_zone"></a> [availability\_zone](#output\_availability\_zone) | Availability Zone in which the target is registered. |
| <a name="output_quic_server_id"></a> [quic\_server\_id](#output\_quic\_server\_id) | QUIC server ID assigned to the target, if applicable. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | Identifier of the VPC created by the example. |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | Identifier of the subnet created by the example. |
<!-- END_TF_DOCS -->
