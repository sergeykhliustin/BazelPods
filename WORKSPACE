load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "a19cf84dd060eda50be9ba5b0eca88377e0306ffbc1cc059df6a6947e48ac61a",
    url = "https://github.com/bazelbuild/rules_apple/releases/download/1.1.1/rules_apple.1.1.1.tar.gz",
)

http_archive(
    name = "build_bazel_rules_swift",
    sha256 = "043897b483781cfd6cbd521569bfee339c8fbb2ad0f0bdcd1b3749523a262cf4",
    url = "https://github.com/bazelbuild/rules_swift/releases/download/1.1.1/rules_swift.1.1.1.tar.gz",
)

load("@build_bazel_rules_apple//apple:repositories.bzl", "apple_rules_dependencies")

apple_rules_dependencies()

load("@build_bazel_rules_swift//swift:repositories.bzl", "swift_rules_dependencies")

swift_rules_dependencies()

load("@build_bazel_rules_swift//swift:extras.bzl", "swift_rules_extra_dependencies")

swift_rules_extra_dependencies()

http_archive(
    name = "build_bazel_rules_ios",
    sha256 = "ed9111f335bdbfe273da27f614448d764d9c710cd380e35f7c1bb413db339b84",
    strip_prefix = "rules_ios-bb79e0327f8a7ff73b96be24f74dbd3b9a0d101c",
    url = "https://github.com/bazel-ios/rules_ios/archive/bb79e0327f8a7ff73b96be24f74dbd3b9a0d101c.zip"
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