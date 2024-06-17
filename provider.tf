terraform {
  backend "s3" {
    bucket = "pjt-eshop-bucket"           # 개인이 생성한 S3 버킷의 실제 이름 ex) bucket = t3msp
    key    = "mgmt/terraform.tfstate" # mgmt 인프라의 tfstate 파일 저장 path(고정값)
    region = "us-east-1"              # S3가 존재하는 region
    skip_s3_checksum=true             # Terraform 1.6 이상부터 추가 파라메터
    skip_requesting_account_id=true   # Terraform 1.6 이상부터 추가 파라메터
  }
  required_version = ">=1.1.3"
}

provider "aws" {
  region = var.aws_region
}
