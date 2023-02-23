#  BazelPods [![bazel-icon](https://user-images.githubusercontent.com/51409210/188334195-d558f4b3-cafb-4501-8dc7-ed4771508a09.svg)](https://bazel.build/) + [![favicon](https://user-images.githubusercontent.com/51409210/188334178-cbb1e7c9-aee3-4802-bcd2-81292d47d02d.png)](https://cocoapods.org/) 
![Snapshot tests status](https://github.com/BazelPods/BazelPods/actions/workflows/snapshot_tests.yml/badge.svg?branch=main) ![Integration tests static status](https://github.com/BazelPods/BazelPods/actions/workflows/integration_tests_static.yml/badge.svg?branch=main) ![Integration tests dynamic status](https://github.com/BazelPods/BazelPods/actions/workflows/integration_tests_dynamic.yml/badge.svg?branch=main)

One more way to build CocoaPods with Bazel. It generates Bazel's `BUILD` files for pods using awesome [rules_ios](https://github.com/bazel-ios/rules_ios).  
Core idea, Podspec parser, Starlark compiler are forked from [PodToBUILD](https://github.com/bazel-xcode/PodToBUILD)

#

### ⚙️ Status and features

|                                                                                 | iOS  | macOS | watchOS | tvOS |
| -                                                                               | -    | -     | -       | -    |
| static library                                                                  | ✅   | ✅     | ❓      | ❓   |
| dynamic (`use_framework!`)                                                      | ✅   | 🔜     | ❓      | ❓   |
| vendored static libs                                                            | ✅   | ❓     | ❓      | ❓   |
| vendored frameworks                                                             | ✅   | ❓     | ❓      | ❓   |
| vendored xcframeworks                                                           | ✅   | ❓     | ❓      | ❓   |
| bundles and resources                                                           | ✅   | ❓     | ❓      | ❓   |
| [rules_xcodeproj](https://github.com/buildbuddy-io/rules_xcodeproj)             | ✅   | ❓     | ❓      | ❓   |

###### ✅ - full support (report issues if no), 🔜 - not yet supported, ❓ - unknown, ❌ - not supported

  - [x] Autodetect vendored frameworks and libs architectures and ignore unsupported
  - [x] Local pods with custom paths, private pods (resolved by CocoaPods)
  - [ ] Nested subspecs (possibly works, but not tested yet)
  
 ### 🎸 Let's rock
Don't forget to setup [`rules_ios`](https://github.com/bazel-ios/rules_ios) and [`rules_apple`](https://github.com/bazelbuild/rules_apple) first.

Add `BazelPods` to your `WORKSPACE`
```starlark
http_archive(
    name = "bazel_pods",
    sha256 = "<sha256>",
    strip_prefix = "BazelPods-<version>",
    urls = ["https://github.com/sergeykhliustin/BazelPods/archive/refs/tags/<version>.tar.gz"],
)

load("@bazel_pods//:repositories.bzl", "bazelpods_dependencies")

bazelpods_dependencies()
```
Add `post_install` action to your `Podfile` and run `pod install`
```ruby
post_install do |installer|
  puts "Generating Pods.json"
  development_pods = installer.sandbox.development_pods
  mapped_pods = installer.analysis_result.specifications.reduce({}) { |result, spec|
    result[spec.name] = {
      name: spec.name,
      podspec: "#{spec.defined_in_file.to_s}",
      development_path: development_pods[spec.name]
    }
    result
  }
  File.open('Pods/Pods.json', 'w') { |file|
    file.write(JSON.pretty_generate(mapped_pods))
  }
end
```
Run `BazelPods`
```sh
bazel run @bazel_pods//:Generator -- --src $PWD
```
###### See full list of command line options [below](#%EF%B8%8F-command-line-options)  
Now you can add first level dependencies to your app as `//Pods/<pod_name>`  
Note: if you have multiplatform setup (`--platform` with more than 1 option), use `//Pods/<pod_name>:<pod_name>_<platform>`  
Enjoy :)

#### Patches
You can specify patches to use in order you want. Also you can use same patch several times.
- `bundle_deduplicate` checks if final bundle will contain bundles with same name and avoids them.  
For example, [GoogleMaps](https://github.com/CocoaPods/Specs/blob/master/Specs/a/d/d/GoogleMaps/7.3.0/GoogleMaps.podspec.json) contains `GoogleMaps.bundle` in `resources` and vendored `GoogleMaps.xcframework` also contains same bundle.
- `arm64_to_sim` patches legacy frameworks and libraries to support arm64 simulator. Read more [arm64-to-sim](https://github.com/bogo/arm64-to-sim)
- `user_options` applies options from `--user-options`. If not specified but `--user-options` not empty will be applied in the end.
- `missing_sdks` scans all sources for `import`, `@import` and `#import` to find missing sdk frameworks and adds them to final configuration.

### ⌨️ Command line options
Generator  
```
USAGE: Generator [<options>] --src <src>

OPTIONS:
  --src <src>             Sources root where Pods directory located (or renamed by podsRoot)
  --pods-json <pods-json> Pods.json (default: Pods/Pods.json)
  --platforms <platforms> Space separated platforms.
                          Valid values are: ios, osx, tvos, watchos. (default: ios)
  --min-ios <min-ios>     Minimum iOS version (default: 13.0)
  --patches <patches>     Patches. It will be applied in the order listed here.
                          Available options: bundle_deduplicate, arm64_to_sim, missing_sdks, user_options.
                          user_options requires --user-options configured.
                          If 'user_options' not specified, but --user_options exist, user_options patch are applied automatically.
  --user-options <user-options>
                          User extra options.
                          Supported fields: 'sdk_frameworks', 'sdk_dylibs', 'weak_sdk_frameworks', 'vendored_libraries', 'vendored_frameworks', 'vendored_xcframeworks', 'testonly', 'link_dynamic'.
                          Supported operators: '+=' (append), '-=' (delete), ':=' (replace).
                          Example:
                          'SomePod.sdk_dylibs += something,something'
                          'SomePod.testonly := true'
                          Platform specific:
                          'SomePod.platform_ios.sdk_dylibs += something,something'
  --deps-prefix <deps-prefix>
                          Dependencies prefix (default: //Pods)
  --pods-root <pods-root> Pods root relative to workspace. Used for headers search paths (default: Pods)
  -f, --frameworks        Packaging pods in dynamic frameworks if possible (same as `use_frameworks!`)
  --no-concurrency        Disable concurrency.
  --print-output          Print BUILD files contents to terminal output
  --dry-run               Dry run. Files will not be written
  -a, --add-podspec       Will add podspec.json to the pod directory. Just for debugging purposes.
  --color <color>         Logs color (auto|yes|no) (default: auto)
  --log-level <log-level> Log level (debug|info|warning|error|none) (default: info)
  -h, --help              Show help information.
```
Compiler  
```
USAGE: Compiler --src <src> --podspec <podspec> [--subspecs <subspecs> ...] [--platforms <platforms> ...] [--min-ios <min-ios>] [--patches <patches> ...] [--user-options <user-options> ...] [--deps-prefix <deps-prefix>] [--pods-root <pods-root>] [--no-concurrency] [--frameworks] [--log-level <log-level>]

OPTIONS:
  --src <src>             Sources root where Pods directory located (or renamed by podsRoot)
  --podspec <podspec>     podspec.json
  --subspecs <subspecs>   Subspecs list
  --platforms <platforms> Space separated platforms.
                          Valid values are: ios, osx, tvos, watchos. (default: ios)
  --min-ios <min-ios>     Minimum iOS version (default: 13.0)
  --patches <patches>     Patches. It will be applied in the order listed here.
                          Available options: bundle_deduplicate, arm64_to_sim, missing_sdks, user_options.
                          user_options requires --user-options configured.
                          If 'user_options' not specified, but --user_options exist, user_options patch are applied automatically.
  --user-options <user-options>
                          User extra options.
                          Supported fields: 'sdk_frameworks', 'sdk_dylibs', 'weak_sdk_frameworks', 'vendored_libraries', 'vendored_frameworks', 'vendored_xcframeworks', 'testonly', 'link_dynamic'.
                          Supported operators: '+=' (append), '-=' (delete), ':=' (replace).
                          Example:
                          'SomePod.sdk_dylibs += something,something'
                          'SomePod.testonly := true'
                          Platform specific:
                          'SomePod.platform_ios.sdk_dylibs += something,something'
  --deps-prefix <deps-prefix>
                          Dependencies prefix (default: //Pods)
  --pods-root <pods-root> Pods root relative to workspace. Used for headers search paths (default: Pods)
  --no-concurrency        Disable concurrency.
  -f, --frameworks        Packaging pods in dynamic frameworks if possible (same as `use_frameworks!`)
  --log-level <log-level> Log level (debug|info|warning|error|none) (default: info)
  -h, --help              Show help information.
```

### 🤔 History and motivation
There are two existing wonderful alternatives to this project: [cocoapods-bazel](https://github.com/bazel-ios/cocoapods-bazel) and [PodToBUILD](https://github.com/pinterest/PodToBUILD).

`cocoapods-bazel` generates BUILD files based on targets from `Pods.xcodeproj`.  
As a result of this, we will have some aggregated targets needed for Xcode but redundant for Bazel.  
These targets cause issues with resources and module name resolving.  
For example, currently, it's not working out of the box for a custom Firebase setup.

`PodToBUILD`'s main idea is to generate BUILD files directly from .podspec info and **it's great!**  
Unfortunately, out of the box, it cannot resolve the whole dependency tree with private pods as Cocoapods do.  
We can solve it by letting Cocoapods do its work and vendorise pods after. (something like [this](https://github.com/pinterest/PodToBUILD/pull/216/files))  
Another problem is "mixed code" (Swift + Objective-C). It's still [`in development`](https://github.com/pinterest/PodToBUILD#does-it-work-with-swift), so you cannot resolve it with reasonable effort.  
Meanwhile, [`rules_ios`](https://github.com/bazel-ios/rules_ios) already supports it.

`BazelPods` uses best of all worlds.  
Let Cocoapods download, resolve and setup everything for us. After that, BazelPods will generate `BUILD` files from .podspecs with only needed subspecs with rules from [`rules_ios`](https://github.com/bazel-ios/rules_ios). Written in Swift, so it will do it really fast.

## Contributing and issues
`make xcodeproj`
Just contribute and report your issues 

## Credits 
- [`PodToBUILD`](https://github.com/pinterest/PodToBUILD)
- [`rules_ios`](https://github.com/bazel-ios/rules_ios)
- [`cocoapods-bazel`](https://github.com/bazel-ios/cocoapods-bazel)
- [`xcodeproj2bazel`](https://github.com/WeijunDeng/xcodeproj2bazel)  
###### Powered by [sergeykhliustin](https://github.com/sergeykhliustin)
