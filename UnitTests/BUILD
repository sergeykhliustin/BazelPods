load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@build_bazel_rules_apple//apple:macos.bzl", "macos_unit_test")
# This tests RepoToolsCore and Starlark logic
swift_library(
    name = "PodToBUILDTestsLib",
    srcs = glob(["PodToBUILDTests/*.swift"]),
    deps = [
        "//:PodToBUILD",
        "@bazelpods-SwiftCheck//:SwiftCheck",
    ],
    data = glob(["Examples/**/*.podspec.json"])
)

macos_unit_test(
    name = "PodToBUILDTests",
    deps = [":PodToBUILDTestsLib"],
    minimum_os_version = "10.11",
)

swift_library(
    name = "BuildTestsLib",
    srcs = glob(["BuildTests/*.swift"]),
    deps = [
        "@bazelpods-SwiftCheck//:SwiftCheck",
        "//:PodToBUILD",
    ],
    data = glob(["Examples/**/*.podspec.json"])
)

# This tests RepoToolsCore and Starlark logic
macos_unit_test(
    name = "BuildTests",
    deps = [":BuildTestsLib"],
    minimum_os_version = "10.11",
)