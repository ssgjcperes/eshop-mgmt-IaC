# AWS securitygroup Module

AWS의 Security Group(Host Firewall)을 관리하는 모듈입니다.<br>본 모듈에서는 Security Group의 설정 가독성을 높이기 위해 map의 형태로 in/outbound policy를 통합해서 설정/관리합니다.

Security Group에 대한 자세한 내용은 아래의 AWS 문서를 참고하도록 합니다. <br>

> ✔  [`AWS SecurityGroup`](https://docs.aws.amazon.com/ko_kr/vpc/latest/userguide/VPC_SecurityGroups.html) - 보안 그룹은 EC2 인스턴스가 인바운드 및 아웃바운드 트래픽을 제어하는 가상 방화벽 역할을 합니다. 
> VPC에서 EC2 인스턴스를 시작할 때 최대 5개의 보안 그룹에 인스턴스를 할당할 수 있습니다. 
> 보안 그룹은 서브넷 수준이 아니라 인스턴스 수준에서 작동하므로 VPC에 있는 서브넷의 각 인스턴스를 서로 다른 보안 그룹 세트에 할당할 수 있습니다. 



## 인프라 사전 준비사항

다음의 인프라가 사전에 설치되어 있어야만, 본 모듈을 사용하여 자원을 생성할 수 있습니다.

|    AWS 인프라    |                          간단 설명                           | Required | 사용 가능 모듈 |
| :--------------: | :----------------------------------------------------------: | :------: | :------------: |
|       VPC        | [사용자 정의 가상 네트워크](https://docs.aws.amazon.com/ko_kr/vpc/latest/userguide/what-is-amazon-vpc.html) |  `yes`   |  network/vpc   |
|      Subnet      | [VPC의 IP주소범위](https://docs.aws.amazon.com/ko_kr/vpc/latest/userguide/configure-subnets.html) |  `yes`   |  network/vpc   |
|   Route table    | [네트워크 트래픽 전송규칙](https://docs.aws.amazon.com/ko_kr/vpc/latest/userguide/VPC_Route_Tables.html) |  `yes`   |  network/vpc   |
| Internet Gateway | [인터넷 연결 리소스](https://docs.aws.amazon.com/ko_kr/vpc/latest/userguide/VPC_Internet_Gateway.html) |  `yes`   |  network/vpc   |

security group은 EC2, EKS, RDS, ELB등 다양한 AWS Service에 보안을 위해 적용할 수 있습니다.



## 사용예시

security groups를 아래와 같은 코드로 생성할 수 있습니다. (※ 아래의 예시 코드에서는 이해를 돕기 위해 변수대신 값을 사용하였으며, 대부분 변수를 사용합니다.)

```yaml
module "sg" {
    source = "../../../modules/security/securitygroup"
    # should use count variable to use "*""
    vpc_id = "******"
    svc_name = "km"
    purpose = "svc"
    env = "dev"
    region_name_alias = "kr"
    sg_rules = var.sg_rules
}
```

- svc_name, purpose, env, region_name_alias와 같은 variable들은 tag를 생성할 때 suffix로 사용됩니다.

  > Name: [type]\_[name]\_[svc_name]\_[purpose]\_[env]\_[region] ex) se_common_dks_svc_prod_kr
  >
  > \[type\]: se: EC2, sl: Loadbalancer, sr: RDS, sc: ElastiCache, sf: EFS, ss: Security(HSM), sk: EKS

- sg_rule은 json형태의 variable로 정의가 되며, Input 항목을 참고하기 바랍니다.



## Requirements

| Name      | Version |
| :-------- | :-----: |
| terraform | >= 0.12 |



## Providers

| Name | Version |
| :--- | :-----: |
| aws  | >= 3.72 |



## Resources

| Name                                                         |   Type   |
| :----------------------------------------------------------- | :------: |
| [aws_security_group](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |



## Inputs

| Name                                     | Description                                                  |      Type      | Default | Required |
| :--------------------------------------- | :----------------------------------------------------------- | :------------: | :-----: | :------: |
| vpc_id                                   | EC2 인스턴스를 생성할 VPC ID                                 |    `string`    |         |  `yes`   |
| svc_name                                 | VPC의 사용 용도                               |    `string`    |         |  `yes`   |
| purpose                                  | VPC의 용도를 나타낼 수 있는 서비스 명 (ex, svc / mgmt)       |    `string`    |         |  `yes`   |
| env                                      | 시스템 구성 환경 (ex, dev / stg / prod)                      |    `string`    |         |  `yes`   |
| region_name_alias                        | 서비스 AWS Region alias (ex, ap-northeast-2 → kr)            |    `string`    |         |  `yes`   |
| **sg_rules**                             | Security Group 정의                                          |     `any`      |         |  `yes`   |
| **sg_rules**.type                        | Security group type ("EC2: se, ELB: sl ...")                 |    `string`    |         |  `yes`   |
| **sg_rules**.description                 | Security group description                                   |    `string`    |         |  `yes`   |
| **sg_rules**.*ingresses*                 | Security Group의 inbound rule 정의                           | `list(object)` |         |  `yes`   |
| **sg_rules**.*ingresses*.<br>from        | inbound rule의 from port                                     |    `number`    |         |  `yes`   |
| **sg_rules**.*ingresses*.<br>to          | inbound rule의 to port                                       |    `number`    |         |  `yes`   |
| **sg_rules**.*ingresses*.<br>proto       | inbound rule의 protocol                                      |    `string`    |         |  `yes`   |
| **sg_rules**.*ingresses*.<br>cidrs       | inbound rule의 source IP Address 대역 (sg_name과 exclusive)  | `list(string)` | `null`  |   `no`   |
| **sg_rules**.*ingresses*.<br/>sg_name    | inbound rule의 source security group을 설정                  |    `string`    | `null`  |   `no`   |
| **sg_rules**.*ingresses*.<br/>sg_id      | inbound rule의 source security group ID를 설정               |    `string`    | `null`  |   `no`   |
| **sg_rules**.*ingresses*.<br>description | inbound rule의 description                                   |    `string`    | `null`  |   `no`   |
| **sg_rules**.*egresses*                  | Security Group의 outbound rule 정의                          | `list(object)` |         |  `yes`   |
| **sg_rules**.*egresses*.<br>from         | outbound rule의 from port                                    |    `number`    |         |  `yes`   |
| **sg_rules**.*egresses*.<br>to           | outbound rule의 to port                                      |    `number`    |         |  `yes`   |
| **sg_rules**.*egresses*.<br>proto        | outbound rule의 protocol                                     |    `string`    |         |  `yes`   |
| **sg_rules**.*egresses*.<br>cidrs        | outbound rule의 source IP Address 대역 (sg_name과 exclusive) | `list(string)` | `null`  |   `no`   |
| **sg_rules**.*egresses*.<br/>sg_name     | outbound rule의 source security group을 설정                 |    `string`    | `null`  |   `no`   |
| **sg_rules**.*egresses*.<br/>sg_id       | outbound rule의 source security group ID를 설정              |    `string`    | `null`  |   `no`   |
| **sg_rules**.*egresses*.<br>description  | outbound rule의 description                                  |    `string`    | `null`  |   `no`   |

### 참고

------

**`sg_rules.type`** - AWS Resource에 대해 다음과 같이 type이 정의 되어 있다.

| Type |    Resource name    |
| :--: | :-----------------: |
|  se  |         EC2         |
|  sl  |         ELB         |
|  sr  |         RDS         |
|  sc  | ElastiCache (Redis) |
|  sf  |         EFS         |
|  ss  |     CloudHSMv2      |
|  sk  |         EKS         |
|  sp  |    VPC Endpoints    |

**`sg_rules`** - sg_rules input variable은 아래와 같은 구조로 구성되어 있다. (실제 variable type은 any이나 아래와 같은 형식으로 사용됨을 참조)

```yaml
type = map(object({
    type = string #(Required)
    description = string #(Required)
    ingresses = list(object({
        from = number #(Required)
        to = number #(Required)
        proto = string #(Required)
        cidrs = list(string) #(Optional)
        sg_name = string #(Optional)
        sg_id = string #(Optional)
        description = string #(Optional)
    }))
    egresses = list(object({
        from = number #(Required)
        to = number #(Required)
        proto = string #(Required)
        cidrs = list(string) #(Optional)
        sg_name = string #(Optional)
        sg_id = string #(Optional)
        description = string #(Optional)
    }))
}))
```

**`example of sg_rules`**

```
sg_rules = {
    bastion = {
        type = "se"
        description = "bastion server security group"
        ingresses = [
            {
                from = 2022
                to = 2022
                proto = "tcp"
                cidrs = ["***.***.***.*/24","***.***.***.*/24"]
                description = "HQ_SSH"
            }
        ]
        egresses = [
            {
                from = 443
                to = 443
                proto = "tcp"
                cidrs = ["0.0.0.0/0"]
                description = "Internet_HTTPS"
            },
            {
                from = 5306
                to = 5306
                proto = "tcp"
                sg_name = "rds"
                description = "RDS_MySQL"
            },
            {
                from = 8379
                to = 8379
                proto = "tcp"
                sg_name = "redis"
                description = "ElastiCache_Redis"
            },
            {
                from = 443
                to = 443
                proto = "tcp"
                sg_name = "eks"
                description = "EKS_APIServer"
            },
            {
                from = 22
                to = 22
                proto = "tcp"
                sg_name = "eks"
                description = "EKSNode_SSH"
            }
        ]
    },
    common = {
        type = "se"
        description = "common security group"
        ingresses = []
        egresses = []
    }
    rds = {
        type = "sr"
        description = "RDS security group"
        ingresses = [
            {
                from = 5306
                to = 5306
                proto = "tcp"
                sg_name = "bastion"
                description = "Bastion_MySQL"
            },
            {
                from = 5306
                to = 5306
                proto = "tcp"
                sg_name = "eks"
                description = "EKSNode_MySQL"
            }
        ]
        egresses = []
    },
    redis = {
        type = "sc"
        description = "ElastiCache security group"
        ingresses = [
            {
                from = 8379
                to = 8379
                proto = "tcp"
                sg_name = "bastion"
                description = "Bastion_Redis"
            },
            {
                from = 8379
                to = 8379
                proto = "tcp"
                sg_name = "eks"
                description = "EKSNode_Redis"
            }
        ]
        egresses = []
    },
    eks = {
        type = "sk"
        description = "EKS security group"
        ingresses = [
            {
                from = 22
                to = 22
                proto = "tcp"
                sg_name = "bastion"
                description = "Bastion_SSH"
            },
            {
                from = 443
                to = 443
                proto = "tcp"
                sg_name = "bastion"
                description = "Bastion_APIServer"
            },
            {
                from = 8080
                to = 8080
                proto = "tcp"
                sg_name = "sa"
                description = "ELB-sa_EKSWorkers"
            }
        ]
        egresses = [
            {
                from = 5306
                to = 5306
                proto = "tcp"
                sg_name = "rds"
                description = "RDS_MySQL"
            },
            {
                from = 8379
                to = 8379
                proto = "tcp"
                sg_name = "redis"
                description = "ElastiCache_Redis"
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
                cidrs = ["10.1.0.0/16"]
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
    },
    sa = {
        type = "sl"
        description = "ELB Security Group"
        ingresses = [
            {
                from = 443
                to = 443
                proto = "tcp"
                cidrs = ["0.0.0.0/0"]
                description = "Device_HTTPS"
            }
        ]
        egresses = [
            {
                from = 8080
                to = 8080
                proto = "tcp"
                sg_name = "eks"
                description = "ELB-sa_EKSWorkers"
            }
        ]
    }
}
```



## Outputs

| Name      | Description                                                  |
| :-------- | :----------------------------------------------------------- |
| sg_id_map | Security group name 과 ID의 mapping table ex) {"bastion" : "sg-01ac289f11a139ae5" ...} |
