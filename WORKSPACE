load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "2a0a35c9f72a0b0ac9238ecb081b0da4bb3e9739e25d2a910cc6b4c4425c01be",
    url = "https://github.com/bazelbuild/rules_apple/releases/download/2.4.1/rules_apple.2.4.1.tar.gz",
)

http_archive(
    name = "build_bazel_rules_swift",
    sha256 = "b3b6c5c9f2a589150f71e79dec1e1ed0eb974dbd49e9317df4e09e08ff6e83df",
    url = "https://github.com/bazelbuild/rules_swift/releases/download/1.9.1/rules_swift.1.9.1.tar.gz",
)

http_archive(
    name = "build_bazel_rules_ios",
    sha256 = "88dc6c5d1aade86bc4e26cbafa62595dffd9f3821f16e8ba8461f372d66a5783",
    url = "https://github.com/bazel-ios/rules_ios/releases/download/2.1.0/rules_ios.2.1.0.tar.gz",
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
    name = "com_github_buildbuddy_io_rules_xcodeproj",
    sha256 = "f836d2a516a911dc0ace44b1f51aa575613f149a934f4be1e7bd551a549672ff",
    url = "https://github.com/buildbuddy-io/rules_xcodeproj/releases/download/1.7.1/release.tar.gz",
)

load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:repositories.bzl",
    "xcodeproj_rules_dependencies",
)

xcodeproj_rules_dependencies()