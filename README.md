# README
The following code designed to restart EKS cluster deployment using AWS Lambda. Example usages: your AWS Secrets Manager secret has been rotated and you want to restart deployment, so application could fetch new creds.

To achieve this add the CloudWatch trigger for your Lambda Function

### Requirements
Required permissions for Lambda execution role:

```
eks:DescribeCluster
sts:GetCallerIdentity
```

If your AWS EKS cluster is in private subnets, your AWS Lambda should has VPC access enabled. In that case, execution role must have `AWSLambdaVPCAccessExecutionRole` policy attached.

You need to setup the following Lambda function environment variables:

```
CLUSTER_NAME = "<EKS cluster name>"
REGION = "<EKS cluster region>"
NAMESPACE = "<K8 namespace>"
DEPLOYMENTS_TO_ROTATE = "<list of deployment that need to be restarted separated by whitespace>"
```

In order to allow AWS Lambda function to manage kubernetes resource, you need to do the following:

* Modify `aws-auth` config map and add the following lines under the section “mapRoles”:
    
    ```
    - rolearn: arn:aws:iam::XXXXXX:role/YYYYYYY
        username: lambda
    ```

    Replace `arn:aws:iam::XXXXXX:role/YYYYYYY` with your lambda execution role ARN

* Create RBAC role:

    ```
    kind: Role
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
        name: lambda-access
        namespace: default
    rules:
    - apiGroups: [""]
      resources: ["pods"]
      verbs: ["get", "watch", "list"]
    ```

* Create Role Binding resource:

    ```
    kind: RoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: lambda-user-role-binding
      namespace: default
    subjects:
    - kind: User
      name: lambda
      apiGroup: rbac.authorization.k8s.io
    roleRef:
      kind: Role
      name: lambda-access
      apiGroup: rbac.authorization.k8s.io
    ```


Deploy code to lambda and run it lambda.

Build Lambda package with `junipiter`:

```
juni build
```

### Terraform
You can use terraform code to create all that above. Do not forget to provider your own values in `variables.tfvars` file:

```
terraform apply --var-file variables.tfvars
```