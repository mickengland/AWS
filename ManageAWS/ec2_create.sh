#!/bin/bash
usage() { echo "Usage: $0 [-c <comp1|comp2|sysops>] [-e <dev|qa|prod>][-u]" 1>&2; exit 1; } 

# Get user input
while getopts "c:e:u:" o; do
    case "${o}" in
        c)
            c=${OPTARG}
            ((c == app1 || c == app2 || c == sysops)) || usage
            ;;
        e)
            e=${OPTARG}
            ((e == dev || e == qa || e == prod)) || usage
            ;;
        u)
            u=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${c}" ] || [ -z "${e}" ]; then
    usage
fi

# Set DNS zoneid
if [ $e = 'dev' ]; then
    zoneid=<Your ZoneID Here>
elif [ $e = 'qa' ]; then
    zoneid=<Your ZoneID Here>
fi

# Set hostname
if [ "${e}" == "${u}" ]; then
    hostname=${c}
else
    hostname=${c}-${u}
fi

# Set bootstrap file
bootstrap="${e}.sh"

# System Variables
key=sysops-key # Set the key you want the instance to launch with.
size=m1.small  # Set the size of instance to launch.
ami_id=ami-35792c5c # This is our standard ami. Don't change without good reason
sg=<your security group> # This is the internal security group. Don't change without consulting sysops.
# The subnet determines AWS availability zone. Sometimes needs changing if instances are not availabe in chosen zone.
#subnet=subnet-75ee131b #1d
subnet=subnet-<your subnet> #1e
number=$(date +%Y%m%d%H%M)
fdqn="${hostname}.${e}.example.com"

# Clean up boostrap from last run
sed -i '/.*reboot*./d' ${bootstrap}
sed -i '/.*mkfs*./d' ${bootstrap}
sed -i '/.*xvd*./d' ${bootstrap}
sed -i '/.*mkdir*./d' ${bootstrap}
sed -i '/.*mount*./d' ${bootstrap}

# Writing the bootstrap file
# Modify /etc/fstab
echo "sed -e '/xvdb/s/^/#/g' -i /etc/fstab" >> ${bootstrap}
echo "echo \"/dev/xvdb  /tmp    auto    defaults  0 2\" >> /etc/fstab" >> ${bootstrap}
#Unount ephemeral drive
echo "umount /media/ephemeral0" >> ${bootstrap}
# Create the file systems -- comment out mkfs if running with  snapshots
echo "mkfs -t ext4 /dev/xvdb" >> ${bootstrap}

# Mount the filesystems
echo "mount /tmp" >> ${bootstrap}

# Resize root partition
echo "resize2fs /dev/xvda1" >> ${bootstrap}

# Configure puppet
sed -i '/HOSTNAME/d' ${bootstrap}
echo "sed -i 's/HOSTNAME.*/HOSTNAME=${hostname}.${e}.example.com/' /etc/sysconfig/network" >> ${bootstrap}
sed -i '/^hostname/d' ${bootstrap}
echo "hostname ${hostname}" >> ${bootstrap}

# Reboot
echo "/sbin/reboot now" >> ${bootstrap}

# Start the instance. Modify to include a -b reference for any devices you wish added to the system.
echo "Starting instance ${hostname}"
instanceid=$(ec2-run-instances ${ami_id} -n 1 -k ${key} -g ${sg} -t ${size} -s ${subnet} -b "/dev/xvdb=ephemeral0" -b "/dev/sda1=:100" -f ${bootstrap} | egrep ^INSTANCE | cut -f2)

# Monitor instance status
while state=$(aws ec2 describe-instances --instance-ids $instanceid --output text --query 'Reservations[*].Instances[*].State.Name'); test "$state" = "pending"; do
  sleep 5; echo -n '.'
done; echo " $state"

#Adding the tags
if [ -z "$instanceid" ]; then
    echo "ERROR: could not create instance. Check ${logfile}   for more information. ";
    exit;
else
    echo "Launched with instanceid=$instanceid"
    echo "Adding tags..."
    ec2-create-tags $instanceid --tag component=${c} --tag env=${e} --tag Name=${hostname}-${e}-${number}
fi

#Add to DNS
ipaddr=$(ec2-describe-instances ${instanceid} | grep INSTANCE | cut -f 18)
route53 add_record ${zoneid} ${fdqn} A ${ipaddr} 3600

echo "${fdqn} running with ip of ${ipaddr}"
