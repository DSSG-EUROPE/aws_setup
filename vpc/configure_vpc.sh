#!/bin/bash
#
# Configure the Virtual Private Cloud
#
# 0. Create VPC
# 1. Create 2 Subnets
# 2. Create an Internet Gateway
# 3. Attach the Internet Gateway to the VPC
# 4. Create a Route Table
# 5. Add the Internet Gateway to the Route Table
# 6. Make one of the Subnets public
#
################################################


#####
# 0 # Create VPC
#####
vpc_id=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 | jq -r ".Vpc.VpcId")
echo -e "VPC created:\n$vpc_id"


#####
# 1 # Create Subnets
#####
# Subnet 1
subnet1=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.2.0/24)
echo -e "subnet1 response...\n$subnet1"
subnet1_id=$(echo $subnet1 | jq -r ".Subnet.SubnetId")
echo -e "Subnet1 created:\n$subnet1_id"
# Subnet 2
subnet2=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.2.0/24)
echo -e "subnet2 response...\n$subnet2"
subnet2_id=$(echo $subnet2 | jq -r ".Subnet.SubnetId")
echo -e "Subnet2 created:\n$subnet2_id"


#####
# 2 # Create Internet Gateway
#####
igw=$(aws ec2 create-internet-gateway)
echo -e "igw response...\n$igw"
igw_id=$(echo $igw | jq -r ".InternetGateway.InternetGatewayId")
echo -e "Internet Gateway created:\n$igw_id"


#####
# 3 # Attach Internet Gateway to the VPC
#####
aws ec2 attach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id
echo "Attached the Internet Gateway to the VPC."


#####
# 4 # Create Route Table
#####
rtb=$(aws ec2 create-route-table --vpc-id $vpc_id)
echo -e "rt response...\n$rtb"
rtb_id=$(echo $rtb | jq -r ".RouteTable.RouteTableId")
echo -e "Route Table created:\n$rtb_id"


#####
# 5 # Create a route to the internet in the Route Table via the Internet Gateway
#####
resp=$(aws ec2 create-route --route-table-id $rtb_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id)
echo -e "Added Internet Gateway to the Route Table...\n$resp"


#####
# 6 # Make one of the subnets public
#####
rtb_assoc=$(aws ec2 associate-route-table --route-table-id $rtb_id --subnet-id $subnet2)
echo -e "Route table connected to subnet, now publically accessible.\n$rtb_assoc"
