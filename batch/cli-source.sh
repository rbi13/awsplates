#!/usr/bin/env bash

### Params
codeBucket='bnsdscode'
fileBucket='bnsdsfileprocessing'
fileNotif='notification.json'
queueName='jobQueue'
queueUrl='https://us-west-2.queue.amazonaws.com/448132366281/jobQueue'
lambdaProjectDir='lambda'
lambdaBuildDir='build/distributions'
lambdaArchiveName='S3FileScheduler-0.0.1.zip'
lambdaName='jobScheduler'

stackFile='batch.yml'

### Compute Stack (cloud formation)
create-compute-stack(){
	aws cloudformation create-stack \
		--stack-name $1 \
		--template-body "file://${stackFile}"
}
delete-compute-stack(){
	aws cloudformation delete-stack \
		--stack-name $1
}

### lambda functions
lm-create(){
     aws lambda create-function \
        --function-name ${lambdaName} \
        --runtime  'java8' \
        --role  'arn:aws:iam::448132366281:role/lambda-exec' \
        --handler 'io.rbi.aws.lambda.scheduling.S3FileScheduler' \
        --code "S3Bucket=${codeBucket}, S3Key=${lambdaArchiveName}"

    aws lambda add-permission \
        --function-name ${lambdaName} \
        --statement-id "jobScheduler" \
        --action "lambda:InvokeFunction" \
        --principal s3.amazonaws.com \
        --timeout 20
}

lm-update-code(){
    cd ${lambdaProjectDir}
    gradle bZ
    s3-lambda-upload "${lambdaBuildDir}/${lambdaArchiveName}"
     aws lambda update-function-code \
        --function-name ${lambdaName} \
        --s3-bucket ${codeBucket} \
        --s3-key ${lambdaArchiveName}
}

lm-update-config(){
 aws lambda update-function-configuration \
    --function-name ${lambdaName} \
    --memory-size 256 \
    --timeout 20
}

sq-create(){
    aws sqs create-queue --queue-name ${queueName}
}

sq-receive(){
    aws sqs receive-message \
        --queue-url ${queueUrl} \
        --wait-time-seconds 3 \
        --query Messages[0].[Body,ReceiptHandle]
}

### Bucket Functions
s3-create(){
	aws s3 mb "s3://${codeBucket}" 
	aws s3 mb "s3://${fileBucket}" 
}
s3-configure(){
    # TODO: arn currently hardcoded in json config
    aws s3api put-bucket-notification-configuration \
        --bucket ${fileBucket} \
        --notification-configuration "file://${fileNotif}"
}
# named based, single-file uploading
s3-upload(){ aws s3 cp "$1" "s3://${fileBucket}/uploads/solo/$(basename $1)" ;}
# time based, batched uploading
s3-dir-upload(){ aws s3 sync . "s3://${fileBucket}/uploads/$(date +%s%3N)" ;}
# clear upload section
s3-clr-uploads(){ aws s3 rm --recursive "s3://${fileBucket}/uploads" ;}
# code upload
s3-lambda-upload(){ aws s3 cp "$1" "s3://${codeBucket}/$(basename $1)" ;}

