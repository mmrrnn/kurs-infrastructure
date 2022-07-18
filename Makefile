PARAMETERS_FILE=template.config.json
PARAMETERS=$(shell cat $(PARAMETERS_FILE) | jqn 'get("Parameters") | entries | map(x => x[0] + "=" + x[1]) | join(" ")')
REGION=us-east-1

ARTIFACTS_BUCKET_NAME=artifacts-dev-marcin-kurs
ARTIFACTS_S3_PREFIX=infrastructure
STACK_NAME=mpapiez-nestjs-course

TEMPLATE_FILE=main.yml
CAPABILITIES=CAPABILITY_IAM CAPABILITY_AUTO_EXPAND

ARTIFACT_NAME=main.zip

copy-s3-zip-files:
	aws s3 cp s3://$(ARTIFACTS_BUCKET_NAME)/nest-api/nest-api.zip .

deploy-manually: copy-s3-zip-files
	sam build
	sam package --output-template-file $(TEMPLATE_FILE) --s3-bucket $(ARTIFACTS_BUCKET_NAME) --s3-prefix $(ARTIFACTS_S3_PREFIX) --region $(REGION)
	sam deploy --template-file $(TEMPLATE_FILE) --stack-name $(STACK_NAME) --capabilities $(CAPABILITIES)  --region $(REGION) --parameter-overrides $(PARAMETERS)