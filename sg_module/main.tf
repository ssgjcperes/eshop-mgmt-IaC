/*  Default security groups for Default VPC (common, bastion, deploy)
    Resource Naming rule
    SecurityGroup: se_[name]_[svc_name]_[purpose]_[env]_[region] ex) se_common_dks_svc_prod_kr
    (se: EC2, sl: Loadbalancer, sr: RDS, sc: ElastiCache, sf: EFS, ss: Security(HSM), sk: EKS)
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
    suffix = "${local.svc_name}_${local.purpose}_${local.env}_${local.region_name_alias}"
    
    sg_ingress_rules = flatten([
        for name in keys(var.sg_rules) : [
            for ingress in var.sg_rules[name].ingresses : {
                "name" = name
                "rule" = ingress
            } # if lookup(ingress, "sg_name", null) != null
        ]
    ])
    
    sg_egress_rules = flatten([
        for name in keys(var.sg_rules) : [
            for egress in var.sg_rules[name].egresses : {
                "name" = name
                "rule" = egress
            } # if lookup(egress, "sg_name", null) != null
        ]
    ])
}

resource "aws_security_group" "main" {
    for_each = var.sg_rules
    
    name = lookup(each.value, "name", "${each.value.type}_${each.key}_${local.suffix}")
    #timestamp recreate security group whenever refresh same code
    #description = format("%s security group created at %s", each.value.description, formatdate("YY-MM-DD hh:mm(ZZZ)", timestamp()))
    description = each.value.description
    vpc_id = var.vpc_id
    /* 아래의 dynamic ingress 코드랑, aws_security_group_rule을 같이 쓰면, 매번 replace 되므로 주의한다.
       아래의 dynamic code는 사용하지 않는게 좋다. */
    /*   
    dynamic ingress {
        for_each = [ for k in each.value.ingresses : k if lookup(k, "cidrs", null) != null ]
        content {
            description = ingress.value.description
            from_port = ingress.value.from
            to_port = ingress.value.to
            protocol = ingress.value.proto
            cidr_blocks = ingress.value.cidrs
        }
    }
    dynamic egress {
        for_each = [ for k in each.value.egresses : k if lookup(k, "cidrs", null) != null ]
        content {
            description = egress.value.description
            from_port = egress.value.from
            to_port = egress.value.to
            protocol = egress.value.proto
            cidr_blocks = egress.value.cidrs
        }
    }
    */
    tags = merge({
        Name = format("%s_%s_%s", each.value.type, each.key, local.suffix)
    }, lookup(each.value, "tags", {}))
}

resource "aws_security_group_rule" "ingress" {
    #The ... modifier after that outer expression tells Terraform to pass each element of that outer tuple as a separate argument to merge
    #terraform tip, 만일 for_each에 flatten으로 list를 사용하게 되는 경우, 내용이 1개라도 변경되면, list index의 위치가 바뀌기 때문에, 모두 replace되는 단점이 있음.
    #foe_each는 가급적, map의 형태로 사용해야 나중에 replace를 최소화 할 수 있다.
    #for문에 기본적으로 index를 받아 올 수 있음. for idx, egress in rule.egresses => 변수만 설정해 주면 enumeration정보를 받아 올 수 있다.
    #idx를 사용하더라도, 순번이기 때문에, 설정에서 순번이 바뀌는 경우, 순번을 맞추기 위해서, 전체를 재 생성하는 문제가 발생함
    #결국, 고유한 key를 사용해서 관리해야만 한다.
    #key에 ip address list가 포함되는데, ip address가 아주 많아지면 key가 극단적으로 커지므로, md5 hash를 통해 일정 길이의 key로 만들어준다. => 나중에 문제 생기면 적용하자.
    for_each = merge([ for sg_name, rule in var.sg_rules: 
                            { for idx, ingress in rule.ingresses :
                                format("%s^in^%s^%s-%s^%s", sg_name, ingress.proto, ingress.from, ingress.to, lookup(ingress,"cidrs",null) != null ?
                                    join(",", ingress.cidrs) : lookup(ingress,"sg_name",null) != null ? ingress.sg_name : ingress.sg_id) => ingress }
                     ]...)
    security_group_id = aws_security_group.main[split("^", each.key)[0]].id
    type = "ingress"
    #timestamp recreate security group whenever refresh same code
    #description = format("%s_%s", formatdate("YYMMDD(ZZZ)", timestamp()), local.sg_ingress_rules[count.index].rule.description)
    description = each.value.description
    from_port = each.value.from
    to_port = each.value.to
    protocol = each.value.proto
    ipv6_cidr_blocks = null
    prefix_list_ids = null
    cidr_blocks = lookup(each.value, "cidrs", null) != null ? each.value.cidrs : null
    source_security_group_id = (
        lookup(each.value, "sg_name", null) != null ? aws_security_group.main[each.value.sg_name].id : 
        lookup(each.value, "sg_id", null) != null ? each.value.sg_id : null
    )
    depends_on = [aws_security_group.main]

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_security_group_rule" "egress" {
    #The ... modifier after that outer expression tells Terraform to pass each element of that outer tuple as a separate argument to merge
    #terraform tip, 만일 for_each에 flatten으로 list를 사용하게 되는 경우, 내용이 1개라도 변경되면, list index의 위치가 바뀌기 때문에, 모두 replace되는 단점이 있음.
    #foe_each는 가급적, map의 형태로 사용해야 나중에 replace를 최소화 할 수 있다.
    #for문에 기본적으로 index를 받아 올 수 있음. for idx, egress in rule.egresses => 변수만 설정해 주면 enumeration정보를 받아 올 수 있다.
    #idx를 사용하더라도, 순번이기 때문에, 설정에서 순번이 바뀌는 경우, 순번을 맞추기 위해서, 전체를 재 생성하는 문제가 발생함
    #결국, 고유한 key를 사용해서 관리해야만 한다.
    #key에 ip address list가 포함되는데, ip address가 아주 많아지면 key가 극단적으로 커지므로, md5 hash를 통해 일정 길이의 key로 만들어준다. => 나중에 문제 생기면 적용하자.
    for_each = merge([ for sg_name, rule in var.sg_rules:
                            { for idx, egress in rule.egresses : 
                                format("%s^out^%s^%s-%s^%s", sg_name, egress.proto, egress.from, egress.to, lookup(egress,"cidrs",null) != null ?
                                    join(",", egress.cidrs) : lookup(egress,"sg_name",null) != null ? egress.sg_name : egress.sg_id ) => egress }
                     ]...)
    security_group_id = aws_security_group.main[split("^", each.key)[0]].id
    type = "egress"
    #timestamp recreate security group whenever refresh same code
    #description = format("%s_%s", formatdate("YYMMDD_ZZZ", timestamp()), local.sg_egress_rules[count.index].rule.description)
    description = each.value.description
    from_port = each.value.from
    to_port = each.value.to
    protocol = each.value.proto
    ipv6_cidr_blocks = null
    prefix_list_ids = null
    cidr_blocks = lookup(each.value, "cidrs", null) != null ? each.value.cidrs : null
    source_security_group_id = (
        lookup(each.value, "sg_name", null) != null ? aws_security_group.main[each.value.sg_name].id : 
        lookup(each.value, "sg_id", null) != null ? each.value.sg_id : null
    )
    depends_on = [aws_security_group.main]
    
    lifecycle {
        create_before_destroy = true
    }
}