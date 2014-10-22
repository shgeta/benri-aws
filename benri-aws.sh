#!/bin/sh



benri_aws(){
  #TODproxy t_benri_aws_*
  echo "not implemented."
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
