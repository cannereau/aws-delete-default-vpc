#!/bin/bash

# colors
CDNGR='\033[0;31m'
CINFO='\033[0;36m'
CNOTE='\033[0;33m'
CNONE='\033[0m'

# retrieve parameters
profile=""
dryrun=""
while [ $# -gt 0 ]
do
    if [ $1 == "--dry-run" ]
    then
        dryrun="${CINFO}[dry-run]${CNONE}"
    elif [ $1 == "--profile" ]
    then
        declare profile="$2"
    fi
    shift
done

# check profile
if [ -z $profile ]
then
    echo -e "${CDNGR}Profile is missing !${CNONE}"
    echo -e "Usage : ${CNOTE}delete_vpc.sh [--dry-run] --profile${CNONE} MyAccount"
else
    # browse regions
    for region in `aws ec2 describe-regions \
                        --query 'Regions[].RegionName' \
                        --profile $profile \
                        --region eu-west-1 \
                        --output text`
    do
        # retrieve default vpc
        vpc=$(aws ec2 describe-vpcs \
                    --filters Name=isDefault,Values=true \
                    --query 'Vpcs[].VpcId' \
                    --profile $profile \
                    --region $region \
                    --output text)
        if [ -z $vpc ]
        then
            echo -e "No default VPC in $region"
        else
            echo -e "Found default VPC ${CNOTE}$vpc${CNONE} in $region"

            # check vpc content
            ec2=$(aws ec2 describe-instances \
                        --filters Name=vpc-id,Values=$vpc \
                        --query 'Reservations[*].Instances[*].InstanceId' \
                        --profile $profile \
                        --region $region \
                        --output text)
            if [ -z $ec2 ]
            then
                # delete internet gateways
                for ig in `aws ec2 describe-internet-gateways \
                                --filters Name=attachment.vpc-id,Values=$vpc \
                                --query 'InternetGateways[].InternetGatewayId' \
                                --profile $profile \
                                --region $region \
                                --output text`
                do
                    echo -e "Detaching et deleting internet gateway ${CNOTE}$ig${CNONE}... $dryrun"
                    if [ -z $dryrun ]
                    then
                        aws ec2 detach-internet-gateway \
                                --internet-gateway-id $ig \
                                --vpc-id $vpc \
                                --profile $profile \
                                --region $region
                        aws ec2 delete-internet-gateway \
                                --internet-gateway-id $ig \
                                --profile $profile \
                                --region $region
                    fi
                done

                # delete security groups
                for sg in `aws ec2 describe-security-groups \
                                --filters Name=vpc-id,Values=$vpc \
                                --query "SecurityGroups[?GroupName!='default'].GroupId" \
                                --profile $profile \
                                --region $region \
                                --output text`
                do
                    echo -e "Deleting security group ${CNOTE}$sg${CNONE}... $dryrun"
                    if [ -z $dryrun ]
                    then
                        aws ec2 delete-security-group \
                                --group-id $sg \
                                --profile $profile \
                                --region $region
                    fi
                done

                # delete subnets
                for subnet in `aws ec2 describe-subnets \
                                    --filters Name=vpc-id,Values=$vpc \
                                    --query 'Subnets[].SubnetId' \
                                    --profile $profile \
                                    --region $region \
                                    --output text`
                do
                    echo -e "Deleting subnet ${CNOTE}$subnet${CNONE}... $dryrun"
                    if [ -z $dryrun ]
                    then
                        aws ec2 delete-subnet \
                                --subnet-id $subnet \
                                --profile $profile \
                                --region $region
                    fi
                done

                # delete vpc
                echo -e "Deleting vpc ${CNOTE}$vpc${CNONE}... $dryrun"
                if [ -z $dryrun ]
                then
                    aws ec2 delete-vpc \
                            --vpc-id $vpc \
                            --profile $profile \
                            --region $region
                fi
            else
                echo -e "${CDNGR}There are instances in vpc $vpc !${CNONE}"
                echo -e "${CNOTE}*** Remove them before removing vpc ***${CNONE}"
            fi
        fi
    done
fi
