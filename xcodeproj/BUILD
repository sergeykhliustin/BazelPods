load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl",
    "top_level_target",
    "xcodeproj",
    "xcode_schemes",
)

BAZELPODS = "bazelpods"

xcodeproj(
    name = "xcodeproj",
    project_name = "BazelPods",
    pre_build = """
export PATH="$PATH:/opt/homebrew/bin"

if which swiftlint >/dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
    """,
    top_level_targets = [
        top_level_target("//:bazelpods", target_environments = []),
        top_level_target("//:Analyzer", target_environments = []),
    ],
    schemes = [
        xcode_schemes.scheme(
            name = BAZELPODS,
            build_action = xcode_schemes.build_action(targets = ["//:%s" % BAZELPODS]),
            launch_action = xcode_schemes.launch_action(target = "//:%s" % BAZELPODS),
        ),
        xcode_schemes.scheme(
            name = BAZELPODS + " Tests",
            build_action = xcode_schemes.build_action(targets = ["//:%s" % BAZELPODS]),
            launch_action = xcode_schemes.launch_action(
                target = "//:%s" % BAZELPODS,
                args = ["--src $SRCROOT/Tests -a --log-level debug --patches bundle_deduplicate arm64_to_sim missing_sdks --diff"]
            ),
        ),
        xcode_schemes.scheme(
            name = BAZELPODS + " Tests Frameworks",
            build_action = xcode_schemes.build_action(targets = ["//:%s" % BAZELPODS]),
            launch_action = xcode_schemes.launch_action(
                target = "//:%s" % BAZELPODS,
                args = ["--src $SRCROOT/Tests -a -f --log-level debug --patches bundle_deduplicate arm64_to_sim missing_sdks --diff"]
            ),
        ),
        xcode_schemes.scheme(
            name = BAZELPODS + " arm64sim Tests",
            build_action = xcode_schemes.build_action(targets = ["//:%s" % BAZELPODS]),
            launch_action = xcode_schemes.launch_action(
                target = "//:%s" % BAZELPODS,
                args = ["arm64sim --src $SRCROOT/Tests --log-level debug"]
            ),
        ),
        xcode_schemes.scheme(
            name = BAZELPODS + " arm64sim Tests Frameworks",
            build_action = xcode_schemes.build_action(targets = ["//:%s" % BAZELPODS]),
            launch_action = xcode_schemes.launch_action(
                target = "//:%s" % BAZELPODS,
                args = ["arm64sim --src $SRCROOT/Tests -f --log-level debug"]
            ),
        ),
    ],
    tags = ["manual"],
)
