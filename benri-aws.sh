#!/bin/sh
#できるだけbash依存しないで行こう！


benri_aws () {
  #TODO proxy t_benri_aws_*
  echo "not implemented."
}
_benri_aws_converter_to_snake () {
  echo "$1"|sed -e 's/\([A-Z]\)/-\1/g' -e 'y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/' -e 's/^-//'
}


_benri_aws_new_session () {
  session_key="${SESSION_PREFIX}_$(date +"%Y%m%d%H%M%S")"
  echo "session_key is $session_key"
  echo "$session_key" >>"session_${session_key}.log"
}

_benri_aws_set_tag_created () {
  #if you set $session_key and $group_key. there are used by tags for session and group.
  for _target in "$@"
  do
    _username=$(whoami)
    aws ec2 create-tags --resources "$_target" --tags "Key=created_by,Value=$_username"
    aws ec2 create-tags --resources "$_target" --tags "Key=session,Value=$session_key"
    aws ec2 create-tags --resources "$_target" --tags "Key=group,Value=$group_key"
    _date=$(date +"%Y%m%d%H%M%S")
    aws ec2 create-tags --resources $_target --tags "Key=created_at,Value=$_date"
    echo "$_target" >>"session_${session_key}.log"
  done
}

_benri_aws_describe_all () {
  
  for _key in $_BENRI_AWS_EC2_DESCRIBES_ALL
  do
    echo "###################################"
    echo "$_key"
    aws ec2 "$_key" "$@"
    
  done
  
}

#破壊的！作りかけ
_benri_aws_clear_all_under_vpc () {
  _vpc_id="$1"
  for _target in $_BENRI_AWS_ORDER_IN_VPC
  do
    :
  done
}
#わかりしだい増やす。作りかけ
_BENRI_AWS_ORDER_IN_VPC='instance:instances:Inctance:Inctances
security-group:security-groups:SecurityGroup:SecurityGroups
subnet:subnets:Subnet:Subnets
route_table:route_tables:RouteTable:RouteTables
network-acl:network-acls:NetworkAcl:NetworkAcls
vpc:vpcs:Vpc:Vpcs
'

_benri_aws_cleanup_security_group () {
  #security_groupのぱミッションをきれいにしようとします。失敗する時もありますディペンデンシーなどで。
  _group_id="$1"
  echo "clean up "
  
  _permission=$(aws ec2 describe-security-groups --output json --query '*[]|[?GroupId==`'$_group_id'`].IpPermissionsEgress|[]')
  if test -n "$_permission"
    then
    aws ec2 revoke-security-group-egress --group-id "$_id" --ip-permissions "$_permission" || return 1
  fi
  _permission=$(aws ec2 describe-security-groups --output json --query '*[]|[?GroupId==`'$_group_id'`].IpPermissions|[]')
  if test -n "$_permission"
    then
    aws ec2 revoke-security-group-ingress --group-id "$_id" --ip-permissions "$_permission" || return 1
  fi
}







#作りかけ
_benri_aws_name_to_plural () {
  _target_name="$1"
  _index=0
  for _names in $_BENRI_AWS_ORDER_IN_VPC
  do
    _name=
    if [ $_name == $_target_name ]
      then
      break
    fi
    _index=$( expr "$_index" + 1 )
  done
  
  
}
_BENRI_AWS_ORDER_IN_VPC_PLURAL='instances
security-groups
subnets
route_tables
network-acls
vpcs
'





## ex. _benri_aws_set_tags_to 'subnet-1234' 'Key=session,Value=12345'
_benri_aws_set_tags_to () {
  if [ $# -lt 2 ]
    then
    echo "ex. _benri_aws_set_tags_to 'subnet-1234' 'Key=session,Value=12345'"
    return -1
  fi
  _target="$1"
  shift
  aws ec2 create-tags --resources "$_target" --tags "$@"
}

#タグからルートテーブルを探す
_benri_aws_find_route_tables_by_tag () {
  #$1 key $2 name
  _tagkey=$1
  _tagvalue=$2
  
  _target="route-tables"
  _Target="RouteTables"
  _key_name_for_id="RouteTableId"
  
  aws ec2  "describe-$_target" --query "$(_part_of_tag_query $_tagkey $_tagvalue)|[].$_key_name_for_id"  --output text
}

#タグからインスタンスを探す
_benri_aws_find_instances_by_tag () {
  #$1 key $2 name
  _tagkey=$1
  _tagvalue=$2
  
  _target="instances"
  _Target="Instances"
  _key_name_for_id="InstanceId"
  
  
  _query=$(_benri_aws_query_builder_filter_by_tag "$_tagkey" "$_tagvalue")
  
  aws ec2  "describe-$_target" --query "*[]|"$(_benri_aws_query_builder_down_one_level)"|$_query|[]."$_key_name_for_id  --output text
}
_benri_aws_find_instances_by_name_tag () {
_tagkey='Name'
  _tagvalue=$1
  
  _target="instances"
  _Target="Instances"
  _key_name_for_id="InstanceId"
  
  
_query=$(_benri_aws_query_builder_filter_by_tag "$_tagkey" "$_tagvalue")
aws ec2  "describe-$_target" --query "*[]|"$(_benri_aws_query_builder_down_one_level)"|$_query|[]."$_key_name_for_id  --output text
}
#vpcidからインスタンスを探す
# _benri_aws_find_instances_by_vpcid () {
#   _vpcid="$1"
#   shift
#   _other_options="$@"
#   _target="instances"
#   _Target="Instances"
#   _key_name_for_id="InstanceId"
#   aws ec2  "describe-$_target" --query "*[]|"$(_benri_aws_query_builder_down_one_level)"|"$(_benri_aws_query_builder_get_object_from_list_by_vpcid "$_vpcid")  $_other_options
# }
_benri_aws_find_instance_ids_by_vpcid () {
_vpcid="$1"
# shift
# _other_options="$@"
_target="instances"
_Target="Instances"
_key_name_for_id="InstanceId"
aws ec2  "describe-$_target" --query "*[]|"$(_benri_aws_query_builder_down_one_level)"|"$(_benri_aws_query_builder_get_object_from_list_by_vpcid "$_vpcid")"|[].$_key_name_for_id"  --output text
}


# _benri_aws_find_by_vpcid_from_category () {
#   _vpcid=$1
#   _catregory=$2
#   
#   
# }

#vpcidと関連のあるものすべて
_benri_aws_find_all_by_vpcid () {
  _vpcid=$1
  shift
  echo "{"
  for _key in $_BENRI_AWS_EC2_SEARCH_TARGETS 
  do
    _query_str='*[]|[?VpcId==`'"$_vpcid"'`]'
    _ret=
    _ret=$(aws ec2 "$_key" --query "$_query_str" "$@" )
    if [ -n "$_ret" ]
      then
      
      echo "$_key : $_ret"
      echo ","
    else
      #階層を下げる
      _query_str='*[]|[].*|[]|[]|[?VpcId]|[?VpcId==`'"$_vpcid"'`]'
      _ret=$(aws ec2 "$_key" --query "$_query_str" "$@" )
      if [ -n "$_ret" ]
        then
        
        echo "$_key : $_ret"
        echo ","
      fi
      
    fi
  done
  echo "}"
}

_benri_aws_find_route_tables_by_vpcid () {
  _vpcid=$1
  
  _target="route-tables"
  _Target="RouteTables"
  _key_name_for_id="RouteTableId"
  
  aws ec2  "describe-$_target" --query "$_Target[?VpcId==\`$_vpcid\`].$_key_name_for_id" --output text
}

_benri_aws_find_object_by_tag () {
  _tagkey="$1"
  _tagvalue="$2"
  
  #ex. _target="route-tables"
  _target="$3"
  #ex. _Target="RouteTables"
  _Target="$4"
  #ex. _key_name_for_id="RouteTableId"
  _key_name_for_id="$5"
  
  aws ec2  "describe-$_target" --query "*[]|$(_benri_aws_query_builder_get_object_from_list_by_tag $_tagkey $_tagvalue)"  --output json
}
_benri_aws_find_object_by_key_value () {
  _key="$1"
  _value="$2"
  
  #ex. _target="route-tables"
  _target="$3"
  #ex. _Target="RouteTables"
  _Target="$4"
  #ex. _key_name_for_id="RouteTableId"
  _key_name_for_id="$5"
  
  aws ec2  "describe-$_target" --query "*[]|"$(_benri_aws_query_builder_get_object_from_list_by_key_value "$_key" "$_value")  --output json
}
_benri_aws_find_ids_by_key_value () {
  if [ $# -ne 5 ]
    then
    echo "ex. _benri_aws_find_ids_by_key_value GroupName sg-12345 security-groups  SecurityGroups SecurityGroupId"
    return -1
  fi
  _key="$1"
  _value="$2"
  
  #ex. _target="route-tables"
  _target="$3"
  #ex. _Target="RouteTables"
  _Target="$4"
  #ex. _key_name_for_id="RouteTableId"
  _key_name_for_id="$5"
  
  aws ec2  "describe-$_target" --query "*[]|"$(_benri_aws_query_builder_get_object_from_list_by_key_value "$_key" "$_value")"|[].$_key_name_for_id"   --output text
}
_benri_aws_find_ids_by_vpcid_and_key_value () {
  #instanceは対応していない
  if [ $# -ne 6 ]
    then
    echo "ex. _benri_aws_find_ids_by_key_value vpc-3333333 GroupName sg-12345 security-groups  SecurityGroups SecurityGroupId"
    return -1
  fi
  _vpcid="$1"
  _key="$2"
  _value="$3"
  #ex. _target="route-tables"
  _target="$4"
  #ex. _Target="RouteTables"
  _Target="$5"
  #ex. _key_name_for_id="RouteTableId"
  _key_name_for_id="$6"
  # '*[]|[?VpcId==`vpc-b913e0dc`]|[?Tags[?Key==`Name`]]|[?Tags[?Value==`humidai test`]]'
  _query="*[]|"$(_benri_aws_query_builder_get_object_from_list_by_vpcid "$_vpcid")"|"$(_benri_aws_query_builder_get_object_from_list_by_key_value "$_key" "$_value")"|[].$_key_name_for_id"
  aws ec2  "describe-$_target" --query "$_query" --output text
}
#v
_benri_aws_find_ids_by_tag () {
  if [ $# -ne 5 ]
    then
    echo "ex. _benri_aws_find_ids_by_tag test ttt vpcs Vpcs VpcId"
    return -1
  fi
  
  _tagkey="$1"
  _tagvalue="$2"
  
  #ex. _target="route-tables"
  _target="$3"
  #ex. _Target="RouteTables"
  _Target="$4"
  #ex. _key_name_for_id="RouteTableId"
  _key_name_for_id="$5"
  
  aws ec2  "describe-$_target" --query "*[]|$(_benri_aws_query_builder_get_object_from_list_by_tag $_tagkey $_tagvalue)|[].$_key_name_for_id"  --output text
}





#vpc配下にあるもの用
_benri_aws_find_ids_by_vpcid_and_tag () {
  if [ $# -ne 6 ]
    then
    echo "ex. _benri_aws_find_ids_by_tag vpc-123456 tagkey tagvalue subnets Subnets SubnetId"
    return -1
  fi
  _vpcid="$1"
  _tagkey="$2"
  _tagvalue="$3"
  
  #ex. _target="route-tables"
  _target="$4"
  #ex. _Target="RouteTables"
  _Target="$5"
  #ex. _key_name_for_id="RouteTableId"
  _key_name_for_id="$6"
  
  aws ec2  "describe-$_target" --query "*[]|"$(_benri_aws_query_builder_get_object_from_list_by_vpcid "$_vpcid")"|$(_benri_aws_query_builder_get_object_from_list_by_tag $_tagkey $_tagvalue)|[].$_key_name_for_id"  --output text
}







#依存関係を探すときの助けになるもの。
_benri_aws_ec2_search_id () {
  if [ $# -eq 0 ]
    then
    echo "require one id"
    return -1
  fi
  id=$1
  count=0
  echo "id:$id was found on ..."
  for key in ''$_BENRI_AWS_EC2_SEARCH_TARGETS 
  do
    #  aws ec2 "$key" |grep "$id" | wc -l
    count=$(aws ec2 "$key" 2>log |grep "$id" | wc -l) 
    # echo count
    if [ $count -ne 0 ]
      then
      echo "$key"
    fi
  done
  
}









#引数が必要なものは入っていない
_benri_aws_ec2_describe_all () {
  
  for key in ''$_BENRI_AWS_EC2_SEARCH_TARGETS 
  do
    aws ec2 "$key" "$@"
  done
  
}







##TODOもれがないか
_BENRI_AWS_EC2_SEARCH_TARGETS='describe-account-attributes
describe-addresses
describe-availability-zones
describe-bundle-tasks
describe-conversion-tasks
describe-customer-gateways
describe-dhcp-options
describe-export-tasks
describe-instances
describe-internet-gateways
describe-key-pairs
describe-network-acls
describe-network-interfaces
describe-placement-groups
describe-regions
describe-route-tables
describe-security-groups
describe-snapshots
describe-subnets
describe-tags
describe-volumes
describe-vpc-attribute
describe-vpc-peering-connections
describe-vpcs
describe-vpn-connections
describe-vpn-gateways
'

_BENRI_AWS_EC2_DESCRIBES_ALL='describe-account-attributes
describe-addresses
describe-availability-zones
describe-bundle-tasks
describe-conversion-tasks
describe-customer-gateways
describe-dhcp-options
describe-export-tasks
describe-images
describe-instance-status
describe-instances
describe-internet-gateways
describe-key-pairs
describe-network-acls
describe-network-interfaces
describe-placement-groups
describe-regions
describe-route-tables
describe-security-groups
describe-snapshots
describe-spot-instance-requests
describe-spot-price-history
describe-subnets
describe-tags
describe-volume-status
describe-volumes
describe-vpc-peering-connections
describe-vpcs
describe-vpn-connections
describe-vpn-gateways
'




#### 部分は今後filterという名前に変えていこうgetはそのまま使える形にしよう！
_benri_aws_query_builder_filter_base () {
  _query_str=
  if test -n "$BENRI_AWS_TARGET_VPC_ID"
    then
      _query_str=''$(_benri_aws_query_builder_get_object_from_list_by_vpcid "$BENRI_AWS_TARGET_VPC_ID")'|'
  fi
  echo $_query_str
}
_benri_aws_query_builder_filter_by_tag_() {
  _keyname=$1
  _value=$2
  _query_str=
  _query_str="[?Tags[?Key==\`$_keyname\`]][]|[?Tags[?Value==\`$_value\`]]"
  echo $_query_str
}
_benri_aws_query_builder_filter_by_tag () {
  _keyname=$1
  _value=$2
  _query_str=
  _query_str=$(_benri_aws_query_builder_filter_base)""$(_benri_aws_query_builder_filter_by_tag_ "$_keyname" "$_value" )
  echo $_query_str
}

_benri_aws_query_builder_filter_by_name_tag () {
  _keyname='Name'
  _value=$1
  _query_str=
  _query_str=$(_benri_aws_query_builder_filter_by_tag "$_keyname" "$_value" )
  echo $_query_str
}


#１階層下げる
_benri_aws_query_builder_down_one_level () {
  ##TODO テストまだ
  echo "[].*|[]|[]"
  # echo "[].*[?VpcId]|[]|[]" こっちのほうがいいか？
}



_benri_aws_query_builder_get_object_by_keyname () {
  ##TODO テストまだ
  _keyname="$1"
  echo "[?$_keyname]"
}


_benri_aws_query_builder_get_object_from_list_by_tag () {
  #配列が来ている仮定 たいていの場合このまえに *[]| などをつけるとよいかも
_query_str=$(_benri_aws_query_builder_filter_by_tag "$@")
echo $_query_str
}

_benri_aws_query_builder_get_object_from_list_by_key_value () {
  #配列が来ている仮定 たいていの場合このまえに *[]| などをつけるとよいかも
  _key="$1"
  _value="$2"
  _query_str='[?'"$_key"'==`'"$_value"'`]'
  echo "$_query_str"
}
_benri_aws_query_builder_get_vpcid_from_list_by_vpcid (){
  _query_str=$(_benri_aws_query_builder_get_object_from_list_by_vpcid "$1")"|[].VpcId"
}
_benri_aws_query_builder_get_object_from_list_by_vpcid () {
  #配列が来ている仮定 たいていの場合このまえに *[]| などをつけるとよいかも
  _vpcid="$1"
  # _query_str='[?VpcId==`'"$_vpcid"'`]'
  _query_str=$(_benri_aws_query_builder_get_object_from_list_by_key_value "VpcId" "$_vpcid")
  echo "$_query_str"
}
#上より1階層深い場所にある場合instanceなど。
_benri_aws_query_builder_get_object_from_list_by_vpcid_2 () {
  _query_str=''$(_benri_aws_query_builder_down_one_level)'|'$(_benri_aws_query_builder_get_object_from_list_by_vpcid "$@")''
  echo "$_query_str"
}

#インターフェイスのは考慮しない
_benri_aws_query_builder_get_instance_ids_by_security_group_name () {
  _vpcid="$1"
  _sg_name="$2"
  _query_str='*[]|'$(_benri_aws_query_builder_down_one_level)'|'$(_benri_aws_query_builder_get_object_from_list_by_vpcid "$_vpcid")'|[?SecurityGroups[?GroupName==`'"$_sg_name"'`]].InstanceId'
echo "$_query_str"
}

###filters
#BENRI_AWS_TARGET_VPC_IDでvpc絞り込み　暫定でここに仕込む


##for cloudformation
#論理IDで絞り込み
_benri_aws_query_builder_filter_by_logical_id () {
  _logical_id="$1"
  _query_str=''$(_benri_aws_query_builder_filter_by_tag 'aws:cloudformation:logical-id' $_logical_id)
  
  echo "$_query_str"
}
#論理IDでセキュリティーグループid取得 
_benri_aws_query_builder_get_security_group_id_by_logical_id () {
  __logical_id="$1"
  __query_str='*[]|'$(_benri_aws_query_builder_filter_by_tag 'aws:cloudformation:logical-id' $__logical_id)'.GroupId'
  echo "$__query_str"
}
_benri_aws_get_security_group_id_by_logical_id () {
  _logical_id="$1"
  _query_str=$(_benri_aws_query_builder_get_security_group_id_by_logical_id "$_logical_id")
  aws ec2 describe-security-groups --output text --query "$_query_str" 
}
#論理IDでセキュリティーグループid取得 
_benri_aws_query_builder_get_security_owner_id_by_logical_id () {
  __logical_id="$1"
  __query_str='*[]|'$(_benri_aws_query_builder_filter_by_tag 'aws:cloudformation:logical-id' $_logical_id)'.OwnerId'
  echo "$__query_str"
}
_benri_aws_get_security_owner_id_by_logical_id () {
  _logical_id="$1"
  _query_str=$(_benri_aws_query_builder_get_security_owner_id_by_logical_id "$_logical_id")
  aws ec2 describe-security-groups --output text --query "$_query_str" 
}
#Nameタグでセキュリティーグループid取得
_benri_aws_query_builder_get_security_group_id_by_name_tag () {
  __name="$1"
  __query_str='*[]|'$(_benri_aws_query_builder_filter_by_name_tag  $__name)'.GroupId'
  echo "$__query_str"
}


_benri_aws_get_security_group_id_by_name_tag () {
  _name="$1"
  # _benri_aws_query_builder_filter_by_name_tag
  _query_str=$(_benri_aws_query_builder_get_security_group_id_by_name_tag "$_name")
  aws ec2 describe-security-groups --output text --query "$_query_str" 
}


_benri_aws_query_builder_filter_internet_gateway_by_logical_id () {
  _query_vpc=
  if test -n "$BENRI_AWS_TARGET_VPC_ID"
    then
      _query_vpc='[?Attachments[?VpcId==`'"$BENRI_AWS_TARGET_VPC_ID"'`]]|'
  fi
  
  
  #InternetGatewayはVpcIdの場所が違うので気をつけること _benri_aws_query_builder_filter_by_tag_　をつかう最後のアンスコに注意
  _logical_id="$1"
  _query_str="$_query_vpc"$(_benri_aws_query_builder_filter_by_tag_ 'aws:cloudformation:logical-id' "$_logical_id")
  echo "$_query_str"
}
#internet gateway id取得
_benri_aws_get_internet_gateway_id_by_logical_id () {
  _query_vpc=
  if test -n "$BENRI_AWS_TARGET_VPC_ID"
    then
      _query_vpc='[?Attachments[?VpcId==`'"$BENRI_AWS_TARGET_VPC_ID"'`]]|'
  fi
  
  
  #InternetGatewayはVpcIdの場所が違うので気をつけること _benri_aws_query_builder_filter_by_tag_　をつかう最後のアンスコに注意
  _logical_id="$1"
  _query_str='*[]|'$(_benri_aws_query_builder_filter_internet_gateway_by_logical_id "$_logical_id")'.InternetGatewayId'
  aws ec2 describe-internet-gateways  --output text --query "$_query_str" 
}
#subnet id取得
_benri_aws_get_subnet_id_by_logical_id () {
  #InternetGateway
  _logical_id="$1"
  _query_str='*[]|'$(_benri_aws_query_builder_filter_by_logical_id "$_logical_id")'.SubnetId'
  aws ec2 describe-subnets  --output text --query "$_query_str" 
}
