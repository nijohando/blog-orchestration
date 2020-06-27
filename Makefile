DOCKER_ENV=DOCKER_BUILDKIT=1
CLI_IMAGE=nijohando/terraform-awscli:0.12.26
RUN_TF=./run tf -d
PRJ_SITE_DIR=tf0.d/site
PRJ_CI_DIR=tf1.d/ci
GRAPH_CMD="graph | dot -Tsvg > graph.svg"
VIEW_IMAGE_CMD=open $(PRJ_SITE_DIR)/graph.svg

.PHONY: image sh

image:
	$(DOCKER_ENV) docker build -t $(CLI_IMAGE) ./dockerfiles/terraform-awscli

sh:
	./run sh

dev/site/%:
	$(RUN_TF) $(PRJ_SITE_DIR) -p dev -p private $*

dev/site/graph:
	$(RUN_TF) $(PRJ_SITE_DIR) $(GRAPH_CMD)
	$(VIEW_IMAGE_CMD)

dev/ci/%:
	$(RUN_TF) $(PRJ_CI_DIR) -p dev $*

dev/ci/graph:
	$(RUN_TF) $(PRJ_CI_DIR) $(GRAPH_CMD)
	$(VIEW_IMAGE_CMD)

