#!/bin/bash
SG_ID="sg-0d4fbbcb5f7b89575"
AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z0853835SDE0JTKZUUR2"
DOMAIN_NAME="sanathananelaform.online"

for instance in $@ # user may pass mongo,cataglouge
do
    INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text)
    if [ $instance == "frontend"]; then
        IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)
    else
        IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query 'Reservations[0].Instances[0].PrivateIpAddress' \
        --output text)

        RECORD_NAME="$instance.$DOMAIN_NAME" #mongodb.sanathananelaform.online
    fi
    echo  "IP Address :$IP"

# Update Route53 record
    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
    "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
        "Name": "'$RECORD_NAME'",
        "Type": "A",
        "TTL": 1,
        "ResourceRecords": [{"Value": "'$IP'"}]
        }
    }]
    }
    '
    echo "record updated for $instance
done