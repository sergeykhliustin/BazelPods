load(
    "@bazel_tools//tools/build_defs/repo:git.bzl",
    "git_repository",
    "new_git_repository",
)
load(
    "@bazel_tools//tools/build_defs/repo:http.bzl",
    "http_archive"
)

NAMESPACE_PREFIX = "bazelpods_"

def namespaced_name(name):
    if name.startswith("@"):
        return name.replace("@", "@%s" % NAMESPACE_PREFIX)
    return NAMESPACE_PREFIX + name

def namespaced_dep_name(name):
    if name.startswith("@"):
        return name.replace("@", "@%s" % NAMESPACE_PREFIX)
    return name

def namespaced_new_git_repository(name, **kwargs):
    new_git_repository(
        name = namespaced_name(name),
        **kwargs
    )

def namespaced_git_repository(name, **kwargs):
    git_repository(
        name = namespaced_name(name),
        **kwargs
    )

def namespaced_http_archive(name, **kwargs):
    http_archive(
        name = namespaced_name(name),
        **kwargs
    )

def namespaced_build_file(libs):
    return """
package(default_visibility = ["//visibility:public"])
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
""" + "\n\n".join(libs)

def namespaced_swift_library(name, srcs, deps = None, defines = None, copts=[]):
    deps = [] if deps == None else deps
    defines = [] if defines == None else defines
    return """
swift_library(
    name = "{name}",
    srcs = glob([{srcs}]),
    module_name = "{name}",
    deps = [{deps}],
    defines = [{defines}],
    copts = ["-DSWIFT_PACKAGE", {copts}],
    visibility = ["//visibility:public"],
)""".format(**dict(
        name = name,
        srcs = ",\n".join(['"%s"' % x for x in srcs]),
        defines = ",\n".join(['"%s"' % x for x in defines]),
        deps = ",\n".join(['"%s"' % namespaced_dep_name(x) for x in deps]),
        copts = ",\n".join(['"%s"' % x for x in copts]),
    ))

def bazelpods_dependencies():
    namespaced_http_archive(
        name = "swift_argument_parser",
        url = "https://github.com/apple/swift-argument-parser/archive/refs/tags/1.3.0.tar.gz",
        strip_prefix = "swift-argument-parser-1.3.0",
        sha256 = "e5010ff37b542807346927ba68b7f06365a53cf49d36a6df13cef50d86018204",
        build_file_content = namespaced_build_file([
            namespaced_swift_library(
                name = "ArgumentParser",
                srcs = ["Sources/ArgumentParser/**/*.swift"],
                deps = [":ArgumentParserToolInfo"],
                copts = [
                    "-enable-library-evolution",
                    "-swift-version", 
                    "5"
                ],
            ),
            namespaced_swift_library(
                name = "ArgumentParserToolInfo",
                srcs = ["Sources/ArgumentParserToolInfo/**/*.swift"],
                copts = [
                    "-enable-library-evolution",
                    "-swift-version", "5"
                ],
            )
        ])
    )

non_module_deps = module_extension(
    implementation = lambda _: bazelpods_dependencies()
)
