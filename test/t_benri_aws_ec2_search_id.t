#!/bin/sh
test_description="benri-aws Test"
user_dir=~
AWS_CONFIG_FILE="$user_dir/.aws/config"
export AWS_CONFIG_FILE

# sh ../../benri-aws.sh
source '../benri-aws.sh'
. ./sharness.sh



test_expect_failure "no argument" '
_benri_aws_ec2_search_id
'
test_done
