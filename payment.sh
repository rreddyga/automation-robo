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
MYSQL_HOST="mysql.sanathananelaform.online"

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

dnf install python3 gcc python3-devel -y &>>LOGS_FILE
VALIDATE $? "Installing maven "

id roboshop 
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>LOGS_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "Roboshop user already exist... $Y SKIPPING $N "
fi

mkdir -p /app # if folder exists it will not create otherwise it will create  
VALIDATE $? "Creating app directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>LOGS_FILE
VALIDATE $? "downloading the payment zip code"

cd /app 
VALIDATE $? "Chaning the directory ->app"

rm -rf /app/*
VALIDATE $? "Removing the existing code"
unzip /tmp/shipping.zip
VALIDATE $? "Unzipping the shipping code"

cd /app 
pip3 install -r requirements.txt
VALIDATE $? "Installing dependencies"
