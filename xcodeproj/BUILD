load(
    "@rules_xcodeproj//xcodeproj:defs.bzl",
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
            name = BAZELPODS + " Compile",
            build_action = xcode_schemes.build_action(targets = ["//:%s" % BAZELPODS]),
            launch_action = xcode_schemes.launch_action(
                target = "//:%s" % BAZELPODS,
                args = ["compile --src $SRCROOT/Tests --log-level debug --patches bundle_deduplicate arm64_to_sim missing_sdks --no-concurrency --podspec $SRCROOT/Tests/Pods/FirebaseDatabase/FirebaseDatabase.json"]
            ),
        ),
        xcode_schemes.scheme(
            name = BAZELPODS + " Tests",
            build_action = xcode_schemes.build_action(targets = ["//:%s" % BAZELPODS]),
            launch_action = xcode_schemes.launch_action(
                target = "//:%s" % BAZELPODS,
                args = ["--src $SRCROOT/Tests -a --log-level debug --patches bundle_deduplicate arm64_to_sim missing_sdks --diff --no-concurrency --deps-prefix //Tests/Pods"]
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
        xcode_schemes.scheme(
            name = BAZELPODS + " IntegrationTests",
            build_action = xcode_schemes.build_action(targets = ["//:%s" % BAZELPODS]),
            launch_action = xcode_schemes.launch_action(
                target = "//:%s" % BAZELPODS,
                args = ["--src $SRCROOT/IntegrationTests -a --log-level debug --patches bundle_deduplicate arm64_to_sim missing_sdks --diff"]
            ),
        ),
        xcode_schemes.scheme(
            name = BAZELPODS + " IntegrationTests Frameworks",
            build_action = xcode_schemes.build_action(targets = ["//:%s" % BAZELPODS]),
            launch_action = xcode_schemes.launch_action(
                target = "//:%s" % BAZELPODS,
                args = ["--src $SRCROOT/IntegrationTests -a -f --log-level debug --patches bundle_deduplicate arm64_to_sim missing_sdks --diff"]
            ),
        ),
        xcode_schemes.scheme(
            name = BAZELPODS + " arm64sim IntegrationTests",
            build_action = xcode_schemes.build_action(targets = ["//:%s" % BAZELPODS]),
            launch_action = xcode_schemes.launch_action(
                target = "//:%s" % BAZELPODS,
                args = ["arm64sim --src $SRCROOT/IntegrationTests --log-level debug"]
            ),
        ),
        xcode_schemes.scheme(
            name = BAZELPODS + " arm64sim IntegrationTests Frameworks",
            build_action = xcode_schemes.build_action(targets = ["//:%s" % BAZELPODS]),
            launch_action = xcode_schemes.launch_action(
                target = "//:%s" % BAZELPODS,
                args = ["arm64sim --src $SRCROOT/IntegrationTests -f --log-level debug"]
            ),
        ),
    ],
    tags = ["manual"],
)
