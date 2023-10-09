# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


##
# Project variables
TARGET_DIR = "./Output"
PROJECTNAME=ecsclockdemo
REPONAME=${PROJECTNAME}
STACKNAME=${PROJECTNAME}


##
# Sanity checks
AWSCLI:=$(shell command -v aws --version 2> /dev/null)
DOCKER:=$(shell command -v docker --version 2> /dev/null)

ifdef AWSCLI
AWSCLI:=aws
else
$(error "Did not find required AWS CLI executable!")
endif

ifdef DOCKER
DOCKER:=docker
else
$(error "Did not find required DOCKER executable!")
endif

ifndef REGION
$(error "You must supply both Account ID and Region, i.e.: make infra ACCOUNTID='123456789123' REGION='aa-bbbbb-X' ")
endif

ifndef ACCOUNTID
$(error "You must supply both Account ID and Region, i.e.: make infra ACCOUNTID='123456789123' REGION='aa-bbbbb-X' ")
endif


##
# Targets
infra:
	@echo -e "\nDeploying CloudFormation Stack..."

	@aws --region=${REGION} cloudformation deploy 					\
      	 --template-file ./ecs-fargate-clock-accuracy.yaml 			\
      	 --stack-name ${STACKNAME} 									\
		 --parameter-overrides ProjectName=${PROJECTNAME}			\
		 --no-fail-on-empty-changeset								\
      	 --capabilities CAPABILITY_AUTO_EXPAND CAPABILITY_NAMED_IAM \

	@if [ $$? -ne 0 ] ; then									\
		echo -e "\n[ERROR] Stack creation or update failed...";	\
		exit 1;													\
	fi

	@echo -e "\n[OK] CloudFormation Stack created/updated successfully."

.ONESHELL:
images: clean infra

	@if [ ! -d $(TARGET_DIR) ] ; then	\
		echo "Making $(TARGET_DIR)";	\
		mkdir -p ./Output;				\
	fi

	@echo -e "\nLogging into ECR..."
	@aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNTID}.dkr.ecr.${REGION}.amazonaws.com
	@echo -e "[OK]"

	@echo -e "\nBuilding Python app..."
	@docker build --platform linux/amd64 --tag app-python app-python/.
	@if [ $$? -ne 0 ] ; then									\
		echo -e "\n[ERROR] Building Docker image failed.";		\
		exit 1;													\
	fi
	@docker tag app-python:latest ${ACCOUNTID}.dkr.ecr.${REGION}.amazonaws.com/${REPONAME}:app-python
	@docker push ${ACCOUNTID}.dkr.ecr.${REGION}.amazonaws.com/${REPONAME}:app-python
	@echo -e "[OK]"

	@echo -e "\nBuilding cron-worker..."
	@docker build --platform linux/amd64 --tag cron-worker cron-worker/.
	@if [ $$? -ne 0 ] ; then									\
		echo -e "\n[ERROR] Building Docker image failed.";		\
		exit 1;													\
	fi
	@docker tag cron-worker:latest ${ACCOUNTID}.dkr.ecr.${REGION}.amazonaws.com/${REPONAME}:cron-worker
	@docker push ${ACCOUNTID}.dkr.ecr.${REGION}.amazonaws.com/${REPONAME}:cron-worker
	@echo -e "[OK]"

	@echo -e "\nDone building docker images!"

clean:
	@echo "Removing $(TARGET_DIR)"
	@rm -rf $(TARGET_DIR)

all: images
	@echo -e "[OK] - Build completed!"