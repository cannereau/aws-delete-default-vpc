# AWS Delete Default VPC
This Bash script delete all **non empty** Default VPC across AWS regions.

Before deleting VPC, the script
- check there is no EC2 instance hosted by the VPC
- delete all Internet Gateways attached to the VPC
- delete all non default Security Groups attached to the VPC
- delete all subnets hosted by the VPC

## Prerequisites
This script need
- [AWS CLI](https://docs.aws.amazon.com/fr_fr/cli/latest/userguide/cli-chap-welcome.html)

An AWS CLI profile for an AWS account must be registered using the command

    aws configure --profile MyAccount

## Usage
    delete_vpc.sh [--dry-run] --profile MyAccount

The **dry-run** option runs the script **without** deleting any resource
