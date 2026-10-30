#!/bin/bash
#Setting up payment using shell script#

user_id=$(id -u)
logs_folder="/var/log/roboshop-logs"
logs_file="${logs_folder}/${0}.log"
script_dir=$(dirname "$(realpath "$0")") 
#script_dir this variable becomes /home/ec2-user/shell-roboshop-v1 and 
#locks it here and where ever it sees $script_dir it shows /home/ec2-user/shell-roboshop-v1
domain_name="srikarlabs.space"
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

dnf module disable nginx -y &>>$logs_file
dnf module enable nginx:1.26 -y &>>$logs_file
dnf install nginx -y &>>$logs_file
validate $? "Installing nginx"

systemctl enable nginx &>>$logs_file
systemctl start nginx &>>$logs_file
validate $? "Enable and start nginx"

rm -rf /usr/share/nginx/html/* &>>$logs_file
validate $? "Removing default nginx content"

curl -L -o /tmp/frontend.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/frontend-v4.zip &>>$logs_file
cd /usr/share/nginx/html &>> $logs_file
unzip /tmp/frontend.zip &>> $logs_file
validate $? "Downloading and unzipping frontend code"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$script_dir/roboshop.conf"
cp "$script_dir/roboshop.conf" /etc/nginx/default.d/roboshop.conf
validate $? "Copied roboshop config"

nginx -t &>> $logs_file
validate $? "Nginx Configuration"

systemctl restart nginx
validate $? "Restarting nginx"

echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $logs_file

