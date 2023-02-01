load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "43737f28a578d8d8d7ab7df2fb80225a6b23b9af9655fcdc66ae38eb2abcf2ed",
    url = "https://github.com/bazelbuild/rules_apple/releases/download/2.0.0/rules_apple.2.0.0.tar.gz",
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
    sha256 = "dfff3ecdce0ca1c1f7ca619b8a7e9f83f22a553f16d2ec321557f1fc4f173b94",
    strip_prefix = "rules_ios-985d578d8d4c3e4b6fe23dc69436ecafa33d30b4",
    url = "https://github.com/bazel-ios/rules_ios/archive/985d578d8d4c3e4b6fe23dc69436ecafa33d30b4.zip"
)

load("@build_bazel_rules_ios//rules:repositories.bzl", "rules_ios_dependencies")

rules_ios_dependencies()

load("//:repositories.bzl", "bazelpods_dependencies", "bazelpodstests_dependencies")

bazelpods_dependencies()
bazelpodstests_dependencies()

http_archive(
    name = "com_github_buildbuddy_io_rules_xcodeproj",
    sha256 = "9a39f62430765347b15ec6a64061f9a4f33de9e0dc7df3178dcf5aafb3316303",
    url = "https://github.com/buildbuddy-io/rules_xcodeproj/releases/download/1.0.0rc2/release.tar.gz",
)

load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:repositories.bzl",
    "xcodeproj_rules_dependencies",
)

xcodeproj_rules_dependencies()