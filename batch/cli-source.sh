#!/usr/bin/env bash

### Params
codeBucket='bns.ds.code'
fileBucket='bns.ds.fileprocessing'
fileNotif='notification.json'
stackFile='batch.yml'

### Compute Stack (cloud formation)
create-compute-stack() {
	aws cloudformation create-stack \
		--stack-name $1 \
		--template-body "file://${stackFile}"
}
delete-compute-stack() {
	aws cloudformation delete-stack \
		--stack-name $1
}

### Bucket Functions
s3-create() {
	aws s3 mb "s3://${codeBucket}" 
	aws s3 mb "s3://${fileBucket}" 
}
s3-configure() {
    aws lambda add-permission \
        --function-name test2-jobScheduler-1F5WATPRINQ6Z \
        --statement-id "jobScheduler" \
        --action "lambda:InvokeFunction" \
        --principal s3.amazonaws.com

    # TODO: arn currently hardcoded in json config
    aws s3api put-bucket-notification-configuration \
        --bucket ${fileBucket} \
        --notification-configuration "file://${fileNotif}"
}
# named based, single-file uploading
s3-upload() { aws s3 cp "$1" "s3://${fileBucket}/uploads/solo/$(basename $1)" ;}
# time based, batched uploading
s3-dir-upload() { aws s3 sync . "s3://${fileBucket}/uploads/$(date +%s%3N)" ;}
# clear upload section
s3-clr-uploads() { aws s3 rm --recursive "s3://${fileBucket}/uploads" ;}
# code upload
s3-lambda-upload() { aws s3 cp "$1" "s3://${codeBucket}/$(basename $1)" ;}

