#!/bin/bash

# we need to check the root user or not 

USERId=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE=$LOGS_FOLDER/$0.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

SCRIPT_DIR=$PWD
MONGODB_HOST="mongodb.sanathananelaform.online"

if [ $USERId -ne 0 ]; then
    echo -e "$R please run  this script  with the root user access $N" | tee -a $LOGS_FILE
    exit 1
fi
VALIDATE()
{
    if [ $1 -ne 0 ]; then
        echo -e "$2... $R Failure $N " | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2... $G Success $N " | tee -a $LOGS_FILE
    fi
}

dnf module disable nodejs -y &>>LOGS_FILE
VALIDATE $? "Disabling nodejs default versions"

dnf module enable nodejs:20 -y &>>LOGS_FILE
VALIDATE $? "Enabling nodejs 20 version"

dnf install nodejs -y &>>LOGS_FILE
VALIDATE $? "Installing nodejs "

id roboshop 
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>LOGS_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "Roboshop user already exist... $Y SKIPPING $N "
fi

mkdir -p /app # if folder exists it will not create otherwise it will create  
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>LOGS_FILE
VALIDATE $? "downloading the catalogue zip code"

cd /app 
VALIDATE $? "Chaning the directory ->app"

rm -rf /app/*
VALIDATE $? "Removing the existing code"
unzip /tmp/catalogue.zip
VALIDATE $? "Unzipping the catalogue code"

npm install &>>LOGS_FILE
VALIDATE $? "installing npm dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Created the systemctl catalogue service"

systemctl daemon-reload
systemctl enable catalogue 
systemctl start catalogue
VALIDATE $? "Starting catalogue "

cp $SCRIPT_DIR/mongo.rep /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongosh -y
VALIDATE $? "Installing mongodb-mongosh"

#to check the mongodb schema loaded or not
DB_INDEX=$(mongosh --host $MONGODB_HOST --quiet --eval 'db.getMongo().getDBNames().indexOf('catalogue')')
if [ DB_INDEX -le 0]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js
    VALIDATE $? "Loading the products"
else
    echo -e "Products already loaded... $Y SKIPPING $N"
fi

systemctl restart catalogue
VALIDATE $? "restart catalogue"