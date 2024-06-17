sg_rules = {
    common = {
        type = "se"
        description = "common security group"
        ingresses = []
        egresses = [
            {
                from = 443
                to = 443
                proto = "tcp"
                cidrs = ["0.0.0.0/0"]
                description = "Anyopen_HTTPS"
            }
        ]
    },
    endpoints = {
        type = "sp"
        description = "VPC interface endpoints security group"
        ingresses = [
            {
                from = 443
                to = 443
                proto = "tcp"
                cidrs = ["10.0.0.0/16"]
                description = "VPC-subnet_HTTPS"
            }
        ]
        egresses = [
            {
                from = 0
                to = 0
                proto = "-1"
                cidrs = ["0.0.0.0/0"]
                description = "VPC-subnet_ALL"
            }
        ]
    }
}