load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl",
    "top_level_target",
    "xcodeproj",
)

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
        top_level_target("//:Compiler", target_environments = []),
        top_level_target("//:Generator", target_environments = []),
        top_level_target("//:Analyzer", target_environments = []),
    ],
    tags = ["manual"],
)
