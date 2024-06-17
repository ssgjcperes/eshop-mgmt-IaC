/*  Resource Naming rule
    Endpoints: ep_[type]_[aws service]_[service name]_[purpose]_[env]_[region] ex) ep_gateway_s3_dks_svc_prod_kr
*/
terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 4.0"
        }
    }
}

locals {
    svc_name = lower(var.svc_name)
    purpose = lower(var.purpose)
    env = lower(var.env)
    region_name_alias = lower(var.region_name_alias)
    region_name = lower(var.region_name)
    suffix = "${local.svc_name}_${local.purpose}_${local.env}_${local.region_name_alias}"
}

### vpc endpoints ###
# S3 gateway vpc endpoint
resource "aws_vpc_endpoint" "gateway" {
    for_each = var.gateway_endpoints
    vpc_id = var.vpc_id
    vpc_endpoint_type = "Gateway"
    auto_accept = true
    service_name = "com.amazonaws.${var.region_name}.${each.key}"
    
    route_table_ids = each.value.rt_ids
    policy = lookup(each.value, "policy", null)
    # private_dns_enabled = lookup(each.value, "private_dns_enabled", true) # only for interface type vpc endpoints
    tags = {
        # Naming rule: ep_[type]_[aws service]_[service name]_[purpose]_[env]_[region] ex) ep_gateway_s3_dks_svc_prod_kr *epg: endpoint gateway type
        Name = format("ep_gw_%s_%s", each.key, local.suffix)
    }
}

resource "aws_vpc_endpoint" "interface" {
    for_each = var.interface_endpoints
    vpc_id = var.vpc_id
    vpc_endpoint_type = "Interface"
    auto_accept = true
    service_name = "com.amazonaws.${var.region_name}.${each.key}"
    
    subnet_ids = each.value.subnet_ids
    security_group_ids = each.value.security_groups
    policy = lookup(each.value, "policy", null)
    private_dns_enabled = lookup(each.value, "private_dns_enabled", true)
    tags = {
        # Naming rule: ep_[type]_[aws service]_[service name]_[purpose]_[env]_[region] ex) ep_gateway_s3_dks_svc_prod_kr *epg: endpoint gateway type
        Name = format("ep_if_%s_%s", each.key, local.suffix)
    }
}

# data "aws_network_interface" "interface" {
#     for_each = merge([for k, v in aws_vpc_endpoint.interface : 
#                      {for id in v.network_interface_ids : "${k}^${id}" => id }]...)
#     id = each.value
#     depends_on = [aws_vpc_endpoint.interface]
# }