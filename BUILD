load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@build_bazel_rules_apple//apple:macos.bzl", "macos_command_line_application")
load("@rules_cc//cc:defs.bzl", "objc_library")

SWIFT_VERSION = "5"

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

# Logger
swift_library(
    name = "Logger",
    srcs = glob(["Sources/Logger/**/*.swift"]),
    copts = ["-swift-version", SWIFT_VERSION],
)

# CompilerCore is a core library enabling Starlark code generation
swift_library(
    name = "CompilerCore",
    srcs = glob([
        "Sources/CompilerCore/**/*.swift",
        "Sources/Shared/**/*.swift"
    ]),
    deps = [":ObjcSupport", ":Logger"],
    copts = ["-swift-version", SWIFT_VERSION],
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
    srcs = glob([
        "Sources/Compiler/**/*.swift",
        "Sources/Shared/**/*.swift"
    ]),
    deps = [":CompilerCore", ":Logger", "@bazelpods-swift-argument-parser//:ArgumentParser"],
    copts = ["-swift-version", SWIFT_VERSION],
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
    srcs = glob([
        "Sources/Generator/**/*.swift",
        "Sources/Shared/**/*.swift"
    ]),
    deps = [":CompilerCore", ":Logger", "@bazelpods-swift-argument-parser//:ArgumentParser"],
    copts = ["-swift-version", SWIFT_VERSION],
)

# Analyzer

macos_command_line_application(
    name = "Analyzer",
    minimum_os_version = "10.11",
    deps = [":AnalyzerLib"],
    visibility = ["//xcodeproj:__pkg__"]
)

swift_library(
    name = "AnalyzerLib",
    srcs = glob([
        "Sources/Analyzer/**/*.swift",
        "Sources/Shared/**/*.swift"
    ]),
    deps = [":CompilerCore", ":Logger", "@bazelpods-swift-argument-parser//:ArgumentParser"],
    copts = ["-swift-version", SWIFT_VERSION],
)
