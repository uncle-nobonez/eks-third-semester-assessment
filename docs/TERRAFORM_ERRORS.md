Terraform errors observed and how to resolve them
===============================================

This document records the Terraform errors we saw when running CI and local `terraform` commands and the recommended, tested steps to resolve them.

1) Error acquiring the state lock (ResourceNotFoundException)
-----------------------------------------------------------

Symptoms (example from CI):

│ Error: Error acquiring the state lock
│ 
│ Error message: 2 errors occurred:
│     * ResourceNotFoundException: Requested resource not found
│     * ResourceNotFoundException: Requested resource not found
│ 
│ Terraform acquires a state lock to protect the state from being written
│ by multiple users at the same time. Please resolve the issue above and try
│ again. For most commands, you can disable locking with the "-lock=false"
│ flag, but this is not recommended.

Root cause
- The S3 bucket or DynamoDB table configured as the Terraform backend (locking table) doesn't exist yet in the AWS account or is not accessible with the credentials used by the runner.

What to check locally
- Confirm the backend settings (these are defined in `terraform/eks/minimal/backend.tf`):

  bucket: retail-store-terraform-state-uncle
  key: terraform.tfstate
  dynamodb_table: retail-store-terraform-locks
  region: us-east-1

- Test AWS access and resource presence:

```bash
# check identity
aws sts get-caller-identity --output json

# does the S3 bucket exist?
aws s3api head-bucket --bucket retail-store-terraform-state-uncle --region us-east-1 || echo "bucket missing"

# does the DynamoDB lock table exist?
aws dynamodb describe-table --table-name retail-store-terraform-locks --region us-east-1 || echo "table missing"
```

Quick fixes
- Create the backend resources locally (recommended once):

```bash
cd terraform/eks/minimal
./create-terraform-backend.sh
# or run the commands in that script manually using awscli with appropriate AWS credentials
```

- If you prefer CI to create them automatically, ensure the GitHub Actions runner credentials allow S3 and DynamoDB create operations. The CI workflows in this repo now include guarded steps that will attempt to create the S3 bucket and DynamoDB table when running `apply`/`destroy` (but PR plan jobs will only validate and fail fast).

2) EntityAlreadyExists errors when creating IAM policy / KMS alias / Log Group
-----------------------------------------------------------------------------

Symptoms (examples taken from `terraform apply` output):

- Error creating IAM Policy (retail-store-eks-readonly): EntityAlreadyExists: A policy called retail-store-eks-readonly already exists.
- Error creating KMS Alias (alias/eks/retail-store): AlreadyExistsException: An alias with the name arn:aws:kms:us-east-1:<acct-id>:alias/eks/retail-store already exists
- Error creating CloudWatch Log Group (/aws/eks/retail-store/cluster): ResourceAlreadyExistsException: The specified log group already exists

Root cause
- These resources already exist in the AWS account (created outside of this Terraform code or by an earlier run). Terraform attempted to create them again because they are declared in `.tf` files but not present in the current Terraform state.

Resolution (recommended)
A. Import existing resources into Terraform state (clean, idempotent)

1. Initialize Terraform (ensure backend is configured):

```bash
cd terraform/eks/minimal
terraform init
```

2. Find resource ARNs/names using AWS CLI (examples):

```bash
# IAM policy ARN
aws iam list-policies --scope Local --query "Policies[?PolicyName=='retail-store-eks-readonly'].Arn" --output text

# KMS alias presence
aws kms list-aliases --region us-east-1 --query "Aliases[?AliasName=='alias/eks/retail-store']"

# CloudWatch log groups
aws logs describe-log-groups --log-group-name-prefix "/aws/eks/retail-store" --region us-east-1
```

3. Import into Terraform (examples — run from `terraform/eks/minimal`):

```bash
# import IAM policy into the local resource
terraform import aws_iam_policy.eks_readonly <policy-arn>

# import KMS alias using the module path seen in the error (adjust the module path to match your tree):
terraform import module.retail_app_eks.module.eks_cluster.module.kms.aws_kms_alias.this["cluster"] alias/eks/retail-store

# import cloudwatch log group (adjust the module address if needed):
terraform import module.retail_app_eks.module.eks_cluster.aws_cloudwatch_log_group.this[0] "/aws/eks/retail-store/cluster"
```

4. Run `terraform plan` and verify Terraform no longer tries to create these resources.

B. Alternative: tell Terraform to use an existing ARN instead of creating a new resource
- For IAM policy, you can set the `existing_iam_policy_arn` variable (added to this module) to the ARN of the policy so Terraform will not attempt to create it and will attach the policy to the user.

```hcl
# terraform.tfvars or CLI override
existing_iam_policy_arn = "arn:aws:iam::<acct-id>:policy/retail-store-eks-readonly"
```

C. Quick-and-dirty (not recommended long-term)
- Change names in Terraform to include a random suffix (ensures no name collision) — this creates duplicate resources in the account and should be avoided unless you intentionally want a new resource.

3) inline_policy deprecation warnings
-------------------------------------

Warning excerpt:

```
inline_policy is deprecated. Use the aws_iam_role_policy resource instead.
If Terraform should exclusively manage all inline policy associations (the
current behavior of this argument), use the aws_iam_role_policies_exclusive
```

Context
- The warning is produced by an `aws_iam_role` resource inside an EKS module (a module under `.terraform/modules/...`). The provider deprecates embedding policies via `inline_policy` and recommends separate `aws_iam_role_policy` resources.

Recommended actions
- Upgrade the external module (if available) to a version that follows the new pattern.
- If the module is a local module you maintain, refactor the role definitions to use `aws_iam_role_policy` resources.
- If neither is possible, treat it as a warning for now but schedule a module upgrade/fix.

4) Checklist for resolving the reported errors (TL;DR)
------------------------------------------------------

- [ ] Ensure backend exists (S3 + DynamoDB) or create it using `terraform/eks/minimal/create-terraform-backend.sh`
- [ ] Run `terraform init` in `terraform/eks/minimal`
- [ ] Import the existing IAM policy, KMS alias, and CloudWatch log group into Terraform state using `terraform import` with the addresses shown in errors
- [ ] Run `terraform plan` and ensure no unexpected creations
- [ ] Apply
- [ ] Upgrade/refactor modules to remove deprecated `inline_policy` usage when convenient

5) Example commands that were used in diagnosis and resolution
--------------------------------------------------------------

```bash
# check AWS identity
aws sts get-caller-identity

# check S3 bucket + DynamoDB table
aws s3api head-bucket --bucket retail-store-terraform-state-uncle --region us-east-1
aws dynamodb describe-table --table-name retail-store-terraform-locks --region us-east-1

# import IAM policy
terraform import aws_iam_policy.eks_readonly arn:aws:iam::<acct-id>:policy/retail-store-eks-readonly

# import KMS alias
terraform import module.retail_app_eks.module.eks_cluster.module.kms.aws_kms_alias.this["cluster"] alias/eks/retail-store

# import CloudWatch log group
terraform import module.retail_app_eks.module.eks_cluster.aws_cloudwatch_log_group.this[0] "/aws/eks/retail-store/cluster"
```

If you want, I can:
- Add a dedicated CI job to attempt safe `terraform import` for these resources (not automatic — requires review), or
- Apply the `existing_iam_policy_arn` value for CI runs to avoid creating the policy during automated runs, or
- Attempt to upgrade the EKS module in this repo to a version that removes `inline_policy` usage.

If you want me to perform the imports in CI instead of locally, tell me which approach you prefer and I'll create a one-off workflow job that runs the imports guarded by an input flag so you can trigger it manually (recommended only when you trust the CI credentials).

Manual import workflow
----------------------

A manual GitHub Actions workflow was added: `.github/workflows/terraform-imports.yml`.
Trigger it from the Actions tab and type `import` into the confirmation input. The workflow will:

- Initialize Terraform using the S3/DynamoDB backend defined in `terraform/eks/minimal/backend.tf`.
- Safely attempt to import the IAM policy `retail-store-eks-readonly`, the KMS alias `alias/eks/retail-store`, and the CloudWatch log group `/aws/eks/retail-store/cluster` if they exist.
- Run `terraform plan` to verify the imports.

This job is manual to avoid automatic state changes. Review the job logs after running to confirm the imports succeeded.