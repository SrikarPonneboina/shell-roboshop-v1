#!/bin/bash
#Setting up catalogue using shell script#

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

dnf module disable nodejs -y &>> $logs_file
dnf module enable nodejs:24 -y &>> $logs_file
dnf install nodejs -y &>> $logs_file
validate $? "Installing nodejs"

node -v
validate $? "checking nodejs version"

id roboshop &>> $logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "creating system user"
else
    echo -e "$(timestamp) [INFO] System user roboshop already exist..${Y}SKIPPING${N}"
fi

rm -rf /app
validate $? "removing old code from the app directory"

mkdir -p /app
validate $? "creating app directory"

curl -L -o /tmp/catalogue.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/catalogue-v4.zip
validate $? "downloading catalogue"

cd /app
unzip /tmp/catalogue.zip &>> $logs_file
validate $? "unzipping catalogue"

npm install &>> $logs_file
validate $? "installing dependencies"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$script_dir/catalogue.service"
cp "$script_dir/catalogue.service" /etc/systemd/system/catalogue.service
validate $? "creating catalogue service file"

systemctl daemon-reload &>> $logs_file
systemctl enable catalogue &>> $logs_file
systemctl start catalogue &>> $logs_file
validate $? "Enable and start service"

cp "$script_dir/mongodb.repo" /etc/yum.repos.d/mongodb.repo
validate $? "Adding mongodb repo"

dnf install mongodb-mongosh -y &>> $logs_file
validate $? "Downloading mongodb client"

product_count=$(mongosh --host mongodb.$domain_name --quiet --eval 'db.getSiblingDB("catalogue").products.countDocuments()')
validate $? "Connecting to mongodb"

if [ $product_count -eq 0 ]; then
    mongosh --host mongodb.$domain_name </app/db/master-data.js &>> $logs_file
    validate $? "Loading the data"
else
    echo -e "$(timestamp) [INFO] Products already exists.. ${Y}SKIPPING${N}"
fi

systemctl restart catalogue &>> $logs_file
validate $? "Restarting Catalogue"

echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution ====" | tee -a $logs_file
