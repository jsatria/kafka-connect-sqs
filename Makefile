.ONESHELL:
COMPOSE=docker compose
AUTOMATE_ARN=arn:aws:lambda:us-east-1:000000000000:function:function
ROLE_ARN=arn:aws:iam::000000000000:role/DummyRole

init:
	pip install yq
	mkdir -p /tmp/localstack

build: init
	$(COMPOSE) build --no-cache --pull

up: init
		$(COMPOSE) up --remove-orphans --build

create:
	awslocal --endpoint-url=http://localhost:4566 sqs create-queue --queue-name kafkaqueue
	curl -XPOST -H 'Content-Type: application/json' http://localhost:8083/connectors -d @demos/sqs-sink-chirped.json

delete:
	awslocal --queue-url=http://localhost:4566/000000000000/kafkaqueue sqs delete-queue
	curl -XDELETE -H 'Content-Type: application/json' http://localhost:8083/connectors/sqs-sink-chirped

# convert:
# 	@cat ../step-functions-handler/state-machines/$(name).yml | yq > state-machine.json
# 	@sed -i .bak -e s/$$\{step_function_arn\}/$(AUTOMATE_ARN)/g ./state-machine.json
# 	@rm ./state-machine.json.bak

write:
	~/code/kafka_2.12-2.8.0/bin/kafka-console-producer.sh --bootstrap-server 0.0.0.0:9092 --topic chirps-t < kafkapayload.json

execute:
	awslocal stepfunctions \
		--no-cli-pager \
		start-execution \
		--state-machine arn:aws:states:us-east-1:000000000000:stateMachine:$(name)-local \
		--name `date "+%Y-%m-%d-%H-%M-%S"` \
		--input file://./payloads/$(name).json

.PHONY: init build up load compile delete \
	install-deps convert statemachine execute describe et
