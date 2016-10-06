package io.rbi.aws.lambda.scheduling;

import com.amazonaws.services.ecs.AmazonECSClientBuilder;
import com.amazonaws.services.ecs.model.RunTaskRequest;
import com.amazonaws.services.ecs.model.RunTaskResult;
import com.amazonaws.services.ecs.model.StartTaskRequest;
import com.amazonaws.services.ecs.model.StartTaskResult;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.S3Event;

import com.amazonaws.services.sqs.AmazonSQSClient;
import com.amazonaws.services.sqs.model.SendMessageRequest;

import java.io.UnsupportedEncodingException;

/**
 * Lambda function triggered by the creation of objects in S3
 * which in turn starts a container for processing the file.
 *
 * Logging is done through stdout; each line is logged as a
 * separate event in cloudwatch.
 *
 * Created by ron on 04/10/16.
 */
public class S3FileScheduler implements
        RequestHandler<S3Event, String> {

    // TODO: move to proper config
    // config
    static String QUEUE_URL="https://us-west-2.queue.amazonaws.com/448132366281/jobQueue";
    // TODO: switch to <family:revision> probably easier
    static String TASK_DEFINITION="arn:aws:ecs:us-west-2:448132366281:task-definition/kaldi:4";
    // TODO: switch to <family:revision> probably easier
    static String CLUSTER="kaldi-cluster";
    // TODO: switch to <family:revision> probably easier
    static String CLUSTER_INSTANCE="i-0612118517e768b04";

    @Override
    public String handleRequest(S3Event event, Context context) {
        try {
            publishJob(event);
            startProcessor();
        } catch (UnsupportedEncodingException e) {
            return e.getMessage();
        }
        return event.toJson();
    }

    /**
     * publishes message to SQS job queue
     * @param event - S3 creation event
     */
    static void publishJob(S3Event event) throws UnsupportedEncodingException {
        new AmazonSQSClient().sendMessage(
            new SendMessageRequest()
                .withQueueUrl(QUEUE_URL)
                .withMessageBody( event.toJson() )
        );
    }

    /**
     * start processor for queue processing
     */
    static void startProcessor(){
        RunTaskResult res = AmazonECSClientBuilder.defaultClient()
                .runTask(
                    new RunTaskRequest()
                        .withTaskDefinition(TASK_DEFINITION)
                );
        res.getFailures().stream().forEach(f -> System.out.println(f));
        System.out.println(res.getTasks());
    }
}
