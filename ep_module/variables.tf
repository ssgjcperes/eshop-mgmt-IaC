variable "region_name" {
    description = "AWS VPC region name"
    type = string 
}

variable "vpc_id" {
    description = "VPC ID"
    type = string
}

variable "svc_name" {
    description = "Service name"
    type = string
}

variable "purpose" {
    description = "VPC purpose"
    type = string
}

variable "env" {
    description = "Stage (dev, stg, prod etc)"
    type = string
}

variable "region_name_alias" {
    description = "AWS VPC region name alias like KR"
    type = string
}

variable "gateway_endpoints" {
    description = "VPC gateway Endpoints"
    /*
    type = map(object({
        rt_ids = list(string)
        policy = string
    }))
    */
    type = any
    default = {}
}

variable "interface_endpoints" {
    description = "VPC interface Endpoints"
    /*
    type = map(object({
        subnet_ids = list(string)
        security_groups = list(string)
        policy = string
        private_dns_enabled = bool
    }))
    */
    type = any
    default = {}
}