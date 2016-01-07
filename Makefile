all: output/function.zip

.PHONY: output

output:
	@mkdir -p $@

output/index.js: index.js
	cp $< $@

output/node_modules:
	@rm -fr output/node_modules
	npm install --prefix=output hipchat-client aws-lambda-mock-context

output/function.zip: output output/index.js output/node_modules
	cd output && zip -r function.zip index.js node_modules

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


FIXTURES= \
	test.json \
	bug_create.json \
	chore_create.json \
	epic_create.json \
	epic_delete.json \
	release_create.json \
	story_attachment_add.json \
	story_attachment_remove.json \
	story_change_type.json \
	story_comment_add.json \
	story_commit_comment_add.json \
	story_comment_remove.json \
	story_create.json \
	story_delete_multi.json \
	story_delivered.json \
	story_description_change.json \
	story_epic_add.json \
	story_estimated.json \
	story_finished.json \
	story_accepted.json \
	story_label_add.json \
	story_label_add_multi.json \
	story_label_remove.json \
	story_move_multi.json \
	story_owner_add.json \
	story_owner_remove.json \
	story_started.json \
	story_task_add.json \
	story_task_remove.json

localtest: check-hipchat-env output output/index.js output/node_modules
	@$(foreach INPUT,$(FIXTURES),\
		cd output && node --use_strict -e \
		"var ctx=require('aws-lambda-mock-context')(), fixture='../fixtures/$(INPUT)', test=require(fixture); \
		 require('./index.js').handler({ hipchatToken:'$(HIPCHAT_TOKEN)', hipchatRoom:'$(HIPCHAT_ROOM)', activity:test}, ctx); \
		 ctx.Promise.then((result) => { console.log('%s %s', (result.status == test.expected_status) ? 'OK' : 'FAIL', fixture) }); \
		 ctx.Promise.catch((err)   => { console.log('ERR %s: %s', fixture, err) })")

posttest: check-hipchat-env
ifndef AWS_LAMBDA_FUNCTION_URL
	$(error AWS_LAMBDA_FUNCTION_URL is undefined)
endif
	$(foreach INPUT,$(FIXTURES),\
		curl -H "Content-Type: application/json" -X POST -d @fixtures/$(INPUT) \
			'$(AWS_LAMBDA_FUNCTION_URL)/?hipchatToken=$(HIPCHAT_TOKEN)&hipchatRoom=$(HIPCHAT_ROOM)' ;)

