load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_ios",
    sha256 = "171675cc98edf10e4580f3f94319d0ff298f8d5e7d00fd5f8de802443d79e6bf",
    url = "https://github.com/bazel-ios/rules_ios/releases/download/2.3.0/rules_ios.2.3.0.tar.gz",
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
    sha256 = "d16de271048004ea27f98d6fefcb02214337920617a2678f58e8458980243a5f",
    url = "https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/download/1.12.1/release.tar.gz",
)

load(
    "@rules_xcodeproj//xcodeproj:repositories.bzl",
    "xcodeproj_rules_dependencies",
)

xcodeproj_rules_dependencies()