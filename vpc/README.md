## 1.  Create a VPC
AWS Virtual Private Cloud is a virtual network in AWS's data centers, which allows us to isolate our infrastructure from other resources on AWS. We can use this VPC definition to decide who has access to which resources.

We request a specific address range using CIDR block notation (Classless Inter-Domain Routing). CIDR notation is a 4-octet IP address followed by a number which specifies how many bits of the IP address to reserve for network addresses. The remaining bits (e.g. 32-24=8) determines how many of the IP bits to use for host addressing. 2^8=256 host addresses avaialable within the network.

Let's select a CIDR block of /16, so that we can use bits 16-24 for our subnets, and 25-32 for our hosts.

(You can make the following commands more terminal-friendly by parsing them with a command line JSON parser such as `jq`)

`aws ec2 create-vpc --cidr-block 10.0.0.0/16`
```
VPC	10.0.0.0/16	dopt-03e65a6a	default	False	pending	vpc-fefa4f96
CIDRBLOCKASSOCIATIONSET	vpc-cidr-assoc-7079fe18	10.0.0.0/16
CIDRBLOCKSTATE	associated
```

REFS:
[Digital Ocean. Understanding IP Addresses, Subnets, and CIDR Notation for Networking. March 12, 2014.](https://www.digitalocean.com/community/tutorials/understanding-ip-addresses-subnets-and-cidr-notation-for-networking)  
[Digital Ocean. An Introduction to Networking Terminology, Interfaces, and Protocols. January 14, 2014.](https://www.digitalocean.com/community/tutorials/an-introduction-to-networking-terminology-interfaces-and-protocols)

## 2. Create subnets
Subnets are a subsection of our VPC network. (Similar to how a home network is a subnet of our ISP's network.) Subnets define a range of IP address in the VPC, and can be either public or private.

Public subnets interface with the internet, and are used for resources you need to access from a personal computer, such as when you want to be able to SSH into a server.

Private subnets are isolated from the internet, and can only be accessed by other resources within the VPC. Private subnets are typically used to address sensitive resources, such as databases, which we don't want to expose to the public internet. Private subnet instances access the Internet via Network Address Translation (NAT).

While a VPC spans all availability zones within a region, each subnet must lie in just one availability zone. Having subnets across multiple avaialability zones allows us to have a fault-tolerant, redundant infrasturcture.

```
The instances in the public subnet can receive inbound traffic directly from the Internet, whereas the instances in the private subnet can't. The instances in the public subnet can send outbound traffic directly to the Internet, whereas the instances in the private subnet can't. Instead, the instances in the private subnet can access the Internet by using a network address translation (NAT) instance that you launch into the public subnet.

The database servers can connect to the Internet for software updates using the NAT gateway, but the Internet cannot establish connections to the database servers. 
```
cf.
[VPC with Public and Private Subnets (NAT)](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Scenario2.html)
[serverfault: AWS VPC Private vs Public subnets](https://serverfault.com/questions/696306/aws-vpc-private-vs-public-subnets)

First subnet:
`aws ec2 create-subnet --vpc-id vpc-fefa4f96 --cidr-block 10.0.1.0/24 --availability-zone eu-west-2a`
```
SUBNET	False	eu-west-2b	251	10.0.1.0/24	False	False	pending	subnet-2a382867	vpc-fefa4f96
```

Second subnet:
`aws ec2 create-subnet --vpc-id vpc-fefa4f96 --cidr-block 10.0.2.0/24 --availability-zone eu-west-2b`
```
SUBNET	False	eu-west-2b	251	10.0.2.0/24	False	False	pending	subnet-e73929aa	vpc-fefa4f96
```

## 3. Create an internet gateway
An internet gateway provides a route which allows the VPC to be accessed from the internet. It behaves like a modem. (NB. without an internet gateway, resources within the VPC can still talk to each other, but they can't be accessed from the internet.)
`aws ec2 create-internet-gateway`
```
INTERNETGATEWAY	igw-deb79fb7
```


## 4. Attach the internet gateway to the VPC
`aws ec2 attach-internet-gateway --internet-gateway-id igw-deb79fb7 --vpc-id vpc-fefa4f96`
```
[No response]
```

## 5. Create a route table
"A route table contains a set of rules, called routes, that are used to determine where network traffic is directed."
`aws ec2 create-route-table --vpc-id vpc-fefa4f96`
```
ROUTETABLE	rtb-675ec40f	vpc-fefa4f96
ROUTES	10.0.0.0/16	local	CreateRouteTable	active
```

## 6. Add internet gateway rule to the route table
"Attaching an internet gateway does not make all subnets public.  If you want to make a subnet public, you need to add a route table with internet gateway to the subnet."

`aws ec2 create-route --route-table-id rtb-675ec40f --destination-cidr-block 0.0.0.0/0 --gateway-id igw-deb79fb7`
```
True
```
In the Web UI, this looks like:
```
Destination	Target				Status	Propagated
============================================
10.0.0.0/16	local					Active	No
0.0.0.0/0		igw-deb79fb7	Active	No					<< just created!
```

## 7. Associate route table to a subnet, making it publicly accessible
`aws ec2 associate-route-table --route-table-id rtb-675ec40f --subnet-id subnet-e73929aa`
```
rtbassoc-9f101af7
```
"We can now launch an instance to the public subnet which can be accessed over the internet. If you launch an ec2 instance in the private subnet (first subnet – 10.0.1.0/24), you will not be able to access it as it does not have an internet gateway rule. But all the instances in a VPC can talk to each other using its private IP’s."
