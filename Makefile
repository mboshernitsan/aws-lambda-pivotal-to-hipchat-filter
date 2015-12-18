all: output/function.zip

.PHONY: output

output:
	@mkdir -p $@

output/index.js: index.js
	cp $< $@

output/config.js: check-hipchat-env
	echo "var config = { apiAuthToken: '$(HIPCHAT_TOKEN)', roomId: '$(HIPCHAT_ROOM)', from: 'Pivotal'}; module.exports = config;" > $@

output/node_modules:
	npm install --prefix=output hipchat-client aws-lambda-mock-context

output/function.zip: output output/index.js output/config.js output/node_modules
	cd output && zip -r function.zip index.js config.js node_modules

check-hipchat-env:
ifndef HIPCHAT_TOKEN
	$(error HIPCHAT_TOKEN is undefined)
endif
ifndef HIPCHAT_ROOM
	$(error HIPCHAT_ROOM is undefined)
endif

check-aws-env:
ifndef AWS_ACCESS_KEY_ID
	$(error AWS_ACCESS_KEY_ID is undefined)
endif
ifndef AWS_SECRET_ACCESS_KEY
	$(error AWS_SECRET_ACCESS_KEY is undefined)
endif
ifndef AWS_DEFAULT_REGION
	$(error AWS_DEFAULT_REGION is undefined)
endif

deploy: check-aws-env output/function.zip
	aws lambda update-function-code --function-name postToHipChatFromPivotal --zip-file fileb://output/function.zip

localtest: output output/index.js output/config.js output/node_modules
	cd output && node -e "require('./index.js').handler(require('../fixtures/test1.json'), require('aws-lambda-mock-context')())"

test:
ifndef AWS_LAMBDA_FUNCTION_URL
	$(error AWS_LAMBDA_FUNCTION_URL is undefined)
endif
	curl -X POST -d @fixtures/test1.json $(AWS_LAMBDA_FUNCTION_URL)