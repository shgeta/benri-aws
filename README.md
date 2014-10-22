benri-aws
=========


### ec2のdescribeの中からidを探す。

*  _benri_aws_ec2_search_id <some id>

  ex. _benri_aws_ec2_search_id vpc-12345f

### tag のkey valueを使ってインスタンスを探す。

* _benri_aws_find_instances_by_tag <tag key name> <tag value>

  ex. _benri_aws_find_instances_by_tag 'session' '12345'
