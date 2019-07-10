# EC2 Spot Instances

Spot instances allow you to use underutilised EC2 resources at a fraction of the On-Demand price, resulting in savings of around 70-80% ("up to 90%").


## Introduction

We will first create a launch template to define network setting, maximum bid price, interruption behaviour and other details. Then we will file a Spot Request based on this template, while further specifying the specific instance types that we want to use.

After you create the template, if you notice any errors or want to make any adjustments, you can create a new version of the same template by selecting "Create a new template version" and specifying the Source Template and Source Template Version accordingly.

The settings below are an example of a template that was created and deployed in practice. Note that all the settings below are optional and, depending on your particular circumstances, you may want to set them differently.

It is important to set the termination & stopping behaviour carefully. Termination will complete delete your instances (with no chance of recovery afterwards), while Stopping will simply turn off the instance (with the ability to turn it on again afterwards). Hibernation will save the the RAM contents to disk when an instance is stopped.

## Create launch template

$ What would you like to do?
> Create a new template

$ Launch template name
> my-template

### Launch template contents
$ AMI
> Ubuntu Server 18.04 LTS

$ Instance type
> r5.4xlarge

$ Key pair name
> [the admin's .pem]

$ Network type
> VPC

$ Security Groups
> AWS-OpsWorks-Custom-Server
> AWS-OpsWorks-Default-Server

### Network interfaces
Leave blank. Network interfaces and instance-level security groups may not be specified together.

### Storage (Volums)
> EBS, 128GB, Delete on terminate (yes)
The size is largely dependent on your own needs. We found that for teams cloning large GitHub repositories and creating large conda environments, a bare minimum of 8GB per user was required. However, it is prudent to allocate more than the bare minimum to avoid having to upsize the root volume later. (The root volume is the core of your machine, containing the OS itself, the user configurations, etc.)


### Advanced details

$ Purchasing option
> Request Spot instances (check)

$ Maximum price
> Set your maximum price (per instance/hour)
> $1.184 (NB. this is the on-demand price of the r5.4xlarge instance we chose above)

$ Request type
> Persistent (ensure a new request is made if an old one expires or is terminated)

$ Valid to
> Set your request expiry date (NB. want to ensure we don't forget to cancel the request in the future)

$ Interruption behavior
> Stop (NB. don't want to inadvertently terminate our instances)

$ IAM instance profile
> aws-opsworks-ec2-role

$ Shutdown behaviour
> Stop (NB. don't want to inadvertently terminate our instances)

$ Stop - Hivernate behaviour
> Enable
(NB. Hibernation stops your instance and saves the contents of the instance’s RAM to the root volume)

$ Termination protection
> Enable
NB. If enabled, the instance cannot be terminated using the console, API, or CLI until termination protection is disabled.

$ Monitoring
> Enable

$ Elastic Graphics
> Don't include in launch template

$ T2/T3 Unlimited
> Don't include in launch template

$ Placement group name
> Don't include in launch template

$ EBS-optimized instance
> Don't include in launch template

$ User data
> [optional]
This allows you to specify commands which will be run every time a new instance is created, e.g. to install required packages, etc.
Make sure whatever commands you include here actually work as expected by running them manually on a fresh EC2 instance first. Otherwise, if these commands fail they may compromise your entire launch template. For more info, see https://bloggingnectar.com/aws/automate-your-ec2-instance-setup-with-ec2-user-data-scripts/


#########################################

## Request Spot Instances

### Tell us your application or task need
[] Load balancing workloads
[] Flexibile workloads
[x] Big data workloads
[] Defined duration workloads


### Configure your instances
$ Launch template
> my-template

$ AMI
> from template

$ Minimum compute unit
> As specs
> vCPUs: 32
> Memory (GiB): 240

$ Network
> select your VPC

$ Availability Zone
> eu-west-2a

$ Key pair name
> from template


### Tell us how much capacity you need

$ Total target capacity
> 1

$ Optional on-demand portion
> 0
We want to have all our (1) instances as Spot, not On-Demand.

$ Maintain target capacity
> check

$ Interruption behaviour
> Hibernate
If our fleet is interrupted, we don't want to lose all our ongoing experiments.


### Fleet request settings

Uncheck the `Apply recommendations` box.

#### Fleet request
Click on select instance types and select the instances you would like Spot to consider. For example:
```
Instance type 	vCPUs 	Memory (GiB) 	Spot price 	Savings off On-Demand 	
r5.4xlarge 	16 vCPUs 	128GiB 	$0.3591/hr 	64 %
r4.8xlarge 	32 vCPUs 	244GiB 	$0.5596/hr 	74 %
r5.12xlarge 	48 vCPUs 	384GiB 	$0.855/hr 	72 %
r5.16xlarge 	64 vCPUs 	512GiB 	$1.14/hr 	72 % 
```

When selecting instances, you can check the pricing history to see how the price has fluctuated

#### Fleet allocation strategy

$ Diversified across X instance pools in my fleet
> 2


### Additional request details
Apply defaults.




## Common errors
Status: spotFleetRequestConfigurationInvalid
Description: [...] Linux/UNIX: Missing device name
Solution: add an additional EBS volume, e.g. 16GB mounted on /dev/sdb

Status: spotFleetRequestConfigurationInvalid
Description: [...] The attribute 'disableApiTermination' cannot be used when launching a Spot instance.
Solution: Disable termination protection.
+info: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/terminating-instances.html

Status: spotFleetRequestConfigurationInvalid
Description: The parameter validUntil cannot be specified when the SpotRequestType is set to 'single_auction'.
Solution: @ `Spot Request` page, @ `Additional request details` section, uncheck `Apply defaults` box, and then uncheck the `Terminate the instances when the request exprires` box.

Solution 2: Valid to: Don't include

Status: spotFleetRequestConfigurationInvalid
remove the HibernationOptions parameter. To enable the Spot service to hibernate future Spot Instances, set InstanceInterruptionBehavior to hibernate
