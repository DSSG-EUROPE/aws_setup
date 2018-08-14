#!/bin/bash
#
# Usage:
#   bash 02_grant_access.sh
#          $stack_id \
#          $account_number \
#          $username
#          $ssh_public_key

stack_id=$1
account_number=$2
username=$3
ssh_public_key=$4

# Create a new OpsWorks user
aws opsworks create-user-profile \
  --iam-user-arn "arn:aws:iam::${account_number}:user/${username}"

# Add user's public SSH key
aws opsworks update-user-profile \
  --iam-user-arn "arn:aws:iam::${account_number}:user/${username}"
  --ssh-public-key $(cat $ssh_public_key)

# Grant SSH (and sudo?) access 
aws opsworks set-permission \
  --stack-id $stack_id \
  --iam-user-arn "arn:aws:iam::${account_number}:user/${username}" \
  --allow-ssh \
  #--allow-sudo
