include $(shell bash .mkdkr init)

shellcheck:
	@$(.)
	... koalaman/shellcheck-alpine:v0.4.6
	.. shellcheck -e SC1088 -e SC2068 -e SC2086 .mkdkr
	.. shellcheck generator/gitlab-ci
	.. shellcheck -e SC2181 test/unit_job_name
	.. shellcheck -e SC2181 -e SC2086 test/unit_create_instance
	.. shellcheck -e SC2181 -e SC2086 -e SC1091 test/unit_branch_or_tag_name
	.. shellcheck -e SC2181 -e SC2086 -e SC1091 test/unit_branch_or_tag_name_slug
	.. shellcheck test/cover

show:
	@$(.)
	echo $(MKDKR_BRANCH_NAME)
	echo $(MKDKR_BRANCH_NAME_SLUG)

unit:
	@$(.)
	... privileged docker:19 --workdir $(PWD)/test
	.. apk add bash jq git
	.. ./unit_job_name
	.. ./unit_create_instance
	.. ./unit_run_command
	.. ./unit_branch_or_tag_name
	.. ./unit_branch_or_tag_name_slug

DOCKER_BIN=https://download.docker.com/linux/static/stable/x86_64/docker-19.03.5.tgz

coverage:
	@$(.)
	... privileged kcov/kcov:v31 --workdir $(PWD)/test
	.. rm -rf coverage
	.. 'apt-get update && apt-get install -y curl jq bc git'
	.. curl -s '$(DOCKER_BIN) > /tmp/docker.tgz'
	.. tar -zxvf /tmp/docker.tgz --strip=1 -C /usr/local/bin/
	.. kcov --exclude-path=shunit2 coverage unit_job_name
	.. kcov --exclude-path=shunit2 coverage unit_create_instance
	.. kcov --exclude-path=shunit2 coverage unit_run_command
	.. kcov --exclude-path=shunit2 coverage unit_branch_or_tag_name
	.. kcov --exclude-path=shunit2 coverage unit_branch_or_tag_name_slug
	.. './cover > coverage/coverage.json'
	... node:12 \
		-e SURGE_LOGIN='$(SURGE_LOGIN)' \
		-e SURGE_TOKEN=$$SURGE_TOKEN
	.. cp .surgeignore ./test/coverage/
	.. npm install -g surge
	.. surge --project ./test/coverage --domain mkdkr.surge.sh

simple:
	make --silent -f examples/simple.mk simple

multi-images:
	make --silent -f examples/simple.mk multi-images

service:
	make --silent -f examples/service.mk service

dind:
	make --silent -f examples/dind.mk dind

escapes:
	make --silent -f examples/escapes.mk all

shell:
	make --silent -f examples/shell.mk shell

trap:
	make --silent -f examples/trap.mk

stdout:
		make --silent -f examples/stdout.mk all

implicit-job:
	make --silent -f examples/implicit-job.mk

examples/pipeline:
	@cd examples && make --silent -f pipeline.mk pipeline

scenarios: simple multi-images service dind escapes shell trap implicit-job stdout examples/pipeline

brainfuck:
	@$(.)
	... privileged docker:19
	.. apk add make bash
	.. make pipeline

generator/gitlab:
	@$(.)
	... rosineygp/mkdkr
	.. gitlab-ci lint=shellcheck \
		scenarios=small,service,dind > .gitlab-ci.yml

pipeline:
	make --silent commitlint
	make --silent shellcheck
	make --silent unit
	make --silent scenarios -j $(shell nproc) --output-sync