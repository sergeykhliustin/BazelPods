ifeq ($(strip $(GITHUB_ACTIONS)),)
  CONFIG =
else
  CONFIG = --config=ci
endif

.PHONY: xcodeproj
xcodeproj:
	bazel run xcodeproj:xcodeproj

clean:
	bazel clean

expunge:
	bazel clean --expunge
	rm -rf .bazel-cache

bootstrap:
	@bundle install
	@echo "build --swiftcopt=-j`sysctl -n hw.ncpu`" > .env_bazelrc

integration:
	$(MAKE) integration-clean
	$(MAKE) integration-setup
	@echo "\033[32m### integration-generate-static ###\033[0m"
	$(MAKE) integration-generate-static
	@echo "\033[32m### static: integration-build-x86_64 ###\033[0m"
	$(MAKE) integration-build-x86_64
	@echo "\033[32m### static: integration-build-arm64 ###\033[0m"
	$(MAKE) integration-build-arm64
	@echo "\033[32m### integration-generate-dynamic ###\033[0m"
	$(MAKE) integration-generate-dynamic
	@echo "\033[32m### dynamic: integration-build-x86_64 ###\033[0m"
	$(MAKE) integration-build-x86_64
	@echo "\033[32m### dynamic: integration-build-arm64 ###\033[0m"
	$(MAKE) integration-build-arm64
	@echo "\033[32m### finished ###\033[0m"

prepare-tests:
	swift TestTools/generate_podfile.swift TestTools/Pods.json TestTools/Podfile_template > Tests/Podfile
	cd Tests && pod install || pod install --repo-update
	bazel run :bazelpods $(CONFIG) -- \
	--src "$(shell pwd)/Tests" \
	--deps-prefix "//Tests/Pods" \
	--pods-root "Tests/Pods" -a -f \
	--min-ios "10.0" \
	--color yes \
	--log-level debug \
	--patches bundle_deduplicate arm64_to_sim_forced missing_sdks \
	--diff

diff-generated-files:
	@echo "Starting tests with $(shell find Tests/Recorded -type d | wc -l) test cases"

	@if ! [ -n "$(shell find Tests/Recorded -type d)" ]; \
	then \
        echo "Recorded tests are empty"; \
        exit 1;\
    fi; \
    exit_code=0; \
	for dir in Tests/Recorded/*/; \
	do \
		if ! diff "$$dir/BUILD.bazel" "Tests/Pods/`basename $$dir`/BUILD.bazel" > /dev/null; \
		then \
			echo "\033[31merror:\033[0m `basename $$dir` not equal"; \
			diff "$$dir/BUILD.bazel" "Tests/Pods/`basename $$dir`/BUILD.bazel"; \
			exit_code=1; \
		else \
			echo "`basename $$dir` \033[32mok!\033[0m";\
		fi; \
	done; \
	if [ $$exit_code -eq 1 ]; then \
		echo "\033[31mTests failed\033[0m"; \
		exit 1; \
	else \
		echo "\033[32mTests success\033[0m"; \
	fi

.PHONY: tests
tests: prepare-tests diff-generated-files

record-tests:
	rm -rf Tests/Recorded
	-mkdir Tests/Recorded
	@for dir in Tests/Pods/*/ ; do \
		if [ -f "$$dir/BUILD.bazel" ]; then \
			echo $$dir; \
			mkdir Tests/Recorded/`basename $$dir` ; \
			cp $$dir/BUILD.bazel Tests/Recorded/`basename $$dir`/ ; \
	    fi; \
	done

integration-setup:
	swift TestTools/generate_podfile.swift TestTools/Pods_Integration.json TestTools/Podfile_template > IntegrationTests/Podfile
	cd IntegrationTests && pod install
	swift TestTools/generate_buildfile.swift TestTools/Pods_Integration.json TestTools/BUILD_template //IntegrationTests > IntegrationTests/BUILD.bazel

integration-generate-static:
	bazel run :bazelpods $(CONFIG) -- \
	--src "$(shell pwd)/IntegrationTests" \
	--deps-prefix "//IntegrationTests/Pods" \
	--pods-root "IntegrationTests/Pods" \
	--platforms ios osx \
	--patches bundle_deduplicate arm64_to_sim_forced missing_sdks \
	-a -d \
	--color yes \
	--log-level debug

integration-generate-dynamic:
	bazel run :bazelpods $(CONFIG) -- \
	--src "$(shell pwd)/IntegrationTests" \
	--deps-prefix "//IntegrationTests/Pods" \
	--pods-root "IntegrationTests/Pods" \
	--platforms ios osx \
	-a -f -d \
	--color yes \
	--log-level debug \
	--patches bundle_deduplicate arm64_to_sim_forced missing_sdks user_options \
	--user-options "CocoaLumberjack.platform_ios.sdk_frameworks += CoreGraphics"

integration-build-x86_64:
	bazel build $(CONFIG) //IntegrationTests:TestApp_iOS --ios_multi_cpus=x86_64
	bazel build $(CONFIG) //IntegrationTests:TestApp_osx --macos_cpus=x86_64

integration-build-arm64:
	bazel build $(CONFIG) //IntegrationTests:TestApp_iOS --ios_multi_cpus=sim_arm64
	bazel build $(CONFIG) //IntegrationTests:TestApp_osx --macos_cpus=arm64

integration-clean:
	-cd IntegrationTests; \
	rm BUILD.bazel Podfile Podfile.lock; \
	rm -rf Pods

integration-static:
	$(MAKE) integration-clean
	$(MAKE) integration-setup
	$(MAKE) integration-generate-static
	$(MAKE) integration-build-x86_64
	$(MAKE) integration-build-arm64

integration-dynamic:
	$(MAKE) integration-clean
	$(MAKE) integration-setup
	$(MAKE) integration-generate-dynamic
	$(MAKE) integration-build-x86_64
	$(MAKE) integration-build-arm64

integration-run-arm64:
	bazel run //IntegrationTests:TestApp_iOS --ios_multi_cpus=sim_arm64

integration-run-x86_64:
	bazel run //IntegrationTests:TestApp_iOS --ios_multi_cpus=x86_64


