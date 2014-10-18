ManageAWS
=========

A collection of scripts to manage the creation and termination of instances in EC2.

##[ec2_create.sh](./ec2_create.sh)

This script will create a new EC2 instance from the current Amazon AMI image and apply a bootstrap file to do the following:

* Adds required EBS and Peripheral Devices and creates file systems
* Mounts the file systems as specified
* Sets instance hostname and configures networking
* Apply Tags to the instance such as Name: Component: Usage:
* Registers the instance with Puppet and runs catalog update
* Adds the instance to Route53 DNS

Run without any options for script usage details.

###Dependencies

creatEC2.sh depends on either of the following bootstrap files in the directory from which it is run:

   * [dev.sh](./dev.sh)
   * [qa.sh](./qa.sh)

These bootstrap files contain the information to connect the instance to puppet as well as the options chosen in the scripts for things like mount points, EBS devices etc.

The script assumes AWS credentials are setup.

##[terminateInstance.sh](./terminateInstance.sh)

This script terminate an EC2 instance and remove its entry from Route53 DNS. The script requires three arguments:

* The ID of the EC2 instance you wish to terminate
* The hostname of the instance
* The environment in which it is running {dev|qa}

The requirement of all three options make it difficult to terminate an instance by accident.

