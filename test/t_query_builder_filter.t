#!/bin/sh
test_description="benri-aws Test"
user_dir=~
AWS_CONFIG_FILE="$user_dir/.aws/config"
export AWS_CONFIG_FILE

source '../benri-aws.sh'
. ./sharness.sh

# _benri_aws_query_builder_filter_by_tag () {
#   _keyname=$1
#   _value=$2
#   _query_str=$(_benri_aws_query_builder_filter_base)"[?Tags[?Key==\`$_keyname\`]][]|[?Tags[?Value==\`$_value\`]]"
#   echo $_query_str
# }


test_expect_success "_benri_aws_find_instances_by_tag not set BENRI_AWS_TARGET_VPC_ID" '
unset BENRI_AWS_TARGET_VPC_ID
_query=$(_benri_aws_query_builder_filter_by_tag)
test "[?Tags[?Key==\`\`]][]|[?Tags[?Value==\`\`]]" == "$_query"
'

test_expect_success "_benri_aws_find_instances_by_tag  set brank to BENRI_AWS_TARGET_VPC_ID" '
BENRI_AWS_TARGET_VPC_ID=
_query=$(_benri_aws_query_builder_filter_by_tag)
test "[?Tags[?Key==\`\`]][]|[?Tags[?Value==\`\`]]" == "$_query"
'

test_expect_success "_benri_aws_find_instances_by_tag set BENRI_AWS_TARGET_VPC_ID" '
BENRI_AWS_TARGET_VPC_ID="test"
_query=$(_benri_aws_query_builder_filter_by_tag)
test "[?VpcId==\`test\`]|[?Tags[?Key==\`\`]][]|[?Tags[?Value==\`\`]]" == "$_query"
'

test_expect_success "_benri_aws_find_instances_by_tag set BENRI_AWS_TARGET_VPC_ID 複数回よんでもただしい" '
_query=
BENRI_AWS_TARGET_VPC_ID="test"
_query=$(_benri_aws_query_builder_filter_by_tag >/dev/null; _benri_aws_query_builder_filter_by_tag)
test "[?VpcId==\`test\`]|[?Tags[?Key==\`\`]][]|[?Tags[?Value==\`\`]]" == "$_query"
'

test_expect_success "_benri_aws_find_instances_by_tag set BENRI_AWS_TARGET_VPC_ID and remove it." '
{
  BENRI_AWS_TARGET_VPC_ID="test"
  _query=$(_benri_aws_query_builder_filter_by_tag)
  test "[?VpcId==\`test\`]|[?Tags[?Key==\`\`]][]|[?Tags[?Value==\`\`]]" == "$_query"
} &&
{
  BENRI_AWS_TARGET_VPC_ID=
  _query=$(_benri_aws_query_builder_filter_by_tag)
  test "[?Tags[?Key==\`\`]][]|[?Tags[?Value==\`\`]]" == "$_query"
}
'
test_expect_success "_benri_aws_query_builder_filter_internet_gateway_by_logical_id no vpc no arg" '
_query=
BENRI_AWS_TARGET_VPC_ID="test"
_query=$(_benri_aws_query_builder_filter_internet_gateway_by_logical_id >/dev/null ; _benri_aws_query_builder_filter_internet_gateway_by_logical_id)
echo $_query >>_query_benri_aws_query_builder_filter_internet_gateway_by_logical_id
test "[?Attachments[?VpcId==\`test\`]]|[?Tags[?Key==\`aws:cloudformation:logical-id\`]][]|[?Tags[?Value==\`\`]]" == "$_query"
'
test_expect_success "_benri_aws_query_builder_filter_internet_gateway_by_logical_id no vpc " '
_query=
BENRI_AWS_TARGET_VPC_ID="test"
_query=$(_benri_aws_query_builder_filter_internet_gateway_by_logical_id >/dev/null ; _benri_aws_query_builder_filter_internet_gateway_by_logical_id ppp)
echo $_query >>_query_benri_aws_query_builder_filter_internet_gateway_by_logical_id
test "[?Attachments[?VpcId==\`test\`]]|[?Tags[?Key==\`aws:cloudformation:logical-id\`]][]|[?Tags[?Value==\`ppp\`]]" == "$_query"
'
test_expect_success "_benri_aws_query_builder_filter_internet_gateway_by_logical_id vpc no arg" '
_query=
BENRI_AWS_TARGET_VPC_ID=
_query=$(_benri_aws_query_builder_filter_internet_gateway_by_logical_id >/dev/null ; _benri_aws_query_builder_filter_internet_gateway_by_logical_id)
echo $_query >>_query_benri_aws_query_builder_filter_internet_gateway_by_logical_id
test "[?Tags[?Key==\`aws:cloudformation:logical-id\`]][]|[?Tags[?Value==\`\`]]" == "$_query"
'

# _benri_aws_get_internet_gateway_id_by_logical_id
# _benri_aws_query_builder_filter_internet_gateway_by_logical_id
# [?Tags[?Key==`aws:cloudformation:logical-id`]][]|[?Tags[?Value==``]]
test_done
