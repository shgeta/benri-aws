#!/bin/sh



benri_aws(){
  #TODproxy t_benri_aws_*
  echo "not implemented."
}
## ex. _benri_aws_set_tags_to 'subnet-1234' 'Key=session,Value=12345'
_benri_aws_set_tags_to(){
  if [ $# -lt 2]
    then
    echo "ex. _benri_aws_set_tags_to 'subnet-1234' 'Key=session,Value=12345'"
    return -1
  fi
  _target="$1"
  shift
    aws ec2 create-tags --resources "$_target" --tags "$@"
}

#タグからルートテーブルを探す
_benri_aws_find_route_tables_by_tag(){
  #$1 key $2 name
  _tagkey=$1
  _tagvalue=$2
  
  _target="route-tables"
  _Target="RouteTables"
  _key_name_for_id="RouteTableId"
  
  aws ec2  "describe-$_target" --query "$(_part_of_tag_query $_tagkey $_tagvalue)|[].$_key_name_for_id"  --output text
}

#タグからインスタンスを探す
_benri_aws_find_instances_by_tag(){
  #$1 key $2 name
  _tagkey=$1
  _tagvalue=$2
  
  _target="instances"
  _Target="Instances"
  _key_name_for_id="InstanceId"
  aws ec2  "describe-$_target" --query "*[].$_Target[?Tags[?Key==\`$_tagkey\`]][]|[?Tags[?Value==\`$_tagvalue\`]]|[].$_key_name_for_id"  --output text
}

_benri_aws_find_route_tables_by_vpcid(){
#$1 key $2 name
_vpcid=$1

_target="route-tables"
_Target="RouteTables"
_key_name_for_id="RouteTableId"

 aws ec2  "describe-$_target" --query "$_Target[?VpcId==\`$_vpcid\`].$_key_name_for_id" --output text
 }
 
 _benri_aws_find_something_by_tag(){
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
 _benri_aws_find_ids_by_tag(){
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
#依存関係を探すときの助けになるもの。
_benri_aws_ec2_search_id(){
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
# _BENRI_AWS_EC2_SEARCH_TARGETS='describe-account-attributes
# describe-addresses
# describe-availability-zones
# describe-bundle-tasks
# describe-conversion-tasks
# describe-customer-gateways
# describe-dhcp-options
# describe-export-tasks
# describe-image-attribute
# describe-images
# describe-instance-attribute
# describe-instance-status
# describe-instances
# describe-internet-gateways
# describe-key-pairs
# describe-network-acls
# describe-network-interface-attribute
# describe-network-interfaces
# describe-placement-groups
# describe-regions
# describe-reserved-instances
# describe-reserved-instances-listings
# describe-reserved-instances-modifications
# describe-reserved-instances-offerings
# describe-route-tables
# describe-security-groups
# describe-snapshot-attribute
# describe-snapshots
# describe-spot-datafeed-subscription
# describe-spot-instance-requests
# describe-spot-price-history
# describe-subnets
# describe-tags
# describe-volume-attribute
# describe-volume-status
# describe-volumes
# describe-vpc-attribute
# describe-vpc-peering-connections
# describe-vpcs
# describe-vpn-connections
# describe-vpn-gateways
# '


_benri_aws_query_builder_get_object_from_list_by_tag(){
  #配列が来ている仮定 たいていの場合このまえに *[]| などをつけるとよいかも
  _keyname=$1
  _value=$2
  echo "[?Tags[?Key==\`$_keyname\`]][]|[?Tags[?Value==\`$_value\`]]"
}
