all: check-env deploy

.PHONY: output

output:
	@mkdir -p $@

output/index.js: index.js
	cp $< $@

output/config.js:
	echo "var config = { apiAuthToken: '$(HIPCHAT_TOKEN)', roomId: '$(HIPCHAT_ROOM)', from: 'Pivotal'}; module.exports = config;" > $@

output/node_modules:
	npm install --prefix=output hipchat-client

output/function.zip: output output/index.js output/config.js output/node_modules
	cd output && zip -r function.zip index.js config.js node_modules

check-env:
ifndef HIPCHAT_TOKEN
	$(error HIPCHAT_TOKEN is undefined)
endif
ifndef HIPCHAT_ROOM
	$(error HIPCHAT_ROOM is undefined)
endif
ifndef AWS_ACCESS_KEY_ID
	$(error AWS_ACCESS_KEY_ID is undefined)
endif
ifndef AWS_SECRET_ACCESS_KEY
	$(error AWS_SECRET_ACCESS_KEY is undefined)
endif
ifndef AWS_DEFAULT_REGION
	$(error AWS_DEFAULT_REGION is undefined)
endif
ifndef AWS_LAMBDA_ROLE
	$(error AWS_LAMBDA_ROLE is undefined)
endif

# Not ideal, but close enough - attempt to delete funciton first, then attempt to create
deploy: output/function.zip
	-aws lambda delete-function --function-name postToHipChatFromPivotal
	aws lambda create-function --function-name postToHipChatFromPivotal --runtime nodejs --role $(AWS_LAMBDA_ROLE) --handler index.handler --zip-file fileb://output/function.zip
