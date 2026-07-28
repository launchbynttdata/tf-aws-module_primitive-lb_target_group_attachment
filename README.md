# tf-aws-module_primitive-lb_target_group_attachment

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![License: CC BY-NC-ND 4.0](https://img.shields.io/badge/License-CC_BY--NC--ND_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-nd/4.0/)

## Overview

Primitive Terraform module that wraps the [`aws_lb_target_group_attachment`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) resource. It registers a single target (EC2 instance, IP, Lambda function, or ALB) with an Elastic Load Balancer v2 target group.

The module exposes every documented argument of the underlying resource and produces no opinionated defaults beyond Terraform's, so callers retain full control over registration semantics.

> ⚠️ **AWS provider v6 only.** This module requires the AWS provider in the range `>= 6.0, < 7.0`. That is **a departure from most other launchbynttdata primitive modules**, which still permit AWS provider v5. The v6 floor is required because this module exposes the per-resource `region` argument, which is part of the v6-only "enhanced region support" feature. If your calling stack pins AWS provider v5, you will need to upgrade to v6 before consuming this module. See the [Provider compatibility](#provider-compatibility) section below for details.

## Usage

```hcl
module "attachment" {
  source = "git::https://github.com/launchbynttdata/tf-aws-module_primitive-lb_target_group_attachment.git?ref=<tag>"

  target_group_arn  = aws_lb_target_group.example.arn
  target_id         = aws_instance.example.id
  port              = 80
  availability_zone = null
  quic_server_id    = null
  region            = null
}
```

A complete, deployable example lives in [`examples/complete`](./examples/complete).

## Supported `target_type` semantics

The value passed to `target_id` must match the target group's `target_type`:

| `target_type` | Expected `target_id`                                                    | Notes                                                                                                              |
|---------------|-------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------|
| `instance`    | EC2 instance ID                                                         | `port` is required.                                                                                                |
| `ip`          | IP address inside the VPC CIDR, RFC 1918 ranges, or `100.64.0.0/10`     | `port` is required. `availability_zone` may be set to a specific AZ or to `all` for cross-zone IP registration.    |
| `lambda`      | Lambda function ARN                                                     | `port` must be omitted. The function must grant `elasticloadbalancing.amazonaws.com` invoke permission beforehand. |
| `alb`         | Application Load Balancer ARN                                           | `port` is required. Used to register an ALB as a target of a Network Load Balancer.                                |

## Provider compatibility

Compatible with the AWS provider in the range `>= 6.0, < 7.0`. The 6.0 floor is required because the per-resource `region` argument is exposed by this module so callers can manage attachments outside the provider's default region without configuring an aliased provider; per-resource region overrides ("enhanced region support") are an AWS provider v6 feature.

## Pre-Commit hooks

[.pre-commit-config.yaml](.pre-commit-config.yaml) defines `pre-commit` hooks that run terraform, golang, and lint checks. The `commitlint` hook enforces [Conventional Commits](https://www.conventionalcommits.org/) for commit messages. To enable the commit-message hook locally, run:

```shell
pre-commit install --hook-type commit-msg
```

`detect-secrets-hook` prevents new secrets from being introduced into the baseline. See the [pre-commit documentation](https://pre-commit.com/) for installation and hook management.

## Testing the module locally

1. Install the LCAF tooling that the `Makefile` relies on:

   ```shell
   make configure
   ```

   This pulls in shared makefile fragments, installs pre-commit hooks, and downloads policy bundles.

2. Provide AWS credentials. The example uses an SSO profile by default (see `examples/complete/provider.tf`). Authenticate with AWS SSO (`aws sso login --profile <profile>`) or any equivalent mechanism that yields valid credentials in the calling shell.

3. Run the full validation pipeline (lint, plan, conftest, terratest, OPA):

   ```shell
   make check
   ```

   `make check` succeeds only if Terraform plans cleanly, the configured policies pass, and the Terratest suite under `tests/` registers and verifies a target via the AWS API.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.10 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0, < 7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_lb_target_group_attachment.attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | Availability Zone in which to register the target. Set to `all` to register an IP target outside the VPC subnet (cross-zone). Only valid when the target group's `target_type` is `ip`. | `string` | `null` | no |
| <a name="input_port"></a> [port](#input\_port) | Port on which the target receives traffic. Required when the target group's `target_type` is `instance`, `ip`, or `alb`. Must be omitted when `target_type` is `lambda`. | `number` | `null` | no |
| <a name="input_quic_server_id"></a> [quic\_server\_id](#input\_quic\_server\_id) | Server ID for the target. Must be the literal `0x` prefix followed by exactly 16 hexadecimal characters and unique at the listener level. Required when the target group's protocol is `QUIC` or `TCP_QUIC`; must be omitted for any other protocol. Modifying this value forces replacement of the attachment. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region in which to manage the target group attachment. Set to `null` to inherit the region from the AWS provider configuration. Use this only when the calling stack manages multiple regions and you need to override the provider default per-attachment. | `string` | `null` | no |
| <a name="input_target_group_arn"></a> [target\_group\_arn](#input\_target\_group\_arn) | ARN of the target group with which to register the target. | `string` | n/a | yes |
| <a name="input_target_id"></a> [target\_id](#input\_target\_id) | Identifier of the target to register. The expected value depends on the target group's `target_type`:<br/>  - `instance` : EC2 instance ID.<br/>  - `ip`       : IP address (must fall within the VPC CIDR, RFC 1918 ranges, or 100.64.0.0/10).<br/>  - `lambda`   : Lambda function ARN.<br/>  - `alb`      : Application Load Balancer ARN. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_availability_zone"></a> [availability\_zone](#output\_availability\_zone) | Availability Zone in which the target is registered, or null when not applicable. |
| <a name="output_id"></a> [id](#output\_id) | Synthetic identifier of the target group attachment. |
| <a name="output_port"></a> [port](#output\_port) | Port on which the registered target receives traffic, or null when not applicable (e.g. `lambda` targets). |
| <a name="output_quic_server_id"></a> [quic\_server\_id](#output\_quic\_server\_id) | QUIC server ID assigned to the target, or null when the target group does not use QUIC/TCP\_QUIC. |
| <a name="output_region"></a> [region](#output\_region) | AWS region the attachment is managed in (computed from the provider configuration when `var.region` is null). |
| <a name="output_target_group_arn"></a> [target\_group\_arn](#output\_target\_group\_arn) | ARN of the target group the attachment is registered with. |
| <a name="output_target_id"></a> [target\_id](#output\_target\_id) | Identifier of the registered target. |
<!-- END_TF_DOCS -->
