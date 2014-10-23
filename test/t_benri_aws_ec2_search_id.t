#!/bin/sh
test_description="benri-aws Test"
user_dir=~
AWS_CONFIG_FILE="$user_dir/.aws/config"
export AWS_CONFIG_FILE

# sh ../../benri-aws.sh
source '../benri-aws.sh'
. ./sharness.sh



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
test_done
