# AWS

## IAM Best Practices

```json
// 최소 권한 원칙
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::my-bucket/uploads/*"
    }
  ]
}

// 조건부 권한
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-2"
        }
      }
    }
  ]
}
```

## EKS IRSA (IAM Roles for Service Accounts)

```yaml
# 1. IAM Role Trust Policy
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT:oidc-provider/oidc.eks.REGION.amazonaws.com/id/CLUSTER_ID"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.REGION.amazonaws.com/id/CLUSTER_ID:sub": "system:serviceaccount:NAMESPACE:SERVICE_ACCOUNT",
          "oidc.eks.REGION.amazonaws.com/id/CLUSTER_ID:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}

# 2. ServiceAccount annotation
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/my-app-role
```

## S3

```typescript
// SDK v3 사용
import { S3Client, GetObjectCommand, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const s3 = new S3Client({ region: 'ap-northeast-2' });

// 업로드
async function upload(key: string, body: Buffer) {
  await s3.send(new PutObjectCommand({
    Bucket: 'my-bucket',
    Key: key,
    Body: body,
    ContentType: 'application/octet-stream',
  }));
}

// Presigned URL (업로드용)
async function getUploadUrl(key: string): Promise<string> {
  const command = new PutObjectCommand({
    Bucket: 'my-bucket',
    Key: key,
  });
  return getSignedUrl(s3, command, { expiresIn: 3600 });
}
```

## CloudFront + S3

```yaml
# CloudFront OAC (Origin Access Control) 설정
# S3 버킷 정책
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-bucket/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::ACCOUNT:distribution/DIST_ID"
        }
      }
    }
  ]
}
```

## Lambda

```typescript
// Handler 패턴
import { APIGatewayProxyHandler, APIGatewayProxyResult } from 'aws-lambda';

export const handler: APIGatewayProxyHandler = async (event) => {
  try {
    const body = JSON.parse(event.body || '{}');
    
    // 비즈니스 로직
    const result = await processRequest(body);
    
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify(result),
    };
  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Internal server error' }),
    };
  }
};

// Lambda@Edge (CloudFront)
export const handler = async (event) => {
  const request = event.Records[0].cf.request;
  
  // URL 리라이트
  if (!request.uri.includes('.')) {
    request.uri = '/index.html';
  }
  
  return request;
};
```

## DynamoDB

```typescript
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand, PutCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

// Get Item
const { Item } = await docClient.send(new GetCommand({
  TableName: 'users',
  Key: { pk: 'USER#123', sk: 'PROFILE' },
}));

// Query
const { Items } = await docClient.send(new QueryCommand({
  TableName: 'users',
  KeyConditionExpression: 'pk = :pk AND begins_with(sk, :sk)',
  ExpressionAttributeValues: {
    ':pk': 'USER#123',
    ':sk': 'ORDER#',
  },
}));

// Put Item
await docClient.send(new PutCommand({
  TableName: 'users',
  Item: {
    pk: 'USER#123',
    sk: 'PROFILE',
    name: 'John',
    email: 'john@example.com',
    createdAt: new Date().toISOString(),
  },
  ConditionExpression: 'attribute_not_exists(pk)', // 중복 방지
}));
```

## Secrets Manager

```typescript
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

const client = new SecretsManagerClient({});

async function getSecret(secretId: string): Promise<Record<string, string>> {
  const { SecretString } = await client.send(
    new GetSecretValueCommand({ SecretId: secretId })
  );
  return JSON.parse(SecretString || '{}');
}

// 캐싱 권장
let cachedSecrets: Record<string, string> | null = null;

async function getSecretsCached() {
  if (!cachedSecrets) {
    cachedSecrets = await getSecret('my-app/prod');
  }
  return cachedSecrets;
}
```

## Useful CLI Commands

```bash
# EKS
aws eks update-kubeconfig --name my-cluster --region ap-northeast-2

# S3
aws s3 sync ./dist s3://my-bucket --delete
aws s3 cp s3://bucket/file.txt - | head  # stdout으로 출력

# CloudFront
aws cloudfront create-invalidation --distribution-id DIST_ID --paths "/*"

# Logs
aws logs tail /aws/lambda/my-function --follow
aws logs filter-log-events --log-group-name /aws/lambda/my-function --filter-pattern "ERROR"

# SSM Parameter Store
aws ssm get-parameter --name /my-app/db-url --with-decryption
```
