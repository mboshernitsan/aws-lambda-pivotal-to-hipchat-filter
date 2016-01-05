# aws-lambda-pivotal-to-hipchat

A simple Lambda function for transforming Pivotal web hook notifications and posting them to a Hip Chat room.

## Initial set up

This needs to be done once using the AWS CLI commands below or the equivalent AWS Console operations.

```bash

# Set env vars for AWS CLI
$ export AWS_ACCESS_KEY_ID=...
$ export AWS_SECRET_ACCESS_KEY=...
$ export AWS_DEFAULT_REGION=...

# Create AIM role for function
...TODO...
$ export AWS_LAMBDA_ROLE_ARN=...

# Create the function itself
$ aws lambda create-function --function-name postToHipChatFromPivotal --runtime nodejs --role ${AWS_LAMBDA_ROLE_ARN} --handler index.handler
$ export AWS_LAMBDA_FUNCTION_ARN=... # lookup in the output above

# Create the API endpoint
$ aws apigateway create-rest-api --name "pivotalToHipChat"
$ export AWS_APIGATEWAY_ID=... # lookup in the output above

$ aws apigateway get-resources --rest-api-id ${AWS_APIGATEWAY_ID}
$ export AWS_APIGATEWAY_RESOURCE_ID=... # lookup root resource id in the output above

$ aws apigateway put-method --rest-api-id ${AWS_APIGATEWAY_ID} --resource-id ${AWS_APIGATEWAY_RESOURCE_ID} --http-method POST --authorization-type none 

$ aws apigateway put-integration --rest-api-id ${AWS_APIGATEWAY_ID} --resource-id ${AWS_APIGATEWAY_RESOURCE_ID} --http-method POST --type AWS --integration-http-method POST --uri arn:aws:apigateway:${AWS_DEFAULT_REGION}:lambda:path/2015-03-31/functions/${AWS_LAMBDA_FUNCTION_ARN}/invocations

$ aws apigateway put-method-response --rest-api-id ${AWS_APIGATEWAY_ID} --resource-id ${AWS_APIGATEWAY_RESOURCE_ID} --http-method POST --status-code 200 --response-models '{ "application/json": "Empty" }'

$ aws apigateway put-integration-response --rest-api-id ${AWS_APIGATEWAY_ID} --resource-id ${AWS_APIGATEWAY_RESOURCE_ID} --http-method POST --status-code 200 --response-templates '{ "application/json": "" }'

$ aws apigateway create-deployment --rest-api-id ${AWS_APIGATEWAY_ID} --stage-name prod

$ export AWS_LAMBDA_FUNCTION_URL=https://${AWS_APIGATEWAY_ID}.execute-api.${AWS_DEFAULT_REGION}.amazonaws.com/prod
```

## Development loop

After the steps above, it should be possible run make to deploy and test the function (after setting HIPCHAT_TOKEN and HIPCHAT_ROOM):

```bash
$ HIPCHAT_TOKEN=... HIPCHAT_ROOM=... make deploy
$ make posttest
```

Alternatively, you can run the tests locally without deploying:

```bash
$ HIPCHAT_TOKEN=... HIPCHAT_ROOM=... make localtest
```

Both tests will use the fixtures declared inside the Makefile.  ```make localtest``` will also validate the logic for skipping certain state transitions that we didn't find useful to blast to the team.

