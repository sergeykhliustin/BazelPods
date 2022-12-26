
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
	bazel run :Generator -- "Pods/Pods.json" \
	--src "$(shell pwd)/Tests" \
	--deps-prefix "//Tests/Pods" \
	--pods-root "Tests/Pods" -a -c -f \
	--user-options \
	"Bolts.sdk_frameworks += CoreGraphics, WebKit" \
	"SDWebImage.sdk_frameworks += CoreGraphics, CoreImage, QuartzCore, Accelerate" \
	"CocoaLumberjack.sdk_frameworks += CoreGraphics" \
	"FBSDKCoreKit.sdk_frameworks += StoreKit"

.PHONY: tests
tests:
	@if ! [ -n "$(shell find Tests/Recorded -type d)" ]; then \
        echo "Recorded tests are empty";\
        exit 1;\
    fi
	@for dir in Tests/Recorded/*/; do \
		if ! diff "$$dir/BUILD.bazel" "Tests/Pods/`basename $$dir`/BUILD.bazel" > /dev/null; then \
			echo "Error $(basename $$dir) not equal";\
			diff --color=always "$$dir/BUILD.bazel" "Tests/Pods/`basename $$dir`/BUILD.bazel"; \
			exit 1; \
		fi; \
	done
	@echo "Tests success"

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
	cd IntegrationTests; \
	swift generate_pods.swift; \
	pod install

integration-generate:
	bazel run :Generator -- "Pods/Pods.json" --src "$(shell pwd)/IntegrationTests" --deps-prefix "//IntegrationTests/Pods" --pods-root "IntegrationTests/Pods" -a -c

integration-generate-dynamic:
	bazel run :Generator -- "Pods/Pods.json" \
	--src "$(shell pwd)/IntegrationTests" \
	--deps-prefix "//IntegrationTests/Pods" \
	--pods-root "IntegrationTests/Pods" -a -c -f \
	--user-options \
	"Bolts.sdk_frameworks += CoreGraphics, WebKit" \
	"SDWebImage.sdk_frameworks += CoreGraphics, CoreImage, QuartzCore, Accelerate" \
	"CocoaLumberjack.sdk_frameworks += CoreGraphics" \
	"FBSDKCoreKit.sdk_frameworks += StoreKit"

integration-build:
	bazel build //IntegrationTests:TestApp_iOS --apple_platform_type=ios --ios_minimum_os=13.4 --ios_simulator_device="iPhone 8" --ios_multi_cpus=x86_64
	bazel build //IntegrationTests:TestApp_iOS --apple_platform_type=ios --ios_minimum_os=13.4 --ios_simulator_device="iPhone 8" --ios_multi_cpus=sim_arm64

integration-clean:
	cd IntegrationTests; \
	rm BUILD.bazel Podfile Podfile.lock; \
	rm -rf Pods;
	bazel clean

integration-static: integration-clean integration-setup integration-generate integration-build

integration-dynamic: integration-clean integration-setup integration-generate-dynamic integration-build

integration: 
	$(MAKE) integration-static
	$(MAKE) integration-dynamic


