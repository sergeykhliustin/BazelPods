
integration-setup:
	cd IntegrationTests; \
	swift generate_pods.swift; \
	pod install

integration-generate:
	bazel run :Generator -- "Pods/Pods.json" --src "$(shell pwd)/IntegrationTests" --deps-prefix "//IntegrationTests/Pods" --pods-root "IntegrationTests/Pods" -a -c

integration-generate-dynamic:
	bazel run :Generator -- "Pods/Pods.json" --src "$(shell pwd)/IntegrationTests" --deps-prefix "//IntegrationTests/Pods" --pods-root "IntegrationTests/Pods" -a -c -f --extra-sdk CoreGraphics CoreImage StoreKit QuartzCore WebKit Accelerate

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

integration: integration-static integration-dynamic

clean:
	bazel clean

expunge:
	bazel clean --expunge
	rm -rf .bazel-cache
