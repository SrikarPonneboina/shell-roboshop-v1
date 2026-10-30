#!/bin/bash
#Setting up mongodb using shell script#

user_id=$(id -u)
logs_folder="/var/log/roboshop-logs"
logs_file="${logs_folder}/${0}.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
mkdir -p $logs_folder

if [ $user_id -ne 0 ]; then
    echo -e "${R}ERROR${N}: please run with root or sudo access" 
    exit 1
fi

timestamp(){
    date "+%F %T"
}

validate(){
    exit_status=$1
    description=$2
    if [ $exit_status -ne 0 ]; then
        echo -e "$(timestamp) [ERROR] ${description}..${R}FAILED${N}" | tee -a $logs_file
        exit 1
    else
        echo -e "$(timestamp) [INFO] ${description}..${G}SUCCESS${N}" | tee -a $logs_file
    fi
}
echo "$(timestamp) [INFO] ==== Script Started Execution ====" | tee -a $logs_file

cp mongodb.repo /etc/yum.repos.d/mongodb.repo 
validate $? "Adding mongo repo"

dnf install mongodb-org -y &>> $logs_file
validate $? "Installing mongodb"

systemctl enable mongod &>> $logs_file
systemctl start mongod &>> $logs_file
validate $? "Enable and start mongod service"

sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf &>> $logs_file
validate $? "updating remote connections to mongodb"

systemctl restart mongod &>> $logs_file
validate $? "Restart mongodb service"

echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution ====" | tee -a $logs_file

