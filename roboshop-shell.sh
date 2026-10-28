#!/bin/bash

#This script creates instance in aws and updates R53 records

ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="srikarlabs.space"
hostedzone_id="Z064550534ZXEXGIQB3I4"

for instance in $@
do 
read -r instance_id PrivateIp PublicIp <<EOF
$(
    aws ec2 run-instances \
    --image-id $ami_id \
    --instance-type $instance_type \
    --security-groups "roboshop-common" "roboshop-$instance" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=roboshop-$instance}]" \
    --query "Instances[].[InstanceId, PrivateIpAddress, PublicIpAddress]" \
    --output text
)
echo "$instance ID: $instance_id"
echo "PrivateIp = $PrivateIp"
echo "PublicIp = $PublicIp"

done

