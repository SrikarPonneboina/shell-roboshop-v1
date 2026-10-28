#!/bin/bash

#This script creates instance in aws and updates R53 records

ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="srikarlabs.space"
hostedzone_id="Z064550534ZXEXGIQB3I4"

for instance in $@
do 
echo "creating instance.."
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
EOF
echo "$instance ID: $instance_id"
echo "PrivateIp: $PrivateIp"
echo "PublicIp: $PublicIp"

if [ $instance != "frontend" ]; then
    IP=$PrivateIp
    r53_record="${instance}.${domain_name}"
else
    IP=$PublicIp
    r53_record="${domain_name}"
fi

#update R53 record
echo "route 53 record = ${r53_record}"
aws route53 change-resource-record-sets \
--hosted-zone-id $hosted_zone_id \
--change-batch '{
        "Changes": [
            {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "'$r53_record'",
                    "Type": "A",
                    "TTL": 1,
                    "ResourceRecords": [{"Value": "'$IP'"}]
                }
            }
        ]
    }'
echo "Updated r53 record for $instance" 

done