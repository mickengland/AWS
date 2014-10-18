#!/bin/bash
# Usage terminateInstance.sh <instanceID> <hostname> <environment>
instanceid=$1
hostname=$2
environment=$3
#Test for arguments
if [ $# -lt 3 ]; then
    echo "Usage: $0 <InstanceID> <hostname> <environment>"
    echo '''
    The hostname is anything before the domain in DNS, 
    eg adboard-test if the FDQN is adboard.test.qa.example.com
    '''
    exit 1
elif [ $3 != "dev" ] && [ $3 != "qa" ]; then
    echo "Environment must be dev or qa"
    echo "Usage: $0 <InstanceID> <hostname> <environment>"
    exit 1
fi


#Remove from to DNS

##Commented out for testing:

ipaddr=$(ec2-describe-instances ${instanceid} | grep INSTANCE | cut -f 18)
/usr/local/bin/cli53 rrdelete ${environment}.example.com ${hostname} A
#Terminate instance
ec2-terminate-instances ${instanceid}
