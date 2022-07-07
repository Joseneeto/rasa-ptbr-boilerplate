current_dir := $(shell pwd)
user := $(shell whoami)

ENDPOINTS = endpoints/docker-endpoints.yml
CREDENTIALS = credentials/credentials.yml

clean:
	docker-compose down
	cd bot/ && make clean

stop:
	docker-compose stop


############################## DOCKERHUB ##############################
dchub-tag:
	docker tag arthurtemporim/boilerplate arthurtemporim/boilerplate:2.8.12

dchub-push:
	docker push arthurtemporim/boilerplate

############################## BOILERPLATE ##############################
first-run:
	make build
	make train
	make shell

build:
	make build-bot

build-requirements:
	docker build . \
		--no-cache \
		-f docker/requirements.Dockerfile \
		-t arthurtemporim/boilerplate

build-bot:
	docker-compose build \
		--no-cache bot

build-analytics:
	make analytics
	make config-elastic
	# This line should be removed ASAP
	sleep 10
	# Run this command only when kibana is up and ready. A script is needed.
	make config-kibana

config-elastic:
	docker-compose run \
		--rm \
		-v $(current_dir)/modules/analytics/setup_elastic.py:/analytics/setup_elastic.py \
		bot \
		python /analytics/setup_elastic.py

config-kibana:
	docker-compose run \
		--rm \
		-v $(current_dir)/modules/analytics/:/analytics/ \
		kibana \
		python3 /analytics/import_dashboards.py
	echo "Acesse o KIBANA em: http://localhost:5601"

analytics:
	docker-compose up \
		-d elasticsearch
	docker-compose up \
		-d rabbitmq
	docker-compose up \
		-d rabbitmq-consumer
	docker-compose up \
		-d kibana

shell:
	docker-compose run \
		--rm \
		--service-ports \
		bot \
		make shell ENDPOINTS=$(ENDPOINTS)

api:
	docker-compose run \
		--rm \
		--service-ports \
		bot \
		make api ENDPOINTS=$(ENDPOINTS) CREDENTIALS=$(CREDENTIALS)

actions:	
	docker-compose run \
		--rm \
		--service-ports \
		bot \
		make actions

x:
	docker-compose run \
		--rm \
		--service-ports \
		x \
		make x

webchat:
	echo "Executando Bot com Webchat."
	docker-compose run \
		-d \
		--rm \
		--service-ports \
		bot \
		make webchat ENDPOINTS=$(ENDPOINTS) CREDENTIALS=$(CREDENTIALS)
	docker-compose up \
		-d \
		webchat
	echo "Acesse o WEBCHAT em: http://localhost:5010"

telegram:
	docker-compose run \
		-d \
		--rm \
		--service-ports \
		bot-telegram \
		make telegram ENDPOINTS=$(ENDPOINTS) CREDENTIALS=$(CREDENTIALS)

rocket:
	docker-compose up \
		-d \
		rocketchat
	make rocket-bot
	
rocket-bot:
	docker-compose run \
		-d \
		--rm \
		--service-ports \
		bot \
		make rocket ENDPOINTS=$(ENDPOINTS) CREDENTIALS=$(CREDENTIALS)
	echo "Acesse o ROCKETCHAT em: http://localhost:3000"

train:
	docker-compose run \
		--rm bot \
		make train

alltrain:
	make clean 
	make train
	sudo service docker start
	docker-compose run \
		--rm bot \
		make alltrain
	

############################## NOTEBOOKS ##########################

notebooks:
	docker-compose up \
		-d notebooks
	echo "Acesse o KIBANA em: http://localhost:8888"


############################## TESTS ##############################
validate:
	docker-compose run \
		--rm bot \
		make validate

test:
	docker-compose run \
		--rm bot \
		make test

test-nlu:
	docker-compose run \
		--rm \
		bot \
		make test-nlu

test-core:
	docker-compose run \
		--rm \
		bot \
		make test-core

