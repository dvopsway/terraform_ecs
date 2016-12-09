# Terraform ECS

Using this project you can launch your public dockerized images in fully managed HA ECS service.

## Usage

Just take a clone of this project, update terraform.tfvars accordingly and then run terraform plan and apply:

```
terraform plan -var 'access_key=<access_key>' -var 'secret_key=<secret_key>'
```

```
terraform apply -var 'access_key=<access_key>' -var 'secret_key=<secret_key>'
```

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D
