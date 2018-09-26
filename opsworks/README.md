# OpsWorks

OpsWorks is an AWS service allowing for provisioning and managing resources to be used by multiple people requiring different authorization credentials.

## 1. Create a stack
A stack encapsulates a group of resources and assigns a set of users specific permissions to access those resources. For example, an organization such as DSSG with multiple concurrent teams may want to allow access to project-specific resources only to members of each project.  

Specify the stack configuration variables:  
```
stack_name=my_stack
vpc_id=vpc-1234567
account_num=012345678901
default_av_zone=eu-west-2b
subnet_id=subnet-7654321
region=eu-west-2
```

Create a stack:  
```
aws opsworks create-stack \
  --name $stack_name \
  --vpc-id $vpc_id \
  --service-role-arn arn:aws:iam::${account_num}:role/aws-opsworks-service-role \
  --default-instance-profile-arn "arn:aws:iam::${account_num}:instance-profile/aws-opsworks-ec2-role" \
  --default-os "Ubuntu 16.04 LTS" \
  --default-availability-zone $default_av_zone \
  --default-subnet-id $subnet_id \
  --configuration-manager Name=Chef,Version=12 \
  --no-use-custom-cookbooks \
  --use-opsworks-security-groups \
  --default-root-device-type "ebs" \
  --stack-region $region
```

## 2. Create a layer
A layer allows to define a set of rules that will be applied to a set of resouces, such as Elastic IP allocation, equivalent storage volumes, etc.  

A single stack can contain multiple layers, each for a different purpose, such as applications, load balancing, databases, etc. We only want to create an EC2, so we'll just create one layer.  

Specify the layer configuration variables:  
```
layer_name=mylayer
layer_name_short=$layer_name
sg_id='sg-1234567'
```

Create a layer:  
```
aws opsworks create-layer \
  --stack-id $stack_id \
  --type 'custom' \
  --name $layer_name \
  --shortname $layer_name_short \
  --custom-security-group-ids $sg_id \
  --enable-auto-healing \
  --auto-assign-elastic-ips \
  --auto-assign-public-ips \
  --install-updates-on-boot \
  --no-use-ebs-optimized-instances
```

## 3. Create an EC2 computation instance
Let's create an EC2 compute instance accessible only to members of our stack, and following the rules define in our layer.

Specify the instance configuration variables:  
```
stack_id=$1
layer_id=$2
hostname=$3
av_zone=$4
subnet_id=$5
```

Create an EC2 instace:  
```
aws opsworks create-instance \
  --stack-id $stack_id \
  --layer-ids $layer_id \
  --instance-type 't2.nano' \
  --hostname $hostname \
  --availability-zone $av_zone \
  --virtualization-type 'hvm' \
  --subnet-id $subnet_id \
  --architecture 'x86_64' \
  --root-device-type 'ebs' \
  --install-updates-on-boot \
  --no-ebs-optimized \
  --agent-version 'INHERIT' \
  --tenancy 'default' \
  --os 'Ubuntu 16.04 LTS'
```

## 4. Allocate an Elastic IP and associate it to the instance
Even though our layer does `auto-assign-public-ips`, this public IP will be different every time we restart the instance. Elastic IP is AWS's IP allocation service, which allows us to reserve an IP address for our resources.

Allocate an Elastic IP (using the instance's ID from the EC2 Console, not it's ID inside OpsWorks)
```
allocate=$(aws ec2 allocate-address --domain vpc)
elastic_IP=$(echo $allocate | jq -r ".PublicIp")

associate=$(aws ec2 associate-address \
  --instance-id $ec2_instance_id \
  --public-ip $elastic_IP \
  --allow-reassociation)

echo -e "Allocated IP:\n$elastic_IP"
```


## 5. Create a user in the stack
```
aws opsworks create-user-profile \
  --iam-user-arn "arn:aws:iam::${account_number}:user/${username}"
```

Add the user's public SSH key:  
```
aws opsworks update-user-profile \
  --iam-user-arn "arn:aws:iam::${account_number}:user/${username}"
  --ssh-public-key $(cat $ssh_public_key)
```

Grant the user SSH access (and sudo, if applicable):  
```
aws opsworks set-permission \
  --stack-id $stack_id \
  --iam-user-arn "arn:aws:iam::${account_number}:user/${username}" \
  --allow-ssh \
  #--allow-sudo
```

## 6. Install PSQL, Miniconda, and other packages on EC2
In order to access the PostgreSQL database, we will need to add the command line PSQL tools to the EC2 instance. SSH into the EC2, run `sudo su` to switch to the root user, and run the following (answer `Y` when prompted to continue):  
```
echo "Installing PostgreSQL tools..."
sudo apt install postgresql-client-common;
sudo touch /etc/apt/sources.list.d/pgdg.list;
sudo echo "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" >> /etc/apt/sources.list.d/pgdg.list;
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -;
sudo apt-get update;
sudo apt-get install postgresql-10;
echo "Installed PostgreSQL tools: OK."
```

(Optional) To install miniconda, return to your user profile (run `exit` to exit the root profile) and run the following (when prompted for an installation location, enter `/opt/miniconda3` to make it available system-wide, not just `/root/miniconda3`):  
```
echo "Installing Miniconda..."
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh;
chmod +x Miniconda3-latest-Linux-x86_64.sh;
sudo bash Miniconda3-latest-Linux-x86_64.sh;
echo "Installed Miniconda: OK."

# Add Miniconda path to bashrc
echo "export PATH=\"/opt/miniconda3/bin:\$PATH\"" >> ~/.bashrc;
source ~/.bashrc;
```

(Optional) To install some other useful packages, return to the root user and run:
```
# pip upgrade
pip install --upgrade pip;
# AWS CLI tools
pip install awscli;
# csv toolkit
conda install csvkit
# process and resource monitoring
sudo apt-get install htop
```


## 7. Create an RDS database instance
[RDS](https://aws.amazon.com/rds/) is AWS's Relational Database Server, for scalable DB provisioning.

Because we want to create a single database that can be accessed throguh EC2 machines in different stacks, we will not associated the RDS instance to a specific stack (otherwise it would only be accessible through the EC2 inside that stack, and not the others).

By default, an RDS instance needs to be associate with a subnet group which gathers multiple subnets in different availability zones. This is in order to allow DB redundancy. We don't need this feature, but we still have to comply with the requirements for a multi-AZ subnet group.

Create another private subnet (without an internet gateway attached):  
`aws ec2 create-subnet --vpc-id vpc-fefa4f96 --cidr-block 10.0.3.0/24 --availability-zone eu-west-2c`  

Create a subnet group:  
```
aws rds create-db-subnet-group \
  --db-subnet-group-name "subnet-group-in-${vpc_id}" \
  --db-subnet-group-description "subnet-group-in-${vpc_id}" \
  --subnet-ids $subnet1_id $subnet3_id
```

Create an RDS instance:  
```
aws rds create-db-instance \
  --db-name $db_name \
  --db-instance-identifier $db_name \
  --allocated-storage 20 \
  --db-instance-class db.t2.micro \
  --engine postgres \
  --master-username dba \
  --master-user-password $adminpw \
  --vpc-security-group-ids $security_group_id \
  --db-subnet-group "subnet-group-in-${vpc_id}" \
  --availability-zone $availability_zone \
  --port 5432 \
  --no-publicly-accessible \
  --preferred-backup-window 04:00-05:00 \
  --no-auto-minor-version-upgrade
```

If we try accessing the database from our EC2 machine right now, our connection will time out. We need to add an inbound rule to the subnet group, accepting connections from the security group. The AWS CLI does not have this function, so we'll have to add it through the GUI Console.  

1. Go to the [RDS Console](https://eu-west-2.console.aws.amazon.com/rds/home?region=eu-west-2#dashboard:)  
2. Select the RDS instance  
3. Scroll down to _Security Group Rules_  
4. Select the security group (this will then take us to the EC2 Console)  
5. Add an _inbound rule_ allowing all traffic from our security group (set it as the _Source_)  
