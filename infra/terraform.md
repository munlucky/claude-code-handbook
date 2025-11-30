# Terraform

## Project Structure

```
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   └── prod/
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── eks/
│   ├── rds/
│   └── s3/
└── shared/
    └── versions.tf
```

## Basic Structure

```hcl
# versions.tf
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# backend.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "env/dev/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# provider.tf
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.project_name
    }
  }
}
```

## Variables

```hcl
# variables.tf
variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

# terraform.tfvars
environment     = "dev"
vpc_cidr        = "10.0.0.0/16"
private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
tags = {
  Team = "platform"
}
```

## Module 작성

```hcl
# modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-private-${count.index + 1}"
    Type = "private"
  })
}

# modules/vpc/variables.tf
variable "name" {
  description = "VPC name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}

# modules/vpc/outputs.tf
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}
```

## Module 사용

```hcl
# main.tf
module "vpc" {
  source = "../../modules/vpc"

  name               = "${var.project_name}-${var.environment}"
  vpc_cidr           = var.vpc_cidr
  private_subnets    = var.private_subnets
  availability_zones = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
  
  tags = var.tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name   = "${var.project_name}-${var.environment}"
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  
  depends_on = [module.vpc]
}
```

## Data Sources & Locals

```hcl
# 기존 리소스 참조
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Locals
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
  
  name_prefix = "${var.project_name}-${var.environment}"
}
```

## Outputs

```hcl
# outputs.tf
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
  sensitive   = false
}

output "db_password" {
  description = "Database password"
  value       = random_password.db.result
  sensitive   = true
}
```

## Useful Commands

```bash
# 초기화
terraform init
terraform init -upgrade  # provider 업데이트

# 계획
terraform plan
terraform plan -out=tfplan  # 계획 저장
terraform plan -target=module.vpc  # 특정 모듈만

# 적용
terraform apply
terraform apply tfplan  # 저장된 계획 적용
terraform apply -auto-approve  # CI/CD용

# 상태 관리
terraform state list
terraform state show aws_vpc.main
terraform state mv aws_vpc.old aws_vpc.new
terraform state rm aws_vpc.main  # 상태에서 제거 (리소스 유지)

# 삭제
terraform destroy
terraform destroy -target=aws_instance.example

# 포맷 & 검증
terraform fmt -recursive
terraform validate
tflint --recursive

# Import (기존 리소스)
terraform import aws_vpc.main vpc-12345678
```
