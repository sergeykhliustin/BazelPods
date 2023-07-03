load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "a656466b0af05c2345b7e090cfced2db791d2719126b3297beb26626ec7da208",
    url = "https://github.com/bazelbuild/rules_apple/releases/download/2.4.0/rules_apple.2.4.0.tar.gz",
)

http_archive(
    name = "build_bazel_rules_swift",
    sha256 = "84e2cc1c9e3593ae2c0aa4c773bceeb63c2d04c02a74a6e30c1961684d235593",
    url = "https://github.com/bazelbuild/rules_swift/releases/download/1.5.1/rules_swift.1.5.1.tar.gz",
)

http_archive(
    name = "build_bazel_rules_ios",
    sha256 = "ec856c88d2f767431189e66031edc4c04626eb9b145338171d007f88f4a3df21",
    url = "https://github.com/bazel-ios/rules_ios/releases/download/2.0.1/rules_ios.2.0.1.tar.gz",
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