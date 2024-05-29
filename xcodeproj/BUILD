load(
    "@rules_xcodeproj//xcodeproj:defs.bzl",
    "top_level_target",
    "xcodeproj",
    "xcschemes"
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
    generation_mode = "incremental",
    xcschemes = [
        xcschemes.scheme(
            name = BAZELPODS,
            run = xcschemes.run(
                build_targets = ["//:%s" % BAZELPODS],
                launch_target = "//:%s" % BAZELPODS
            ),
        ),
        xcschemes.scheme(
            name = BAZELPODS + " Compile",
            run = xcschemes.run(
                build_targets = ["//:%s" % BAZELPODS],
                launch_target = "//:%s" % BAZELPODS,
                args = ["compile --src $SRCROOT/Tests --log-level debug --patches bundle_deduplicate arm64_to_sim missing_sdks --no-concurrency --podspec $SRCROOT/Tests/Pods/FirebaseDatabase/FirebaseDatabase.json"]
            ),
        ),
        xcschemes.scheme(
            name = BAZELPODS + " Tests",
            run = xcschemes.run(
                build_targets = ["//:%s" % BAZELPODS],
                launch_target = "//:%s" % BAZELPODS,
                args = ["--src $SRCROOT/Tests -a --log-level debug --patches bundle_deduplicate arm64_to_sim missing_sdks --diff --no-concurrency --deps-prefix //Tests/Pods"]
            ),
        ),
        xcschemes.scheme(
            name = BAZELPODS + " Tests Frameworks",
            run = xcschemes.run(
                build_targets = ["//:%s" % BAZELPODS],
                launch_target = "//:%s" % BAZELPODS,
                args = ["--src $SRCROOT/Tests -a -f --log-level debug --patches bundle_deduplicate arm64_to_sim missing_sdks --diff"]
            ),
        ),
        xcschemes.scheme(
            name = BAZELPODS + " arm64sim Tests",
            run = xcschemes.run(
                build_targets = ["//:%s" % BAZELPODS],
                launch_target = "//:%s" % BAZELPODS,
                args = ["arm64sim --src $SRCROOT/Tests --log-level debug"]
            ),
        ),
        xcschemes.scheme(
            name = BAZELPODS + " arm64sim Tests Frameworks",
            run = xcschemes.run(
                build_targets = ["//:%s" % BAZELPODS],
                launch_target = "//:%s" % BAZELPODS,
                args = ["arm64sim --src $SRCROOT/Tests -f --log-level debug"]
            ),
        ),
        xcschemes.scheme(
            name = BAZELPODS + " IntegrationTests",
            run = xcschemes.run(
                build_targets = ["//:%s" % BAZELPODS],
                launch_target = "//:%s" % BAZELPODS,
                args = ["--src $SRCROOT/IntegrationTests -a --log-level debug --patches bundle_deduplicate arm64_to_sim missing_sdks --diff"]
            ),
        ),
        xcschemes.scheme(
            name = BAZELPODS + " IntegrationTests Frameworks",
            run = xcschemes.run(
                build_targets = ["//:%s" % BAZELPODS],
                launch_target = "//:%s" % BAZELPODS,
                args = ["--src $SRCROOT/IntegrationTests -a -f --log-level debug --patches bundle_deduplicate arm64_to_sim missing_sdks --diff"]
            ),
        ),
        xcschemes.scheme(
            name = BAZELPODS + " arm64sim IntegrationTests",
            run = xcschemes.run(
                build_targets = ["//:%s" % BAZELPODS],
                launch_target = "//:%s" % BAZELPODS,
                args = ["arm64sim --src $SRCROOT/IntegrationTests --log-level debug"]
            ),
        ),
        xcschemes.scheme(
            name = BAZELPODS + " arm64sim IntegrationTests Frameworks",
            run = xcschemes.run(
                build_targets = ["//:%s" % BAZELPODS],
                launch_target = "//:%s" % BAZELPODS,
                args = ["arm64sim --src $SRCROOT/IntegrationTests -f --log-level debug"]
            ),
        ),
    ],
    tags = ["manual"],
)
