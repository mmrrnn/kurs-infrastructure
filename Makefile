PARAMETERS_FILE=template.config.json
PARAMETERS=$(shell cat $(PARAMETERS_FILE) | jqn 'get("Parameters") | entries | map(x => x[0] + "=" + x[1]) | join(" ")')
REGION=us-east-1

ARTIFACTS_BUCKET_NAME=artifacts-dev-marcin-kurs
ARTIFACTS_S3_PREFIX=infrastructure
STACK_NAME=mpapiez-nestjs-course

TEMPLATE_FILE=main.yml
CAPABILITIES=CAPABILITY_IAM CAPABILITY_AUTO_EXPAND

VERSION=current
ARTIFACT_NAME=main.zip

.PHONY: deploy

invalidateCloudFront.zip: InvalidateCloudFront/index.js
	( cd InvalidateCloudFront && zip ../invalidateCloudFront.zip index.js )

copy-s3-zip-files:
	aws s3 cp s3://$(ARTIFACTS_BUCKET_NAME)/nest-api/nest-api.zip .

build: invalidateCloudFront.zip copy-s3-zip-files
	sam build

upload: build
	sam package --output-template-file $(TEMPLATE_FILE) --s3-bucket $(ARTIFACTS_BUCKET_NAME) --s3-prefix $(ARTIFACTS_S3_PREFIX)/$(VERSION) --region $(REGION)
	zip $(ARTIFACT_NAME) $(TEMPLATE_FILE) $(PARAMETERS_FILE) Makefile
	aws s3 cp $(ARTIFACT_NAME) s3://$(ARTIFACTS_BUCKET_NAME)/$(ARTIFACTS_S3_PREFIX)/$(VERSION)/ --region $(REGION)

deploy: upload
	sam deploy --template-file $(TEMPLATE_FILE) --stack-name $(STACK_NAME) --capabilities $(CAPABILITIES)  --region $(REGION) --parameter-overrides $(PARAMETERS)

deploy-ci:
	sam deploy --template-file $(TEMPLATE_FILE) --stack-name $(STACK_NAME) --capabilities $(CAPABILITIES)  --region $(REGION) --parameter-overrides $(PARAMETERS)

deploy-manually: copy-s3-zip-files
	sam build
	sam package --output-template-file $(TEMPLATE_FILE) --s3-bucket $(ARTIFACTS_BUCKET_NAME) --s3-prefix $(ARTIFACTS_S3_PREFIX) --region $(REGION)
	sam deploy --template-file $(TEMPLATE_FILE) --stack-name $(STACK_NAME) --capabilities $(CAPABILITIES)  --region $(REGION) --parameter-overrides $(PARAMETERS)