load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl",
    "top_level_target",
    "xcodeproj",
)

xcodeproj(
    name = "xcodeproj",
    project_name = "BazelPods",
    tags = ["manual"],
    top_level_targets = [
        top_level_target("//:Compiler", target_environments = []),
        top_level_target("//:Generator", target_environments = []),
        top_level_target("//:Analyzer", target_environments = []),
    ],
)