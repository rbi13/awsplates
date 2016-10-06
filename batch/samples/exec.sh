#!/usr/bin/env bash

#config
queue='https://us-west-2.queue.amazonaws.com/448132366281/jobQueue'
region='us-west-2'
resultBucket='bnsdsresults'

inputDir='.'
outputDir='.'

receipt_handle=''

process-file(){
    while [ /bin/true ]; do
        message=$( \
            aws sqs receive-message \
                --queue-url ${queue} \
                --region ${region} \
                --wait-time-seconds 10 \
                --query Messages[0].[Body,ReceiptHandle] \
            | sed -e 's/^"\(.*\)"$/\1/'
        )
        echo $message

        if [ $message == "null" ]; then
            echo "No messages left in queue. Exiting."
            exit 0
        fi
        receipt_handle=$(echo ${message} | sed -e 's/^.*"\([^"]*\)"\s*\]$/\1/')
        echo "Receipt handle: ${receipt_handle}."
        bucket=$(echo ${message} | sed -e 's/^.*arn:aws:s3:::\([^\\]*\)\\".*$/\1/')
        echo "Bucket: ${bucket}."
        key=$(echo ${message} | sed -e 's/^.*\\"key\\":\s*\\"\([^\\]*\)\\".*$/\1/')
        echo "Key: ${key}."

        getFile ${bucket} ${key}
        # do stuff
        writeResultFile $(basename ${key})
    done
}

getFile(){
    bucket=$1; key=$2;
    aws s3 cp "s3://${bucket}/${key}" ${inputDir}
}
writeResultFile(){
    key=$1
    aws s3 cp "${outputDir}/${key}" "s3://${resultBucket}/${key}"
    markMsg
}

markMsg(){
    aws sqs delete-message \
        --queue-url ${queue} \
        --region ${region} \
        --receipt-handle "${receipt_handle}"
    receipt_handle=''
}

# exec
process-file