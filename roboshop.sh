#!/bin/bash

# Configuration
SG_ID="sg-0d4fbbcb5f7b89575"
AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z0853835SDE0JTKZUUR2"
DOMAIN_NAME="sanathananelaform.online"

for instance in $@
do
    echo "Creating $instance instance..."
    
    # 1. Create EC2 instance
    INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text)
    
    echo "Instance created: $INSTANCE_ID"
    
    # 2. Wait for instance to initialize
    sleep 15
    
    # 3. Get IP (Public for frontend, Private for others)
    if [ "$instance" == "frontend" ]; then
        IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)
    else
        IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query 'Reservations[0].Instances[0].PrivateIpAddress' \
        --output text)
    fi
    
    echo "IP Address: $IP"
    
    # 4. Update Route53 DNS (skip frontend)
    if [ "$instance" != "frontend" ]; then
        RECORD_NAME="$instance.$DOMAIN_NAME"
        
        # Create JSON for Route53
        cat > /tmp/dns-update.json << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$RECORD_NAME",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$IP"}]
    }
  }]
}
EOF
        
        # Update DNS record
        aws route53 change-resource-record-sets \
        --hosted-zone-id $ZONE_ID \
        --change-batch file:///tmp/dns-update.json
        
        echo "✅ DNS Updated: $RECORD_NAME → $IP"
        rm -f /tmp/dns-update.json
    fi
    
    echo "===================================="
done
