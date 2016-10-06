package io.rbi.aws.lambda.scheduling;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.S3Event;
import static com.amazonaws.services.s3.event.S3EventNotification.S3EventNotificationRecord;
import static java.net.URLDecoder.decode;

import com.amazonaws.services.sqs.AmazonSQSClient;
import com.amazonaws.services.sqs.model.SendMessageRequest;

import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;

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

    // config
    static String QUEUE_URL="https://us-west-2.queue.amazonaws.com/448132366281/jobQueue";

    @Override
    public String handleRequest(S3Event event, Context context) {
        try {
            publishJob(event);
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
                .withMessageBody( toMsg(event) )
        );
    }

    /**
     * Turns S3 event to job message used by processing container.
     * @param event - S3 creation event
     * @return message containing bucket and key for pending job
     * @throws UnsupportedEncodingException -
     * Object key may have spaces or unicode non-ASCII characters.
     * see {@link URLDecoder#decode(String, String)}
     */
    static String toMsg(S3Event event) throws UnsupportedEncodingException {
        S3EventNotificationRecord record = event.getRecords().get(0);
        return String.join("\n",
            record.getS3().getBucket().getName(),
            decode(record.getS3().getObject().getKey().replace('+', ' '), "UTF-8")
        );
    }
}
