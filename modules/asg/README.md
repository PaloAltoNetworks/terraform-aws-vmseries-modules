# Auto-Scaling Group

## AWS IAM Policy

The Terraform user should be attached to the AWS IAM Policy similar to:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "42",
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:DeleteRole",
                "iam:PassRole",
                "lambda:CreateFunction",
                "lambda:DeleteFunction",
                "lambda:InvokeAsync",
                "lambda:InvokeFunction",
                "lambda:UpdateFunctionCode",
                "lambda:GetFunctionConfiguration",
                "lambda:CreateAlias",
                "lambda:DeleteAlias",
                "lambda:UpdateAlias",
                "lambda:AddPermission",
                "lambda:RemovePermission"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```
