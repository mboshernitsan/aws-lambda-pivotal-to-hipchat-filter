# aws-lambda-pivotal-to-hipchat

A simple Lambda function for transforming Pivotal web hook notifications and posting them to a Hip Chat room.

*This is work-in-progress.  Much remains to be done, until this is functional.*

## Prerequisites

### AWS CLI env vars
```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_DEFAULT_REGION=...
```

### Create AIM role for function
```bash
TODO
$ export AWS_LAMBDA_ROLE_ARN=...
```

### Create the function in AWS Console or CLI
```bash
$ aws lambda create-function --function-name postToHipChatFromPivotal --runtime nodejs --role ${AWS_LAMBDA_ROLE_ARN} --handler index.handler
$ export AWS_LAMBDA_FUNCTION_ARN=... # lookup in the output above
```

### Create the API endpoint AWS Console or CLI
```
$ aws apigateway create-rest-api --name "pivotalToHipChat"
$ export AWS_APIGATEWAY_ID=... # lookup in the output above

$ aws apigateway get-resources --rest-api-id <API ID>
$ export AWS_APIGATEWAY_RESOURCE_ID=... # lookup root resource id in the output above

$ aws apigateway put-method --rest-api-id ${AWS_APIGATEWAY_ID} --resource-id ${AWS_APIGATEWAY_RESOURCE_ID} --http-method POST --authorization-type none 

$ aws apigateway put-integration --rest-api-id ${AWS_APIGATEWAY_ID} --resource-id ${AWS_APIGATEWAY_RESOURCE_ID} --http-method POST --type AWS --integration-http-method POST --uri arn:aws:apigateway:${AWS_DEFAULT_REGION}:lambda:path/2015-03-31/functions/${AWS_LAMBDA_FUNCTION_ARN}/invocations

$ aws apigateway create-deployment --rest-api-id ${AWS_APIGATEWAY_ID} --stage-name prod

$ export AWS_LAMBDA_FUNCTION_URL=https://${AWS_APIGATEWAY_ID}.execute-api.${AWS_DEFAULT_REGION}.amazonaws.com/prod
```

