#!/bin/sh
test_description="benri-aws Test"
user_dir=~
AWS_CONFIG_FILE="$user_dir/.aws/config"
export AWS_CONFIG_FILE

# sh ../../benri-aws.sh
source '../benri-aws.sh'
. ./sharness.sh

AZ1="ap-northeast-1a"
AZ2="ap-northeast-1c"

test_expect_failure "_benri_aws_ec2_search_id　no argument" '
_benri_aws_ec2_search_id
'

test_expect_success "_benri_aws_find_instances_by_tag" '

_benri_aws_find_instances_by_tag
'

test_expect_success "_benri_aws_find_route_tables_by_vpcid" '
_vpcid=$(aws ec2 describe-vpcs --query "Vpcs[?IsDefault==\`true\`].VpcId" --output text)
_route_table_ids=$(_benri_aws_find_route_tables_by_vpcid $_vpcid) &&
test -n _route_table_ids

'
test_expect_success "_benri_aws_find_route_tables_by_tag" '
_vpcid=$(aws ec2 describe-vpcs --query "Vpcs[?IsDefault==\`true\`].VpcId" --output text)
_id=$(aws ec2 create-route-table --vpc-id $vpcid --query "*.RouteTableId" --output text) &&
_route_table_ids=$(_benri_aws_find_route_tables_by_tag "session" "sessionkey") &&
aws ec2 delete-route-table --route-table-id "$_id"
test -n _route_table_ids

'
test_expect_success "_benri_aws_find_ids_by_tag" '
_cidr_block="192.168.0.0/16" &&
_vpcid=$(aws ec2 create-vpc --cidr-block $_cidr_block --query "Vpc.VpcId" --output text) &&
_benri_aws_set_tags_to "$_vpcid" "Key=test,Value=_benri_aws_find_ids_by_tag" 

_ids=$(_benri_aws_find_ids_by_tag "test" "_benri_aws_find_ids_by_tag" "vpcs" "Vpcs" "VpcId")
aws ec2 delete-vpc --vpc-id "$_vpcid" 
test "$_vpcid" == "$_ids"

'
test_expect_success "_benri_aws_find_instance_ids_by_vpcid" '
_cidr_block="192.168.0.0/16"
_vpcid=$(aws ec2 create-vpc --cidr-block $_cidr_block --query "Vpc.VpcId" --output text) &&
_benri_aws_set_tags_to "$_vpcid" "Key=test,Value=_benri_aws_find_instance_ids_by_vpcid" &&
_cidr_block="192.168.15.0/25" &&
_subnet_id=$(aws ec2 create-subnet --vpc-id "$_vpcid" --cidr "$_cidr_block" --availability-zone $AZ1 --query "Subnet.SubnetId" --output text) &&
_benri_aws_set_tags_to "$_subnet_id" "Key=test,Value=_benri_aws_find_ids_by_tag" &&
  _img_id="ami-29dc9228" &&
  _instance_type="t2.micro" &&
  _i_id=$(aws ec2 run-instances --image-id "$_img_id" \
  --subnet-id "$_subnet_id" \
  --instance-type $_instance_type\
  --query "Instances|[].InstanceId"\
  --output text) &&
_ids=$(_benri_aws_find_instance_ids_by_vpcid "$_vpcid")  &&
aws ec2 terminate-instances --instance-ids $_i_id >>log
aws ec2 delete-subnet --subnet-id $_subnet_id >>log

aws ec2 delete-vpc --vpc-id "$_vpcid" >>log
test "$_vpcid" == "$_ids"

'

_create_security_group () {
  if test -z "$vpcid" 
    then
    echo 'you need set $vpcid. like "vpcid=vpc12345"'
    return -1
  fi
  _vpcid="$vpcid"
  _group_name="$1"
  
  _id=$(aws ec2 create-security-group --vpc-id "$_vpcid" --group-name "$_group_name" --description "for test" --query "GroupId" --output text) &&
  _set_tag_created "$_id" 
  
  echo "$_id"
}

test_expect_success "_benri_aws_find_ids_by_vpcid_and_key_value" '
_cidr_block="192.168.0.0/16" &&
_vpcid=$(aws ec2 create-vpc --cidr-block $_cidr_block --query "Vpc.VpcId" --output text 2>log) &&
_benri_aws_set_tags_to "$_vpcid" "Key=test,Value=_benri_aws_find_ids_by_vpcid_and_key_value" >>log
_ids=$(_benri_aws_find_ids_by_vpcid_and_key_value "$_vpcid" "VpcId" "$_vpcid" "vpcs" "Vpcs" "VpcId" 2>>log)
vpcid="$_vpcid"
_group_name="fortest"
_sg_id=$(_create_security_group "$_group_name" 2>>log)
_ids=$(_benri_aws_find_ids_by_vpcid_and_key_value "$_vpcid" "GroupName" "$_group_name" "security-groups" "SecurityGroups" "SecurityGroupId" 2>>log)


aws ec2 delete-security-group --group-id "$_sg_id" >>log
aws ec2 delete-vpc --vpc-id "$_vpcid" >>log

echo "$_vpcid $_ids $_sg_id"
test "$_vpcid" == "$_ids" &&
test "$_sg_id" == "$_ids"

'


test_done
