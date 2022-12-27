load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "f94e6dddf74739ef5cb30f000e13a2a613f6ebfa5e63588305a71fce8a8a9911",
    url = "https://github.com/bazelbuild/rules_apple/releases/download/1.1.3/rules_apple.1.1.3.tar.gz",
)

http_archive(
    name = "build_bazel_rules_swift",
    sha256 = "32f95dbe6a88eb298aaa790f05065434f32a662c65ec0a6aabdaf6881e4f169f",
    url = "https://github.com/bazelbuild/rules_swift/releases/download/1.5.0/rules_swift.1.5.0.tar.gz",
)

load("@build_bazel_rules_apple//apple:repositories.bzl", "apple_rules_dependencies")

apple_rules_dependencies()

load("@build_bazel_rules_swift//swift:repositories.bzl", "swift_rules_dependencies")

swift_rules_dependencies()

load("@build_bazel_rules_swift//swift:extras.bzl", "swift_rules_extra_dependencies")

swift_rules_extra_dependencies()

http_archive(
    name = "build_bazel_rules_ios",
    sha256 = "0c2bc221cd03c540e315b50f75b7a6c1c8b58dfca6b96c8aacc9f6bebf04505f",
    strip_prefix = "rules_ios-dfb604dceacb18ff4e240b89300257c06711b3a5",
    url = "https://github.com/bazel-ios/rules_ios/archive/dfb604dceacb18ff4e240b89300257c06711b3a5.zip"
)

load("@build_bazel_rules_ios//rules:repositories.bzl", "rules_ios_dependencies")

rules_ios_dependencies()

load("//:repositories.bzl", "bazelpods_dependencies", "bazelpodstests_dependencies")

bazelpods_dependencies()
bazelpodstests_dependencies()

http_archive(
    name = "com_github_buildbuddy_io_rules_xcodeproj",
    sha256 = "b4e71c7740bb8cfa4bc0b91c0f18ac512debcc111ebe471280e24f579a3b0782",
    url = "https://github.com/buildbuddy-io/rules_xcodeproj/releases/download/0.10.2/release.tar.gz",
)

load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:repositories.bzl",
    "xcodeproj_rules_dependencies",
)

xcodeproj_rules_dependencies()