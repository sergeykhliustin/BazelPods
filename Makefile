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

prepare-tests:
	swift TestTools/generate_podfile.swift TestTools/TopPods.json TestTools/Podfile_template > Tests/Podfile
	cd Tests && pod install
	bazel run :Generator $(CONFIG) -- \
	--src "$(shell pwd)/Tests" \
	--deps-prefix "//Tests/Pods" \
	--pods-root "Tests/Pods" -a -f -c \
	--min-ios "10.0" \
	--color yes \
	--log-level debug \
	--user-options \
	"Bolts.sdk_frameworks += CoreGraphics, WebKit" \
	"SDWebImage.sdk_frameworks += CoreGraphics, CoreImage, QuartzCore, Accelerate" \
	"CocoaLumberjack.sdk_frameworks += CoreGraphics" \
	"FBSDKCoreKit.sdk_frameworks += StoreKit"

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
	swift TestTools/generate_podfile.swift TestTools/TopPods_Integration.json TestTools/Podfile_template > IntegrationTests/Podfile
	cd IntegrationTests && pod install
	swift TestTools/generate_buildfile.swift TestTools/TopPods_Integration.json TestTools/BUILD_template //IntegrationTests > IntegrationTests/BUILD.bazel

integration-generate-static:
	bazel run :Generator $(CONFIG) -- \
	--src "$(shell pwd)/IntegrationTests" \
	--deps-prefix "//IntegrationTests/Pods" \
	--pods-root "IntegrationTests/Pods" \
	-a -c \
	--color yes \
	--log-level debug \

integration-generate-dynamic:
	bazel run :Generator $(CONFIG) -- \
	--src "$(shell pwd)/IntegrationTests" \
	--deps-prefix "//IntegrationTests/Pods" \
	--pods-root "IntegrationTests/Pods" \
	-a -c -f \
	--color yes \
	--log-level debug \
	--user-options \
	"Bolts.sdk_frameworks += CoreGraphics, WebKit" \
	"SDWebImage.sdk_frameworks += CoreGraphics, CoreImage, QuartzCore, Accelerate" \
	"CocoaLumberjack.sdk_frameworks += CoreGraphics" \
	"FBSDKCoreKit.sdk_frameworks += StoreKit" \
	"GoogleUtilities.sdk_frameworks += CoreTelephony"

integration-build-x86_64:
	bazel build $(CONFIG) //IntegrationTests:TestApp_iOS --ios_multi_cpus=x86_64

integration-build-arm64:
	bazel build $(CONFIG) //IntegrationTests:TestApp_iOS --ios_multi_cpus=sim_arm64

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

integration: 
	$(MAKE) integration-clean
	$(MAKE) integration-setup
	$(MAKE) integration-generate-static
	$(MAKE) integration-build-x86_64
	$(MAKE) integration-build-arm64
	$(MAKE) integration-generate-dynamic
	$(MAKE) integration-build-x86_64
	$(MAKE) integration-build-arm64

integration-run-arm64:
	bazel run //IntegrationTests:TestApp_iOS --ios_multi_cpus=sim_arm64

integration-run-x86_64:
	bazel run //IntegrationTests:TestApp_iOS --ios_multi_cpus=x86_64


