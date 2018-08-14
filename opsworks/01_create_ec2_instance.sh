#!/bin/bash
#
# Create an EC2 instance and associate an elastic IP to it
#
# NB. smallest possible instance created (t2.nano)
#
# Usage:
#   bash 01_create_instance.sh \
#          $stack_id \
#          $layer_id \
#          $hostname \
#          $availability_zone \
#          $subnet_id


stack_id=$1
layer_id=$2
hostname=$3
av_zone=$4
subnet_id=$5

ec2=$(aws opsworks create-instance \
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
  --os 'Ubuntu 16.04 LTS')
  #--ami-id "ami-fcc4db98")
ec2_opsworks_id=$(echo $ec2 | jq -r ".InstanceId")

# Get EC2 instance ID (NB. different from the OpsWorks ID for the same EC2 instance)
ec2_instance_id=aws opsworks describe-instances --instance-ids=$ec2_opsworks_id | jq -r ".Instances[0].Ec2InstanceId")

echo -e "Created EC2 instance:\n$ec2_opsworks_id (OpsWorks ID)\n$ec2_instance_id (EC2 ID)"

# Allocate an Elastic IP and associate it to the instance
allocate=$(aws ec2 allocate-address --domain vpc)
elastic_IP=$(echo $allocate | jq -r ".PublicIp")

associate=$(aws ec2 associate-address \
  --instance-id $ec2_instance_id \
  --public-ip $elastic_IP \
  --allow-reassociation)

echo -e "Allocated IP:\n$elastic_IP"
