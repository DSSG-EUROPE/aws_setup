#!/bin/bash
#
#
# Usage:
#   bash 00_create_stack.sh \
#          $stack_name \
#          $vpc_id \
#          $account_number \
#          $default_availability_zone \
#          $subnet_id \
#          $region

stack_name=$1
vpc_id=$2
account_num=$3
default_av_zone=$4
subnet_id=$5
region=$6

# 1. Create a stack
stack=$(aws opsworks create-stack \
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
  --stack-region $region)

stack_id=$(echo $stack | jq -r ".StackId")
echo -e "Created stack:\n$stack_id"

# 2. Create a layer in the stack
layer_name='tut_lyr' #$7
layer_name_short=$layer_name
sg_id='sg-da7143b1'

layer=$(aws opsworks create-layer \
  --stack-id $stack_id \
  --type 'custom' \
  --name $layer_name \
  --shortname $layer_name_short \
  --custom-security-group-ids $sg_id \
  --enable-auto-healing \
  --auto-assign-elastic-ips \
  --auto-assign-public-ips \
  --install-updates-on-boot \
  --no-use-ebs-optimized-instances)

layer_id=$(echo $layer | jq -r ".LayerId")
echo -e "Created layer:\n$layer_id"
