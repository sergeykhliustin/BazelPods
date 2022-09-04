load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@build_bazel_rules_apple//apple:macos.bzl", "macos_command_line_application")
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
    srcs = glob(["Sources/PodToBUILD/**/*.swift"]),
    deps = [":ObjcSupport"],
    copts = ["-swift-version", "5"],
    visibility = ["//Tests:__pkg__"]
)

# Compiler
macos_command_line_application(
    name = "Compiler",
    minimum_os_version = "10.11",
    deps = [":CompilerLib"],
)

swift_library(
    name = "CompilerLib",
    srcs = glob(["Sources/Compiler/**/*.swift"]),
    deps = [":PodToBUILD", "@bazelpods-swift-argument-parser//:ArgumentParser"],
    copts = ["-swift-version", "5"],
)

# Generator

macos_command_line_application(
    name = "Generator",
    minimum_os_version = "10.11",
    deps = [":GeneratorLib"],
)

swift_library(
    name = "GeneratorLib",
    srcs = glob(["Sources/Generator/**/*.swift"]),
    deps = [":PodToBUILD", "@bazelpods-swift-argument-parser//:ArgumentParser"],
    copts = ["-swift-version", "5"],
)
