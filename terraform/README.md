# Terraform

## AWS Credentials

Save your AWS credentials in `~/.aws/credentials` as a profile:

```cfg
[default]
aws_access_key_id = <AWSKEY1>
aws_secret_access_key = <secret+id+1>

[profile2]
aws_access_key_id = <AWSKEY2>
aws_secret_access_key = <secret+id+2>
```

## Command memo

The first command to run for a new configuration -- or after checking out an existing configuration from version control -- is `terraform init`.
After adding a new module to configuration, it is necessary to run (or re-run) `terraform init` to obtain and install the new module's source code.

```sh
terraform init
```

```sh
terraform apply
terraform apply -var 'region=us-east-1' -var 'profile=<your-aws-profile>'
terraform show
```

## Terraform and Ansible reference

https://robertverdam.nl/2018/09/03/deploying-an-application-to-aws-with-terraform-and-ansible-part-1-terraform/