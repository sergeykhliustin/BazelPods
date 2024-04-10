load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_ios",
    sha256 = "8b7ad824844b6e8531ecf53786a0171f0ac937e659b5371aeefd24cda2d382de",
    url = "https://github.com/bazel-ios/rules_ios/releases/download/4.2.1/rules_ios.4.2.1.tar.gz",
)

load(
    "@build_bazel_rules_ios//rules:repositories.bzl",
    "rules_ios_dependencies"
)

rules_ios_dependencies()

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)

apple_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:extras.bzl",
    "swift_rules_extra_dependencies",
)

swift_rules_extra_dependencies()

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()

load("//:repositories.bzl", "bazelpods_dependencies", "bazelpodstests_dependencies")

bazelpods_dependencies()
bazelpodstests_dependencies()

http_archive(
    name = "rules_xcodeproj",
    sha256 = "c387249eb50e10e88281d838b6a8d4bf290ac4d0697808ef03ae442f4b56368b",
    url = "https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/download/2.1.1/release.tar.gz",
)

load(
    "@rules_xcodeproj//xcodeproj:repositories.bzl",
    "xcodeproj_rules_dependencies",
)

xcodeproj_rules_dependencies()

load("@bazel_features//:deps.bzl", "bazel_features_deps")

bazel_features_deps()