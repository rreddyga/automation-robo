#!/bin/bash

# we need to check the root user or not 

USERId=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE=$LOGS_FOLDER/$0.log
R="\e[31m]"
G="\e[32m]"
Y="\e[33m]"
N="\e[0m]"

if [ $USERId -ne 0 ]; then
    echo "$R please run  this script  with the root user access $N" | tee -a $LOGS_FILE
    exit 1
fi
VALIDATE()
{
    if [ $1 -ne 0 ]; then
        echo "$2... $R Failure $N " | tee -a $LOGS_FILE
        exit 1
    else
        echo "$2... $G Success $N " | tee -a $LOGS_FILE
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying Mongo Repo" 

dnf install mongodb-org -y 
VALIDATE $? "Installing mongodb server"

systemctl enable mongod 
VALIDATE $? "Enabled mongod"
systemctl start mongod 
VALIDATE $? "start mongodb"

set -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections"

systemctl restart mongod
VALIDATE $? "Restart the mongod"
