logical_product_family  = "launch"
logical_product_service = "lbatt"
class_env               = "dev"
instance_env            = 0
instance_resource       = 0

vpc_cidr    = "10.0.0.0/16"
subnet_cidr = "10.0.1.0/24"

target_ip   = "10.0.1.100"
target_port = 80

tags = {
  Environment = "test"
  ManagedBy   = "terraform"
  Module      = "tf-aws-module_primitive-lb_target_group_attachment"
}
