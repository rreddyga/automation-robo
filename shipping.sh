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

dnf install maven -y &>>
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

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>LOGS_FILE
VALIDATE $? "downloading the shipping zip code"

cd /app 
VALIDATE $? "Chaning the directory ->app"

rm -rf /app/*
VALIDATE $? "Removing the existing code"
unzip /tmp/shipping.zip
VALIDATE $? "Unzipping the shipping code"

cd /app 
mvn clean package  &>>LOGS_FILE
VALIDATE $? "Installing and buildin the package"

mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "Moving and renaming shipping jar"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Created the systemctl shipping service"

dnf install mysql -y &>>LOGS_FILE
VALIDATE &? "Installing mysql database"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities'
if [ $? -ne 0]; then

    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql 
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql
    VALIDATE $? "Loaded data into mysql"
else
    echo -e "data is already loaded ... $Y  SKIPPING $N "
systemctl enable shipping 
VALIDATE $? "Enabling shipping"
systemctl start shipping
VALIDATE $? "starting the shipping"
