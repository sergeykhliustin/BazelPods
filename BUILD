load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@build_bazel_rules_apple//apple:macos.bzl", "macos_command_line_application")
load("@rules_cc//cc:defs.bzl", "objc_library")

# CI configuration
xcode_version(
  name = 'version14_2_0_14C18',
  version = '14.2.0.14C18',
  aliases = ['14.2.0.14C18', '14.2.0', '14C18', '14.2', '14'],
  default_ios_sdk_version = '16.2',
  default_tvos_sdk_version = '16.1',
  default_macos_sdk_version = '13.1',
  default_watchos_sdk_version = '9.1',
)

xcode_config(
  name = 'host_xcodes',
  versions = [':version14_2_0_14C18'],
  default = ':version14_2_0_14C18',
)
# End CI configuration

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
    visibility = ["//xcodeproj:__pkg__"]
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
    visibility = ["//xcodeproj:__pkg__"]
)

swift_library(
    name = "GeneratorLib",
    srcs = glob(["Sources/Generator/**/*.swift"]),
    deps = [":PodToBUILD", "@bazelpods-swift-argument-parser//:ArgumentParser"],
    copts = ["-swift-version", "5"],
)
