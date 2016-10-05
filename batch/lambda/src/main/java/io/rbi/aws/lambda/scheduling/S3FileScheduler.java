package io.rbi.aws.lambda.scheduling;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.S3Event;

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
    @Override
    public String handleRequest(S3Event event, Context context) {

        event.getRecords().stream()
            .forEach( item -> System.out.println( item.getEventName() ) );

        return event.toJson();
    }
}
