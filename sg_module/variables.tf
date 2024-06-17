variable "vpc_id" {
    description = "VPC id"
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

variable "sg_rules" {
    description = "Security group policy definition"
    type = any
    /*
    type = map(object({
        type = string
        name = string
        description = string
        ingresses = list(object({
            from = number
            to = number
            proto = string
            cidrs = list(string)
            sg_name = string # security group alias name
            sg_id = string # security group ID
            description = string
        }))
        egresses = list(object({
            from = number
            to = number
            proto = string
            cidrs = list(string)
            sg_name = string # security group alias name
            sg_id = string # security group ID
            description = string
        }))
    }))
    */
}
