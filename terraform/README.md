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

```sh
terraform init
terraform apply
terraform show
```
