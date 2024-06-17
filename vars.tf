## Define Common variables #################################

variable "aws_region" {
  default     = null 
  type        = string
  description = "AWS region"
}

### Define EKS variables ###################################
variable "cluster_name" {
  default     = "eks-cluster"
  type        = string
  description = "eks cluster name"
}

variable "node_type" {
  default     = ["t3.medium"]
  type        = list(any)
  description = "eks cluster node type"
}

variable "node_desired_size" {
  default = 2
  type    = number
  description = "eks-node desired size"
}

variable "node_max_size" {
  default = 2
  type    = number
  description = "eks-node max size"
}

variable "node_min_size" {
  default = 2
  type    = number
  description = "eks-node desired size"
}

variable "my_ami" {
  default     = null
  type        = string
  description = "EC2 ami"
}

variable "my_keypair" {
  default     = null
  type        = string
  description = "Key Pairs"
}

variable "sg_rules" {
    description = "Security group policy definition (source security group id)"
    type = any
}