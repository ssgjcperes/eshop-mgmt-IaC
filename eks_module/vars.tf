variable "cluster_name"      {}
variable "node_type"         {}
variable "vpc_id"            {}
variable "subnet_id1"        {}
variable "subnet_id2"        {}
variable "node_desired_size" {}
variable "node_max_size"     {}
variable "node_min_size"     {}
variable "aws_region"        {}
variable "endpoint_private_access" {
    description = "Whether the Amazon EKS private API server endpoint is enabled"
    type = bool
    default = true
}

variable "endpoint_public_access" {
    description = "Whether the Amazon EKS public API server endpoint is enabled"
    type = bool
    default = false
}

variable "public_access_cidrs" {
    description = "List of CIDR blocks. Indicates which CIDR blocks can access the Amazon EKS public API server endpoint"
    type = list(string)
    default = []
}