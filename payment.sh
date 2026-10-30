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

dnf install python3.14 python3.14-pip -y &>> $logs_file
validate $? "Installing Python 3.14"

id roboshop &>> $logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $logs_file
    validate $? "Creating system user"
else
    echo -e "$(timestamp) [INFO] System user roboshop already exist...${Y}SKIPPING${N}"
fi

rm -rf /app
validate $? "Removing old code"

mkdir -p /app
validate $? "Creating app directory"

curl -L -o /tmp/payment.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/payment-v4.zip &>> $logs_file
validate $? "Downloading payment"

cd /app
unzip /tmp/payment.zip &>> $logs_file
validate $? "Unzipping payment"

python3.14 -m venv /app/.venv &>> $logs_file
validate $? "Creating virtual environment"

/app/.venv/bin/pip install -r requirements.txt &>> $logs_file
validate $? "Installing dependencies"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$script_dir/payment.service"
cp "$script_dir/payment.service" /etc/systemd/system/payment.service

systemctl daemon-reload &>> $logs_file
systemctl enable payment &>> $logs_file
systemctl restart payment &>> $logs_file
validate $? "Starting/Restaring payment"


echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $logs_file

