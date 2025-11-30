# AWS Infrastructure Project Instructions

이 문서는 다음 모듈의 조합입니다:
- base/CLAUDE.md
- infra/aws.md
- infra/kubernetes.md
- infra/terraform.md
- infra/docker.md

---

## Base Instructions

- 한국어로 응답
- 변경사항은 이유와 함께 설명
- 인프라 변경은 영향 범위 명시
- 비용 영향 있으면 언급

## Infrastructure as Code

- Terraform으로 인프라 관리
- 모듈화하여 재사용
- 환경별 분리 (dev/staging/prod)
- State는 S3 + DynamoDB로 관리

## AWS Conventions

### Naming
```
{project}-{env}-{resource}
예: myapp-prod-vpc, myapp-dev-eks
```

### Tagging
```hcl
default_tags {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

## EKS Setup

```yaml
# ServiceAccount with IRSA
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/my-app-role
```

## Docker

- Multi-stage build 사용
- Non-root user 실행
- 이미지 크기 최소화
- 보안 스캔 통과

## Terraform Structure

```
terraform/
├── modules/
│   ├── vpc/
│   ├── eks/
│   └── rds/
└── environments/
    ├── dev/
    ├── staging/
    └── prod/
```

## Security Checklist

- [ ] IAM 최소 권한 원칙
- [ ] 보안 그룹 최소 포트
- [ ] 암호화 활성화 (at rest, in transit)
- [ ] VPC 프라이빗 서브넷 활용
- [ ] Secrets Manager 사용

## Deployment

```bash
# Terraform
terraform plan -out=tfplan
terraform apply tfplan

# K8s
kubectl apply -k overlays/prod/

# Docker
docker build -t myapp:v1.0.0 .
docker push ECR_URL/myapp:v1.0.0
```

## Troubleshooting

```bash
# EKS 연결
aws eks update-kubeconfig --name cluster-name

# Pod 디버깅
kubectl logs -f pod-name
kubectl describe pod pod-name
kubectl exec -it pod-name -- /bin/sh

# AWS 리소스 확인
aws sts get-caller-identity
aws eks describe-cluster --name cluster-name
```
