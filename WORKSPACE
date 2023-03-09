load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "43737f28a578d8d8d7ab7df2fb80225a6b23b9af9655fcdc66ae38eb2abcf2ed",
    url = "https://github.com/bazelbuild/rules_apple/releases/download/2.0.0/rules_apple.2.0.0.tar.gz",
)

http_archive(
    name = "build_bazel_rules_swift",
    sha256 = "84e2cc1c9e3593ae2c0aa4c773bceeb63c2d04c02a74a6e30c1961684d235593",
    url = "https://github.com/bazelbuild/rules_swift/releases/download/1.5.1/rules_swift.1.5.1.tar.gz",
)

http_archive(
    name = "build_bazel_rules_ios",
    sha256 = "68cf4870875f077a30f0fdec732c38f8f6dce31aa9c37a4ae82750810844ed4c",
    strip_prefix = "rules_ios-ea40a7b13dd1a29a454de2268a3799a65907501a",
    url = "https://github.com/bazel-ios/rules_ios/archive/ea40a7b13dd1a29a454de2268a3799a65907501a.zip"
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
    sha256 = "d02932255ba3ffaab1859e44528c69988e93fa353fa349243e1ef5054bd1ba80",
    url = "https://github.com/buildbuddy-io/rules_xcodeproj/releases/download/1.2.0/release.tar.gz",
)

load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:repositories.bzl",
    "xcodeproj_rules_dependencies",
)

xcodeproj_rules_dependencies()