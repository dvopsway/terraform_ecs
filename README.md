# Terraform ECS

Using this terrafom module you can launch your public dockerized images in fully managed HA ECS service.

Following components are launched using this module

1. Highly available VPC with public private subnets, securtity group, Network ACLs, etc.
2. Necessary IAM policies
3. Lauch config with autoscaling group
4. ECS Cluster , task definition and service
5. ELB Endpoint

## Usage

To launch a new environment create your module defintion as per below example.

```
module "magnify" {
  source            = "github.com/dvopsway/terraform_ecs"
  access_key        = "xxxxxxxxxxxxxxxxxxxxxxxx"
  secret_key        = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  microservice_name = "magnify"
  imagename         = "padmakarojha/magnify"
  region            = "us-east-1"
  az = {
    zone1 = "us-east-1b"
    zone2 = "us-east-1c"
  }
  vpc_cidr = "10.200.50.0/23"
  key_name = "aws-ops"
}
```

Once done, run terraform plan

```
terraform plan 
```

Review you plan and then run terraform apply to create the infra

```
terraform apply
```

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D
