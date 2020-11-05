# Configuration
TF_VERSION=0.13.4
TF_IMAGE=nijohando/terraform:$(TF_VERSION)
ORCH_NAME=njhd-blog
#TF_BACKEND_BUCKET=<tfstate用S3バケット>
#AWS_REGION=<AWSリージョン>
#AWS_PROFILE=<AWSプロファイル>

# Constants
RUN_TF=./run tf -d
PRJ_SITE_DIR=tf0.d/site
PRJ_CI_DIR=tf1.d/ci
GRAPH_CMD="graph | dot -Tsvg > graph.svg"
VIEW_IMAGE_CMD=open $(PRJ_SITE_DIR)/graph.svg

export TF_IMAGE TF_VERSION TF_BACKEND_BUCKET AWS_REGION AWS_PROFILE ORCH_NAME

.PHONY: image sh site/graph ci/graph site/dev/% ci/dev/% site/prd/% ci/prd/%

image:
	./run img

sh:
	./run sh

site/graph:
	$(RUN_TF) $(PRJ_SITE_DIR) $(GRAPH_CMD)
	$(VIEW_IMAGE_CMD)

ci/graph:
	$(RUN_TF) $(PRJ_CI_DIR) $(GRAPH_CMD)
	$(VIEW_IMAGE_CMD)

site/dev/%:
	$(RUN_TF) $(PRJ_SITE_DIR) -p dev $*

ci/dev/%:
	$(RUN_TF) $(PRJ_CI_DIR) -p dev $*

site/prd/%:
	$(RUN_TF) $(PRJ_SITE_DIR) -p prd $*

ci/prd/%:
	$(RUN_TF) $(PRJ_CI_DIR) -p prd $*


