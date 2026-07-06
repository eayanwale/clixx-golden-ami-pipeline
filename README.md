# CLIXX AMI Build Pipeline

Jenkins-driven pipeline that builds a golden AMI for the CLIXX application with Packer, provisions a bastion/test instance for it with Terraform, and runs an AWS Inspector vulnerability scan against the result.

## Repo layout

```
CLIXX-AMI-BUILD/
└── stackterraform/
    ├── images/
    │   ├── image.pkr.hcl        # Packer template (Amazon Linux 2, amazon-ebs builder)
    │   ├── Jenkinsfile          # Pipeline definition
    │   └── Jenkinsfile-1        # Alternate/backup pipeline definition
    ├── instances/
    │   ├── main.tf              # Key pair, security group, EC2 instance built from the AMI
    │   ├── variables.tf         # Region, VPC, subnets, key path, AMI name
    │   ├── inspector.tf         # Enables AWS Inspector2 (EC2 scanning) on the account
    │   ├── inspector-agentinstall.tpl  # Inspector agent install script
    │   └── ses_key.pub          # Public key installed on the instance
    └── scripts/
        ├── setup.sh             # Packer provisioner: installs LAMP stack (Apache, MariaDB, PHP)
        └── setup_old.sh         # Previous version of the provisioning script
```

## Pipeline overview (`Jenkinsfile`)

Triggered manually with an `ACTION` choice parameter:

| Action | What runs |
|---|---|
| `image_build` | AI source audit → Packer AMI build |
| `tf_apply_scan` | AI source audit → Terraform init/plan/apply → Inspector vulnerability report |
| `full` | All of the above: AMI build, infra apply, and vulnerability scan |
| `tf_destroy` | Terraform destroy |

Stages, in order:

1. **AI Source Code Audit** — runs Claude Code (`claude-sonnet-5`) inside the pipeline to scan the workspace for hardcoded secrets and auto-fix minor `.tf` syntax issues (via `terraform fmt`/`validate`). Stops without proceeding if secrets are found.
2. **Packer AMI Build** — stamps the AMI name with the current build number and runs `packer build` against `image.pkr.hcl`.
3. **Terraform init / plan** — initializes the `instances` stack (S3 backend) and produces a plan.
4. **Build Instance** — `terraform apply` to launch an EC2 instance from the freshly built AMI.
5. **Build Vulnerability Report** — queries AWS Inspector2 findings for the account, archives them as `inspector-findings.json`.
6. **Destroy Instance** — tears down the Terraform-managed infrastructure (`tf_destroy` only).

Slack notifications are sent at the start/end of each major stage.

## Packer image (`image.pkr.hcl`)

- Builder: `amazon-ebs`, sourced from the latest Amazon Linux 2 (`amzn2-ami-hvm-*-x86_64-gp2`) AMI.
- Instance type: `t2.small`, 10GB `gp2` root volume.
- AMI is shared to the account IDs in `aws_accounts` and copied to `us-east-1` (`ami_regions`).
- Provisioning is delegated entirely to `../scripts/setup.sh`.

`setup.sh` installs and enables a LAMP stack (Apache + MariaDB + PHP 7.2 via `amazon-linux-extras`), opens up `AllowOverride All` in the Apache config, tunes TCP keepalive, and sets ownership/permissions on `/var/www` for `ec2-user`/`apache`.

## Terraform (`instances/`)

- Remote state: S3 backend (`enoch-tf-state-bucket`, key `stack-AMI/terraform.tfstate`, `us-east-1`, profile `stackprog-dev`).
- Creates a key pair from `ses_key.pub`, a security group allowing inbound `22`, `80`, `8080` from `0.0.0.0/0`, and a `t2.micro` instance looked up by AMI name (`data.aws_ami.stack`).
- `inspector.tf` enables AWS Inspector2 EC2 scanning for the current account.

## Prerequisites

- Jenkins with the Packer and Terraform (`terraform-1.10`) tools configured, plus the Claude Code AI Agent plugin.
- Jenkins credentials: `Claude_API` (Anthropic API key), AWS credentials with permissions for EC2, Inspector2, and the Terraform state S3 bucket.
- An existing VPC/subnets in `us-east-1` matching the defaults in `variables.tf` (or override them).
- Slack integration configured for the notifications to work.

## Known gaps / things to double-check before relying on this

- The security group in `main.tf` opens ports 22, 80, and 8080 to `0.0.0.0/0` — tighten `cidr_blocks` for anything beyond a throwaway test instance.
- Several values are hardcoded (AWS account IDs, VPC/subnet IDs, S3 state bucket, IAM instance profile) and assume a specific AWS account/environment.
- `Jenkinsfile-1` is to be an older pipeline/skeleton — confirm which one is actually wired to the Jenkins job before editing.
