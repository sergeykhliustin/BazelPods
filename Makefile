
.PHONY: xcodeproj
xcodeproj:
	bazel run xcodeproj

clean:
	bazel clean

expunge:
	bazel clean --expunge
	rm -rf .bazel-cache

prepare-tests:
	swift TestTools/generate_podfile.swift TestTools/TopPods.json TestTools/Podfile_template > Tests/Podfile
	cd Tests && pod install
	bazel run :Generator --config=ci -- "Pods/Pods.json" \
	--src "$(shell pwd)/Tests" \
	--deps-prefix "//Tests/Pods" \
	--pods-root "Tests/Pods" -a -f \
	--min-ios "10.0" \
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
	bazel run :Generator --config=ci \
	-- "Pods/Pods.json" \
	--src "$(shell pwd)/IntegrationTests" \
	--deps-prefix "//IntegrationTests/Pods" \
	--pods-root "IntegrationTests/Pods" \
	--min-ios "13.0" \
	-a -c

integration-generate-dynamic:
	bazel run :Generator --config=ci \
	-- "Pods/Pods.json" \
	--src "$(shell pwd)/IntegrationTests" \
	--deps-prefix "//IntegrationTests/Pods" \
	--pods-root "IntegrationTests/Pods" \
	-a -c -f \
	--min-ios "13.0" \
	--user-options \
	"Bolts.sdk_frameworks += CoreGraphics, WebKit" \
	"SDWebImage.sdk_frameworks += CoreGraphics, CoreImage, QuartzCore, Accelerate" \
	"CocoaLumberjack.sdk_frameworks += CoreGraphics" \
	"FBSDKCoreKit.sdk_frameworks += StoreKit" \
	"GoogleUtilities.sdk_frameworks += CoreTelephony"

integration-build:
	bazel build --config=ci //IntegrationTests:TestApp_iOS --apple_platform_type=ios --ios_minimum_os=13.4 --ios_simulator_device="iPhone 8" --ios_multi_cpus=x86_64
	bazel build --config=ci //IntegrationTests:TestApp_iOS --apple_platform_type=ios --ios_minimum_os=13.4 --ios_simulator_device="iPhone 8" --ios_multi_cpus=sim_arm64

integration-clean:
	-cd IntegrationTests; \
	rm BUILD.bazel Podfile Podfile.lock; \
	rm -rf Pods

integration-static: 
	$(MAKE) integration-clean
	$(MAKE) integration-setup
	$(MAKE) integration-generate-static
	$(MAKE) integration-build

integration-dynamic: 
	$(MAKE) integration-clean
	$(MAKE) integration-setup
	$(MAKE) integration-generate-dynamic
	$(MAKE) integration-build

integration: 
	$(MAKE) integration-clean
	$(MAKE) integration-setup
	$(MAKE) integration-generate-static
	$(MAKE) integration-build
	$(MAKE) integration-generate-dynamic
	$(MAKE) integration-build


