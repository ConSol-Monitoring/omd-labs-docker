REPO = consol/ubuntu-omd-labs
TAG ?= latest

IMAGE=$(REPO):$(TAG)


.PHONY: build bash start stop 

build: 
	docker build -t $(IMAGE) . 
	docker images | grep '$(REPO)'
start:
	docker run -p 8888:80 -d -it $(IMAGE)
	docker images | grep '$(REPO)'
stop:

bash: 
	docker run --rm -p 8888:80 -it $(IMAGE) /bin/bash
