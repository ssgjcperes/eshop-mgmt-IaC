
module "vpc" {
  source          = "./vpc_module"
  cluster_name    = var.cluster_name
}

module "sg" {
    source = "./sg_module"
    # should use count variable to use "*""
    vpc_id = module.vpc.vpc_id
    svc_name = "eshop"
    purpose = "t3"
    env = "dev"
    region_name_alias = "us"
    sg_rules = var.sg_rules
}

module "vpc_endpoints" {
    source = "./ep_module"
    vpc_id = module.vpc.vpc_id
    region_name = var.aws_region
    svc_name = "eshop"
    purpose = "t3"
    env = "dev"
    region_name_alias = "us"
    
    interface_endpoints = {
        # sns = {
        #     subnet_ids = module.vpc.privnat_subnet_ids
        #     security_groups = [module.sg.sg_id_map["endpoints"]]
        # }
        # logs = { # AWS cloudwatch logs vpc endpoint
        #     subnet_ids = module.vpc.privnat_subnet_ids
        #     security_groups = [module.sg.sg_id_map["endpoints"]]
        # }
        autoscaling = { # AWS autoscaling vpc endpoint AWS Console <----> EKS autoscaler controller
            subnet_ids = module.vpc.private_subnet_id
            security_groups = [module.sg.sg_id_map["endpoints"]]
        }
        # elasticloadbalancing = { # ELB vpc endpoint
        #     subnet_ids = module.vpc.private_subnet_id
        #     security_groups = [module.sg.sg_id_map["endpoints"]]
        # }
    }
}


module "eks" {
  
  depends_on = [module.vpc_endpoints]

  source = "./eks_module"

  cluster_name      = var.cluster_name
  node_type         = var.node_type
  node_desired_size = var.node_desired_size
  node_max_size     = var.node_max_size
  node_min_size     = var.node_min_size
  aws_region        = var.aws_region

  vpc_id     = module.vpc.vpc_id
  subnet_id1 = module.vpc.private_subnet_id[0]
  subnet_id2 = module.vpc.private_subnet_id[1]

  endpoint_private_access = true
  endpoint_public_access = true
  #EKS API Server로 My IP 및 MGMT VPC내 생성된 Nat Gateway의 IP를 public ACL에 허용한다.
  #public_access_cidrs = ["${chomp(data.http.get_my_public_ip.response_body)}/32", "${chomp(module.vpc.nat_gateway_ip)}/32"]
  #EKS API Server로 My IP를 public ACL에 허용한다.
  public_access_cidrs = ["${chomp(data.http.get_my_public_ip.response_body)}/32"]
}

resource aws_instance "bastion" {
  
  depends_on = [
    module.vpc,
    module.eks
  ]
  
  #ami             = var.my_ami                           #기본적으로 미사용 수동으로 AMI ID 값을 지정할 때 사용
  ami             = data.aws_ami.ubuntu_linux.image_id    #최신 AMI ID 동적할당
  instance_type   = "t2.micro"
  subnet_id       = module.vpc.public_subnet_id[0]
  security_groups = [aws_security_group.bastion_sg.id]
  key_name    = var.my_keypair

  tags = {
    Name = "eshop-bastion" 
  }

  lifecycle { ignore_changes = [security_groups] }
}


resource aws_instance "admin" {
  
  depends_on = [
    module.vpc,
    module.eks,
    aws_instance.bastion
  ]

  #ami             = var.my_ami                           #기본적으로 미사용 수동으로 AMI ID 값을 지정할 때 사용
  ami             = data.aws_ami.ubuntu_linux.image_id    #최신 AMI ID 동적할당
  instance_type   = "t2.micro"
  subnet_id       = module.vpc.private_subnet_id[0]
  security_groups = [aws_security_group.admin_sg.id]
  key_name    = var.my_keypair

  lifecycle { ignore_changes = [security_groups] }

  user_data = <<EOF
#!/bin/bash

# tree install                                                                                                          
sudo apt update
sudo apt install -y tree

# unzip install
sudo apt update
sudo apt install -y unzip

# awscli install
sudo apt update
sudo apt install -y awscli

# terraform install
# curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
# sudo apt-add-repository -y "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
# sudo apt install -y terraform

### kubectl install
mkdir /home/ubuntu/bin
curl -o /home/ubuntu/bin/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.23.15/2023-01-11/bin/linux/amd64/kubectl
chmod +x /home/ubuntu/bin/kubectl

### helm install
curl -L https://git.io/get_helm.sh | bash -s -- --version v3.8.2

### argocd cli install
curl --silent --location -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.4.28/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

echo 'alias cls=clear' >> /home/ubuntu/.bashrc
echo 'export PATH=$PATH:/home/ubuntu/bin' >> /home/ubuntu/.bashrc

echo 'source <(kubectl completion bash)' >> /home/ubuntu/.bashrc
echo 'alias k=kubectl' >> /home/ubuntu/.bashrc
echo 'complete -F __start_kubectl k' >> /home/ubuntu/.bashrc

# alias 추가
echo 'alias mc="kubectl config use-context mgmt"' >> /home/ubuntu/.bashrc
echo 'alias ec="kubectl config use-context eshop"' >> /home/ubuntu/.bashrc
echo 'alias ef="kubectl config use-context eshop-fg"' >> /home/ubuntu/.bashrc

# WhereAmI
echo 'alias wai="kubectl config get-contexts"' >> /home/ubuntu/.bashrc

EOF

  tags = {
    Name = "eshop-admin"
  }
}


resource "aws_security_group" "bastion_sg" {
  name        = "eshop_mgmt_bastion_sg"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eshop_mgmt_bastion_sg"
  }
}

resource "aws_security_group" "admin_sg" {
  name        = "eshop_mgmt_admin_sg"
  description = "admin server sg"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eshop_mgmt_admin_sg"
  }
}

data "http" "get_my_public_ip" {
  url = "https://ifconfig.me"
}

#최신 AMI ID 동적할당
data "aws_ami" "ubuntu_linux" {

  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_security_group_rule" "bastion-ssh-myip" {
  description       = "my public ip"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"

  cidr_blocks       = ["${chomp(data.http.get_my_public_ip.response_body)}/32"] 
  security_group_id = aws_security_group.bastion_sg.id
}

# resource "aws_security_group_rule" "bastion-ssh-office" {
#   description       = "office"
#   type              = "ingress"
#   from_port         = 22
#   to_port           = 22
#   protocol          = "TCP"

#   cidr_blocks       = ["121.133.133.0/24", "221.167.219.0/24"] 
#   security_group_id = aws_security_group.bastion_sg.id
# }

resource "aws_security_group_rule" "bastion-ssh-us-east-1" {

  count = var.aws_region == "us-east-1" ? 1 : 0

  description       = "AWS EC2_INSTANCE_CONNECT - us-east-1"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"

  cidr_blocks       = ["18.206.107.24/29"] 
  security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "bastion-ssh-us-west-2" {

  count = var.aws_region == "us-west-2" ? 1 : 0

  description       = "AWS EC2_INSTANCE_CONNECT - us-west-2"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"

  cidr_blocks       = ["18.237.140.160/29"] 
  security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "bastion-ssh-ap-northeast-2" {

  count = var.aws_region == "ap-northeast-2" ? 1 : 0

  description       = "AWS EC2_INSTANCE_CONNECT - ap-northeast-2"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"

  cidr_blocks       = ["13.209.1.56/29"] 
  security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "admin-ssh" {
  description              = "from bastion server"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "TCP"
  security_group_id        = aws_security_group.admin_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "admin-argo-rollout" {
  description              = "from bastion server"
  type                     = "ingress"
  from_port                = 3100
  to_port                  = 3100
  protocol                 = "TCP"
  security_group_id        = aws_security_group.admin_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "admin-peering" {
  description              = "from service cluster subnet"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "TCP"
  cidr_blocks              = ["192.168.0.0/24"]
  security_group_id        = aws_security_group.admin_sg.id
}