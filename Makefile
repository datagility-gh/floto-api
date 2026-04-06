BRANCH_ID := $(shell git branch --show-current | cut -d '/' -f2 | cut -d '-' -f1)
STACK := local
STACK_INFRA_PREFIX := f
STACK_FEATURE := $(STACK_INFRA_PREFIX)$(BRANCH_ID)
CONTAINER_REGISTRY := dev01ukscore.azurecr.io
CONTAINER_APP := $(STACK)-ca-floto-api
CONTAINER_APP_RG := $(STACK)-rg-floto
PROJECT_FILE_VERSION := $(shell xpath -q -e "/Project/PropertyGroup/FileVersion/text()" Floto.Api/Floto.Api.csproj 2> /dev/null || echo 0.0.0)
PROJECT_SHORT_VERSION := $(basename $(PROJECT_FILE_VERSION))
PROJECT_PATCH_VERSION := 0
PROJECT_BUILD_VERSION := $(PROJECT_SHORT_VERSION).$(PROJECT_PATCH_VERSION)
API_DIR := Floto.Api
CLIENT_DIR := floto-client
CLIENT_PACKAGE_NAME := @floto/client
CLIENT_VERSION := $(shell node -p "require('./$(CLIENT_DIR)/package.json').version")
CLIENT_SHORT_VERSION := $(basename $(CLIENT_VERSION))
CLIENT_PATCH_VERSION := 0
CLIENT_PACKAGE_VERSION := $(CLIENT_SHORT_VERSION).$(CLIENT_PATCH_VERSION)
AZ_TARGET_PLATFORM := linux/amd64
AZ_RUNTIME_IMAGE := -noble-amd64
APP_CONTAINER_NAME := floto-api
APP_CONTAINER_PORT := 8080
DB_EMULATOR_IMAGE_NAME := mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator:vnext-preview
DB_EMULATOR_DOCKER_CONTAINER_NAME := cosmos-emulator
DB_EMULATOR_PORT := 8081
DB_EMULATOR_EXPLORER_PORT := 1234
DB_EMULATOR_KEY := C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==
DB_EMULATOR_MIGRATION_FILE := database/CreateContainer.cs
DB_EMULATOR_DB_NAME := ${STACK}-sqldb-floto
DB_EMULATOR_CONTAINER_NAME := sql-cont-floto
APP_API_PATH := api/v1/
APP_BASE_URL := http://127.0.0.1:$(APP_CONTAINER_PORT)/$(APP_API_PATH)
CI_IMAGE_TAG := $(PROJECT_BUILD_VERSION)
INFRA_DIR := infra
INFRA_AUTO_APPROVE := false
export TF_VAR_stack := $(STACK)

# interactively authenticate the azure cli
.PHONY: login/az
login/az:
	az login --use-device-code

# login as a service principal
# . ./.az/set_credentials.sh && make login/az/sp
.PHONY: login/az/sp
login/az/sp:
	az login --service-principal --username $(ARM_CLIENT_ID) --password $(ARM_CLIENT_SECRET) --tenant $(ARM_TENANT_ID)

.PHONY: logout/az
logout/az:
	az logout | true

clean:
	rm -rf ./Floto.Api/bin/
	rm -rf ./Floto.Api/obj/
	rm -rf ./Floto.Test/bin/
	rm -rf ./Floto.Test/obj/
	dotnet nuget locals all -c

.PHONY: clean/client
clean/client:
	rm -rf ./$(CLIENT_DIR)/node_modules
	rm -rf ./$(CLIENT_DIR)/package-lock.json
	rm -rf ./$(CLIENT_DIR)/dist

# install the client npm packages
install:
	npm --prefix $(CLIENT_DIR) install

# install the client npm packages using the ci command
.PHONY: install/ci
install/ci:
	npm --prefix $(CLIENT_DIR) ci

lint:
	npm --prefix $(CLIENT_DIR) run format
	npm --prefix $(CLIENT_DIR) run lint

# build the dotnet solution
build: 
	dotnet build

# build the client
.PHONY: build/client
build/client: install
	rm -rf ./$(CLIENT_DIR)/dist
	npm --prefix $(CLIENT_DIR) run build

# build the runtime docker image
# to override the image tag:
#	make build/docker STACK={SOME_STACK}
.PHONY: build/docker
build/docker:
	docker build --target final --tag $(APP_CONTAINER_NAME):$(STACK) \
		--build-arg ASMVERSION=$(PROJECT_BUILD_VERSION) .

# build the runtime docker image for pushing to Azure
# to override the image tag:
#	make build/docker/az CI_IMAGE_TAG={SOME_TAG}
# to override just the project patch version
#	make build/docker/az PROJECT_PATCH_VERSION={SOME_PATCH}
.PHONY: build/docker/az
build/docker/az:
	docker build --target final --tag $(APP_CONTAINER_NAME):$(CI_IMAGE_TAG) \
		--platform=$(AZ_TARGET_PLATFORM) \
		--build-arg RUNTIMEPLATFORM=$(AZ_RUNTIME_IMAGE) --build-arg ASMVERSION=$(PROJECT_BUILD_VERSION) .

# run the api locally, outside of a container
# app listens on port $(APP_CONTAINER_PORT), e.g. http://localhost:8080/api/v1/ping
run: start/db migrate/db
	dotnet run --project ./$(API_DIR)/ \
		-e ASPNETCORE_ENVIRONMENT=Development \
		-e COSMOSDB_CONNECTION_STRING='AccountEndpoint=http://localhost:${DB_EMULATOR_PORT}/;AccountKey=${DB_EMULATOR_KEY};' \
		-e Stack=$(STACK)

# create an npm package for the client
# to set the package patch version
#	make pack CLIENT_PATCH_VERSION={SOME_PATCH}
pack: build/client
	rm -f $(CLIENT_DIR)/floto-client-*.tgz
	sed "s/$(CLIENT_VERSION)/$(CLIENT_PACKAGE_VERSION)/" $(CLIENT_DIR)/package.json > $(CLIENT_DIR)/dist/package.json
	npm pack $(CLIENT_DIR)/dist/ --pack-destination $(CLIENT_DIR)/
	rm -f $(CLIENT_DIR)/sed*
	rm -f $(CLIENT_DIR)/dist/package.json

# run the dotnet unit tests
test:
	dotnet test --filter FullyQualifiedName!~Integration. Floto.Test

# run the dotnet integration tests
.PHONY: test/int
test/int: start/db migrate/db
	dotnet test --filter FullyQualifiedName~Integration. Floto.Test

# run the client jest unit tests
.PHONY: test/client
test/client:
	npm --prefix $(CLIENT_DIR) run test

# run the client jest unit tests
.PHONY: test/client/coverage
test/client/coverage:
	rm -rf $(CLIENT_DIR)/coverage
	rm -rf $(CLIENT_DIR)/test-results
	npm --prefix $(CLIENT_DIR) run coverage

# run the client jest integration tests
#	make test/client/int APP_BASE_URL='http://127.0.0.1:8888/api/v1/' APP_SUB_KEY=someKey
.PHONY: test/client/int
test/client/int:
	rm -f $(CLIENT_DIR)/src/int/package-lock.json && rm -rf $(CLIENT_DIR)/src/int/node_modules
	npm --prefix $(CLIENT_DIR)/src/int install
	FLOTO_API_BASE=$(APP_BASE_URL) FLOTO_API_KEY=$(APP_SUB_KEY) npm --prefix $(CLIENT_DIR) run test:int

# run the dotnet unit tests and generate the code coverage stats
.PHONY: test/coverage
test/coverage:
	rm -rf ./Floto.Test/TestResults/
	dotnet test --filter FullyQualifiedName!~Integration. Floto.Test --logger "trx;logfilename=Floto.Test.trx" \
		--collect:"XPlat Code Coverage" \
		-- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.ExcludeByFile="**/Program.cs,**/*Repository.cs"

# run the dotnet unit tests and generate the code coverage html report
.PHONY: test/coverage/report
test/coverage/report: test/coverage
	reportgenerator -reports:$(shell find Floto.Test/TestResults/**/coverage.cobertura.xml) -targetdir:Floto.Test/TestResults/coveragereport -reporttypes:Html

publish:
	cd $(CLIENT_DIR) && npm publish floto-client-*.tgz

# create a swagger definition file for the app
.PHONY: publish/swagger
publish/swagger: export COSMOSDB_CONNECTION_STRING=dummy
publish/swagger: build
	swagger tofile --output Floto.Api/floto-openapi.json Floto.Api/bin/Debug/net10.0/Floto.Api.dll v1

# generate .NET code for creating the Cosmos DB container from the TF definition
.PHONY: generate/db
generate/db:
	python3 database/cosmostf2dotnet.py < infra/modules/cosmosdb/main.tf > database/CreateContainer.cs

# run the generated .NET code to create the Cosmos DB container in the emulator
.PHONY: migrate/db
migrate/db: export COSMOS_ACCOUNT_ENDPOINT=http://localhost:${DB_EMULATOR_PORT}
migrate/db: export COSMOS_ACCOUNT_KEY=${DB_EMULATOR_KEY}
migrate/db: export COSMOS_DATABASE_ID=${DB_EMULATOR_DB_NAME}
migrate/db: export COSMOS_CONTAINER_ID=${DB_EMULATOR_CONTAINER_NAME}
migrate/db: generate/db
	sleep 10 # wait for the emulator to be ready to accept connections
	dotnet run --no-launch-profile --file ${DB_EMULATOR_MIGRATION_FILE}

# start the app in a docker container
# app listens on port $(APP_CONTAINER_PORT), e.g. http://localhost:8080/api/v1/ping
start: stop start/db migrate/db
	make build/docker
	docker run --name $(APP_CONTAINER_NAME) \
		-e ASPNETCORE_ENVIRONMENT=Development \
		-e COSMOSDB_CONNECTION_STRING='AccountEndpoint=http://$(shell docker inspect $(DB_EMULATOR_DOCKER_CONTAINER_NAME) | jq  -r '.[].NetworkSettings.Networks.bridge.IPAddress'):${DB_EMULATOR_PORT}/;AccountKey=${DB_EMULATOR_KEY};' \
		-e Stack=$(STACK) \
		-p $(APP_CONTAINER_PORT):$(APP_CONTAINER_PORT) \
		-d $(APP_CONTAINER_NAME):$(STACK)

# stop the local app container
stop: stop/db
	docker rm -f $(APP_CONTAINER_NAME) || true

# start the database emulator
# db listens on port ${DB_EMULATOR_PORT}, e,g, http://localhost:8081
# explorer listens on port ${DB_EMULATOR_EXPLORER_PORT} e.g. http://localhost:1234/
.PHONY: start/db
start/db: stop/db
	DOCKER_DEFAULT_PLATFORM=linux/amd64 docker run \
		--name ${DB_EMULATOR_DOCKER_CONTAINER_NAME} \
		-p ${DB_EMULATOR_PORT}:8081 -p ${DB_EMULATOR_EXPLORER_PORT}:1234 \
		-e PROTOCOL=http \
		-e GATEWAY_PUBLIC_ENDPOINT="*" \
		-d ${DB_EMULATOR_IMAGE_NAME}

# stop the database emulator
.PHONY: stop/db
stop/db:
	docker rm -f ${DB_EMULATOR_DOCKER_CONTAINER_NAME} || true

# push the docker image to the container registry
# can override the project patch version and the build branch
#	make push/docker PROJECT_PATCH_VERSION={SOME_PATCH} STACK={SOME_STACK}
.PHONY: push/docker
push/docker: build/docker/az
	az acr login --name $(CONTAINER_REGISTRY)
	docker image tag $(APP_CONTAINER_NAME):$(CI_IMAGE_TAG) $(CONTAINER_REGISTRY)/$(APP_CONTAINER_NAME):$(CI_IMAGE_TAG)
	docker image tag $(APP_CONTAINER_NAME):$(CI_IMAGE_TAG) $(CONTAINER_REGISTRY)/$(APP_CONTAINER_NAME):$(STACK)
	docker image push $(CONTAINER_REGISTRY)/$(APP_CONTAINER_NAME):$(CI_IMAGE_TAG)
	docker image push $(CONTAINER_REGISTRY)/$(APP_CONTAINER_NAME):$(STACK)

# delete the docker all docker image mainifests and tags associated with the given stack
# can be used when cleaning up feature stacks
#	make delete/docker STACK={SOME_STACK}
.PHONY: delete/docker
delete/docker:
	az acr login --name $(CONTAINER_REGISTRY)	
	az acr repository delete -n $(CONTAINER_REGISTRY) --image $(APP_CONTAINER_NAME):$(STACK) --yes || true

# deploy a container image to the container app
# to override the image tag:
#	make update/docker STACK={SOME_STACK}
.PHONY: update/docker
update/docker:
	az config set extension.use_dynamic_install=yes_without_prompt
	az containerapp update -n $(CONTAINER_APP) -g $(CONTAINER_APP_RG) --image $(CONTAINER_REGISTRY)/$(APP_CONTAINER_NAME):$(STACK)

register/app:
	az provider register -n Microsoft.App --wait

# return the FileVersion element value from Floto.Api.csproj
version:
	@echo $(PROJECT_FILE_VERSION)

# return the major.minor parts only from the FileVersion element value from Floto.Api.csproj
.PHONY: version/short
version/short:
	@echo $(PROJECT_SHORT_VERSION)

# return the version element from floto-client/package.json
.PHONY: version/client
version/client:
	@echo $(CLIENT_VERSION)

# return major.minor parts only from the version element from floto-client/package.json
.PHONY: version/client/short
version/client/short:
	@echo $(CLIENT_SHORT_VERSION)

# return the patch part of the version of @floto/client from the npm feed
.PHONY: version/client/remote/patch
version/client/remote/patch:
	@echo $(subst ., '', $(suffix $(shell npm --prefix $(CLIENT_DIR) view $(CLIENT_PACKAGE_NAME) version 2> /dev/null || echo .-1)))

# Deploy local code/infra to an Azure stack
# . ./.az/set_credentials.sh && ENV=non_prod make deploy STACK=main INFRA_AUTO_APPROVE=true
deploy: login/az/sp build/docker/az push/docker apply

# Infra
init: check-for-env
	rm -rf infra/.terraform
	terraform -chdir=$(INFRA_DIR) init -backend=true -backend-config=./environments/${ENV}/backend.tfvars

check-for-env: check-var-ENV check-var-STACK

check-var-%:
	@ if [ "${${*}}" = "" ]; then echo "environment variable '$*' not set"; exit 1; fi

# . ./.az/set_credentials.sh && ENV=non_prod make plan STACK=main
plan: init publish/swagger
	@echo "************************************************************"
	@echo "* ACTION:		PLAN"
	@echo "* ENV:			$(ENV)"
	@echo "* STACK:		$(TF_VAR_stack)"
	@echo "* ARM_CLIENT_ID:	$(ARM_CLIENT_ID)"
	@echo "* ARM_SUBSCRIPTION_ID:	$(ARM_SUBSCRIPTION_ID)"
	@echo "* ARM_TENANT_ID:	$(ARM_TENANT_ID)"
	@echo "************************************************************"
	terraform -chdir=$(INFRA_DIR) workspace select -or-create=true $(TF_VAR_stack)
	terraform -chdir=$(INFRA_DIR) plan --var-file=environments/$(ENV)/variables.tfvars

# . ./.az/set_credentials.sh && ENV=non_prod make apply STACK=main
# To auto-approve
# . ./.az/set_credentials.sh && ENV=non_prod make apply STACK=main INFRA_AUTO_APPROVE=true
# With credentials already set (e.g. CI)
# ENV=non_prod make apply STACK=main INFRA_AUTO_APPROVE=true
apply: init publish/swagger
	@echo "************************************************************"
	@echo "* ACTION:		APPLY"
	@echo "* ENV:			$(ENV)"
	@echo "* STACK:		$(TF_VAR_stack)"
	@echo "* ARM_CLIENT_ID:	$(ARM_CLIENT_ID)"
	@echo "* ARM_SUBSCRIPTION_ID:	$(ARM_SUBSCRIPTION_ID)"
	@echo "* ARM_TENANT_ID:	$(ARM_TENANT_ID)"
	@echo "* AUTO_APPROVE:		$(INFRA_AUTO_APPROVE)"	
	@echo "************************************************************"
	terraform -chdir=$(INFRA_DIR) workspace select -or-create=true $(TF_VAR_stack)
ifeq (true, $(INFRA_AUTO_APPROVE))
	terraform -chdir=$(INFRA_DIR) apply --auto-approve --var-file=environments/$(ENV)/variables.tfvars
else
	terraform -chdir=$(INFRA_DIR) apply --var-file=environments/$(ENV)/variables.tfvars
endif

# create a stack for a feature along with the associated docker image
# gets the stack name from the work item id in the current git branch name
# e.g:
# 0013-get-work-item-number-from-branch-name => 0013
# feature/0013-get-work-item-number-from-branch-name => 0013
# . ./.az/set_credentials.sh && ENV=non_prod make apply/feature
.PHONY: apply/feature
apply/feature:
	make build/docker/az CI_IMAGE_TAG=$(STACK_FEATURE)
	make push/docker STACK=$(STACK_FEATURE)
	make apply STACK=$(STACK_FEATURE)

# make output/api_url_floto
.PHONY: output/%
output/%:
	@terraform -chdir=$(INFRA_DIR) output -json | jq -r .$*.value

# . ./.az/set_credentials.sh && ENV=non_prod make destroy STACK=main
destroy: init
	@echo "************************************************************"
	@echo "* ACTION:		DESTROY"
	@echo "* ENV:			$(ENV)"
	@echo "* STACK:		$(TF_VAR_stack)"
	@echo "* ARM_CLIENT_ID:	$(ARM_CLIENT_ID)"
	@echo "* ARM_SUBSCRIPTION_ID:	$(ARM_SUBSCRIPTION_ID)"
	@echo "* ARM_TENANT_ID:	$(ARM_TENANT_ID)"
	@echo "************************************************************"
	terraform -chdir=$(INFRA_DIR) workspace select -or-create=true $(TF_VAR_stack)
	terraform -chdir=$(INFRA_DIR) destroy --var-file=environments/$(ENV)/variables.tfvars
	terraform -chdir=$(INFRA_DIR) workspace select default
	terraform -chdir=$(INFRA_DIR) workspace delete $(TF_VAR_stack)

# destroy a stack for a feature and remove the associated docker image(s)
# gets the stack name from the work item id in the current git branch name
# e.g:
# 0013-get-work-item-number-from-branch-name => 0013
# feature/0013-get-work-item-number-from-branch-name => 0013
# . ./.az/set_credentials.sh && ENV=non_prod make destroy/feature
# or to destroy a stack other than the one associated with the current git branch:
# . ./.az/set_credentials.sh && ENV=non_prod make destroy/feature STACK_FEATURE=someFeature
.PHONY: destroy/feature
destroy/feature:
	make destroy STACK=$(STACK_FEATURE)
	make delete/docker STACK=$(STACK_FEATURE)
