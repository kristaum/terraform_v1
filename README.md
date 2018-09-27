# terraform_v1
Hands on with terraform and aws
<br>Created Scenario 2 from AWS user guide
<br>Scenario 2: VPC with Public and Private Subnets (NAT)
<br>On this scenario we are also initializing two instances one web instance assigned to the public subnet and a db instance on the private subnet.
<br>The private instance can connect to the internet through a NAT gateway.
<br>You can ssh into the private instance using the public instance as jumpbox, will create another project to use a bastion host instead.
<br>
<br>This still needs changes to become a fully reusable module as this was done for sa-east-1a region
