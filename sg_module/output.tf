output "sg_id_map" {
    value = { for k, v in aws_security_group.main :  k => v.id }
}