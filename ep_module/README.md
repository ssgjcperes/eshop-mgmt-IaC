# AWS endpoints Module

VPC에 VPC endpoints를 생성하는 모듈이며, gateway/interface type vpc endpoints를 생성할 수 있습니다.
보안권고 사항에 따라 가능한 모든 AWS Serivce와의 통신은 public network가 아닌 AWS internally private network를 통해 수행하게 설계되었습니다. 



VPC Endpoints 서비스에 대한 자세한 내용은 아래의 AWS 내용을 확인해 보시기 바랍니다.

> ✔  [`VPC endpoints`](https://docs.aws.amazon.com/ko_kr/vpc/latest/privatelink/vpc-endpoints.html) - VPC 엔드포인트를 통해 인터넷 게이트웨이, NAT 디바이스, VPN 연결 또는 AWS Direct Connect 연결이 필요 없이 Virtual Private Cloud(VPC)와 지원 서비스 간에 연결을 설정할 수 있습니다. 따라서 VPC가 퍼블릭 인터넷에 노출되지 않습니다. 



## 인프라 사전 준비사항

다음의 인프라가 사전에 설치되어 있어야만, 본 모듈을 사용하여 자원을 생성할 수 있습니다.

|    AWS 인프라    |                          간단 설명                           | Required |     사용 가능 모듈     |
| :--------------: | :----------------------------------------------------------: | :------: | :--------------------: |
|       VPC        | [사용자 정의 가상 네트워크](https://docs.aws.amazon.com/ko_kr/vpc/latest/userguide/what-is-amazon-vpc.html) |  `yes`   |      network/vpc       |
|      Subnet      | [VPC의 IP주소범위](https://docs.aws.amazon.com/ko_kr/vpc/latest/userguide/configure-subnets.html) |  `yes`   |      network/vpc       |
|   Route table    | [네트워크 트래픽 전송규칙](https://docs.aws.amazon.com/ko_kr/vpc/latest/userguide/VPC_Route_Tables.html) |  `yes`   |      network/vpc       |
| Internet Gateway | [인터넷 연결 리소스](https://docs.aws.amazon.com/ko_kr/vpc/latest/userguide/VPC_Internet_Gateway.html) |  `yes`   |      network/vpc       |
|   NAT Gateway    | [Private 서브넷의 인터넷 연결 리소스](https://docs.aws.amazon.com/ko_kr/vpc/latest/userguide/vpc-nat-gateway.html) |   `no`   |      network/vpc       |
|   Network ACL    | [네트워크 방화벽](https://docs.aws.amazon.com/ko_kr/vpc/latest/userguide/vpc-network-acls.html) |   `no`   |      network/vpc       |
|  VPC Endpoints   | [AWS private network을 통한 AWS Service접근](https://docs.aws.amazon.com/ko_kr/vpc/latest/privatelink/vpc-endpoints.html) |   `no`   |   network/endpoints    |
| Security Groups  | [Host 방화벽을 통한 접근제어](https://docs.aws.amazon.com/ko_kr/vpc/latest/userguide/VPC_SecurityGroups.html) |  `yes`   | security/securitygroup |



## 사용예시

![vpc endpoints](../docs/images/vpc_endpionts.png)

public, private-nat, private subnet에서 AWS service에 접근하기 위해 VPC endpoints를 사용, public network 대신 AWS private network을 통해 통신하게 됩니다. VPC endpoints는 두가지 type이 있는데, s3, dynamodb의 경우, gateway type endpoint를 제공하여, traffic route를 해당 gateway로 보내게 되며, 나머지 서비스의 경우, interface type endpoints([AWS private link](https://aws.amazon.com/ko/privatelink/?privatelink-blogs.sort-by=item.additionalFields.createdDate&privatelink-blogs.sort-order=desc)를 사용하여 AWS service에 접근하게 됩니다. 



위와 같은 구성에서 VPC Endpoints를 아래와 같은 코드로 생성할 수 있습니다. (※ 아래의 예시 코드에서는 이해를 돕기 위해 변수대신 값을 사용하였으며, 대부분 변수를 사용합니다.)

```yaml
module "vpc_endpoints" {
    source = "../../../modules/network/endpoints"
    vpc_id = "vpc-******"
    region_name = "ap-northeast-2"
    svc_name = "km"
    purpose = "svc"
    env = "dev"
    region_name_alias = "kr"
    gateway_endpoints = { # gateway type endpoints 설정 (현재, s3, dynamodb만 제공)
        s3 = {
            rt_ids = ["rtb-******", "rtb-******", "rtb-******"]
        }
        dynamodb = {
            rt_ids = ["rtb-******", "rtb-******", "rtb-******"]
        }
    }
    interface_endpoints = { # interface type endpoints 설정
        sqs = {
            subnet_ids = ["subnet-******", "subnet-******"]
            security_groups = ["sg-******"]
        }
        sns = {
            subnet_ids = ["subnet-******", "subnet-******"]
            sg_ids = ["sg-******"]
        }
        git-codecommit = { # AWS Code-commit vpc endpoint
            subnet_ids = ["subnet-******"]
            sg_ids = ["sg-******"]
        }
        logs = { # AWS cloudwatch logs vpc endpoint
            subnet_ids = ["subnet-******", "subnet-******"]
            sg_ids = ["sg-******"]
        }
    }
}
```

- VPC endpoints의 tag 명등은 아래의 naming rule에 따라 결정되며, 이때 svc_name, purpose, env, region_name_alias와 같은 variable들은 tag를 생성할 때 suffix로 사용된다. (ex, ep_gateway_s3_km_svc_dev_kr)

  > 1. Endpoints: ep\_[type]\_[aws service]\_[service name]\_[purpose]\_[env]\_[region] ex) ep_gateway_s3_km_svc_dev_kr

- gateway type endpoints 는 과금되지 않으나, interface type endpoints의 경우, 시간당/traffic 과금이 되므로 필요 없은 endpoint는 만들지 않아야 한다.

- gateway_endpoints, interface_endpoints 설정 시, key값은 반드시 서비스 명과 동일해야만 한다. (ex, sqs => **sqs**.amazonaws.com, sns => **sns**.amazonaws.com)

- gateway type endpoints는 route id를, interface type endpoints는 subnet id를 입력해야 한다.

- cognito (IDp)서비스의 경우, 아직 vpc endpoint를 제공하지 않는다.

  

## Requirements

| Name      | Version |
| :-------- | :-----: |
| terraform | >= 0.12 |



## Providers

| Name | Version |
| :--- | :-----: |
| aws  | >~ 4.0  |



## Resources

| Name                                                         |   Type   |
| :----------------------------------------------------------- | :------: |
| [aws_vpc_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |



## Inputs

| Name                                        | Description                                              |      Type      | Default | Required |
| :------------------------------------------ | :------------------------------------------------------- | :------------: | :-----: | :------: |
| vpc_id                                      | EC2 인스턴스를 생성할 VPC ID                             |    `string`    |         |  `yes`   |
| svc_name                                    | VPC의 사용 용도                          |    `string`    |         |  `yes`   |
| purpose                                     | VPC의 용도를 나타낼 수 있는 서비스 명 (ex, svc / mgmt)   |    `string`    |         |  `yes`   |
| env                                         | 시스템 구성 환경 (ex, dev / stg / prd)                   |    `string`    |         |  `yes`   |
| region_name_alias                           | 서비스 AWS Region alias (ex, ap-northeast-2 → kr)        |    `string`    |         |  `yes`   |
| **gateway_endpoints**                       | Gateway type vpc endpoint 정의                           |   `map(any)`   |         |  `yes`   |
| **gateway_endpoints**.rt_ids                | Gateway type vpc endpoints가 속할 routing table IDs      | `list(string)` |         |  `yes`   |
| **gateway_endpoints**.policy                | Gateway type vpc endpoints에 접근할 접근 policy          |    `string`    | `null`  |   `no`   |
| **interface_endpoints**                     | Interface type vpc endpoint 정의                         |   `map(any)`   |         |  `yes`   |
| **interface_endpoints**.subnet_ids          | Interface type vpc endpoints가 속할 subnet IDs           | `list(string)` |         |  `yes`   |
| **interface_endpoints**.policy              | Interface type vpc endpoints에 접근할 접근 policy        |    `string`    | `null`  |   `no`   |
| **interface_endpoints**.security_groups     | Interface type vpc endpoints에 할당할 security group IDs | `list(string)` |         |  `yes`   |
| **interface_endpoints**.private_dns_enabled | VPC endpoint interface에 대해 private dns 적용 여부      |     `bool`     | `false` |   `no`   |

### 참고
------
`gateway_endpoints` - gateway_endpoints input variable은 아래와 같은 구조로 구성되어 있다. (실제 variable type은 any이나 아래와 같은 구조로 사용됨을 참고)
```yaml
type = map(object({
    rt_ids = list(string) #(Required)
    policy = string #(Optional) default: null
}))
```

`interface_endpoints` - interface_endpoints input variable은 아래와 같은 구조로 구성되어 있다. (실제 variable type은 any이나 아래와 같은 구조로 사용됨을 참고)
```yaml
type = map(object({
    subnet_ids = list(string) #(Required)
    sg_ids = list(string) #(Required)
    policy = string #(Optional) default: null
    private_dns_enabled = bool #(Optional) default: false
}))
```



## Outputs

| Name                            | Description                                                  |
| :------------------------------ | :----------------------------------------------------------- |
| gateway_endpoint_id_map         | gateway endpoint 이름, ID 매핑 테이블 { "dynamodb" = "vpce-0297d318bfdcf1982", "s3" = "vpce-0fb9c89ff8dc7b189" } |
| gateway_endpoint_cidr_map       | gateway endpoint 이름, CIDR 매핑 테이블                      |
| gateway_endpoint_prefixlist_map | gateway endpoint 이름, prefix list ID매핑 테이블             |
| interface_endpoint_id_map       | interface endpoint 이름, ID 매핑 테이블 { "logs" = "vpce-086355f866df249cb", "sns" = "vpce-020a3b664d406e700" } |
| interface_endpoint_dns_map      | interface endpoint 이름, DNS 매핑 테이블                     |
| interface_endpoint_if_map       | interface endpoint 이름, Network interface list 매핑 테이블  |