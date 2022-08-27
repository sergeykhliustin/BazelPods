load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@build_bazel_rules_apple//apple:macos.bzl", "macos_command_line_application", "macos_unit_test")
load("@rules_cc//cc:defs.bzl", "objc_library")

objc_library(
    name = "ObjcSupport",
    srcs = glob(["Sources/ObjcSupport/*.m"]),
    hdrs = glob(["Sources/ObjcSupport/include/*"]),
    includes = ["Sources/ObjcSupport/include"]
)

# PodToBUILD is a core library enabling Starlark code generation
swift_library(
    name = "PodToBUILD",
    srcs = glob(["Sources/PodToBUILD/*.swift"]),
    deps = [":ObjcSupport"],
    copts = ["-swift-version", "5"],
)

# Compiler
macos_command_line_application(
    name = "Compiler",
    minimum_os_version = "10.13",
    deps = [":CompilerLib"],
)

swift_library(
    name = "CompilerLib",
    srcs = glob(["Sources/Compiler/*.swift"]),
    deps = [":PodToBUILD", "@swift-argument-parser//:ArgumentParser"],
    copts = ["-swift-version", "5"],
)

# Generator

macos_command_line_application(
    name = "Generator",
    minimum_os_version = "10.13",
    deps = [":GeneratorLib"],
)

swift_library(
    name = "GeneratorLib",
    srcs = glob(["Sources/Generator/*.swift"]),
    deps = [":PodToBUILD", "@swift-argument-parser//:ArgumentParser"],
    copts = ["-swift-version", "5"],
)

# This tests RepoToolsCore and Starlark logic
swift_library(
    name = "PodToBUILDTestsLib",
    srcs = glob(["Tests/PodToBUILDTests/*.swift"]),
    deps = ["@podtobuild-SwiftCheck//:SwiftCheck"],
    data = glob(["Examples/**/*.podspec.json"])
)

macos_unit_test(
    name = "PodToBUILDTests",
    deps = [":PodToBUILDTestsLib"],
    minimum_os_version = "10.13",
)

swift_library(
    name = "BuildTestsLib",
    srcs = glob(["Tests/BuildTests/*.swift"]),
    deps = ["@podtobuild-SwiftCheck//:SwiftCheck"],
    data = glob(["Examples/**/*.podspec.json"])
)

# This tests RepoToolsCore and Starlark logic
macos_unit_test(
    name = "BuildTests",
    deps = [":BuildTestsLib"],
    minimum_os_version = "10.13",
)

