#  BazelPods [![bazel-icon](https://user-images.githubusercontent.com/51409210/188334195-d558f4b3-cafb-4501-8dc7-ed4771508a09.svg)](https://bazel.build/) + [![favicon](https://user-images.githubusercontent.com/51409210/188334178-cbb1e7c9-aee3-4802-bcd2-81292d47d02d.png)](https://cocoapods.org/) 
![Snapshot tests status](https://github.com/sergeykhliustin/BazelPods/actions/workflows/snapshot_tests.yml/badge.svg?branch=main) ![Integration tests static status](https://github.com/sergeykhliustin/BazelPods/actions/workflows/integration_tests_static.yml/badge.svg?branch=main) ![Integration tests dynamic status](https://github.com/sergeykhliustin/BazelPods/actions/workflows/integration_tests_dynamic.yml/badge.svg?branch=main)

One more way to build CocoaPods with Bazel. It generates Bazel's `BUILD` files for pods using awesome [rules_ios](https://github.com/bazel-ios/rules_ios).  
Core idea, Podspec parser, Starlark compiler are forked from Pinterest's [PodToBUILD](https://github.com/pinterest/PodToBUILD)

#

### 🤔 Motivation
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
Let Cocoapods download, resolve and setup everything for us. After that, it will generate `BUILD` files from .podspecs with only needed subspecs with rules from [`rules_ios`](https://github.com/bazel-ios/rules_ios). Written in Swift, so it will do it really fast.

### ⚙️ Features

- Platforms and architectures
  - [x] iOS full support
    - [x] Simulator: arm64, x86_64
    - [x] Device: armv7, arm64, arm64e
  - [ ] macOS (soon)
  - [ ] watchOS (soon)
  - [ ] tvOS (soon)
- Linking
  - [x] Static
  - [x] Dynamic `use_frameworks!` (`--frameworks` option. also check `--extra-sdk` and `--user-options` if you facing missing sdk issues)
  - [ ] Mixed (?)
- Pods: 
  - [x] Autodetect vendored frameworks architectures and ignore unsupported
  - [x] Almost everything from top pods (vendored frameworks/xcframeworks/libraries, resources/bundles, xcconfigs)
  - [x] Local pods with custom paths
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
bazel run @bazel_pods//:Generator -- Pods/Pods.json --src $PWD
```
Now you can add first level dependencies to your app as `//Pods/<pod_name>`  
Enjoy :)

### Generator options
```
USAGE: Generator [<options>] --src <src>

OPTIONS:
  --src <src>             Sources root where Pods directory located (or renamed by podsRoot)
  --pods-json <pods-json> Pods.json (default: Pods/Pods.json)
  --platforms <platforms> Space separated platforms.
                          Valid values are: ios, osx, tvos, watchos.
                          Currently ignored, only 'ios' supported (default: ios)
  --min-ios <min-ios>     Minimum iOS version (default: 13.0)
  --deps-prefix <deps-prefix>
                          Dependencies prefix (default: //Pods)
  --pods-root <pods-root> Pods root relative to workspace. Used for headers search paths (default: Pods)
  -f, --frameworks        Packaging pods in dynamic frameworks if possible (same as `use_frameworks!`)
  -c, --concurrent        Concurrent mode for generating files faster
  --print-output          Print BUILD files contents to terminal output
  --dry-run               Dry run. Files will not be written
  -a, --add-podspec       Will add podspec.json to the pod directory. Just for debugging purposes.
  --color <color>         Logs color (auto|yes|no) (default: auto)
  --user-options <user-options>
                          User extra options.
                          Supported fields for '+=' (add): 'sdk_dylibs', 'sdk_frameworks', 'weak_sdk_frameworks', 'deps'.
                          Supported fields for '-=' (remove): 'sdk_dylibs', 'sdk_frameworks', 'weak_sdk_frameworks', 'deps'.
                          Supported fields for ':=' (override): 'testonly', 'link_dynamic'.
                          Example:
                          'SomePod.sdk_dylibs += something,something'
                          'SomePod.testonly := true'
  -h, --help              Show help information.
```
### Compiler
```
USAGE: Compiler --src <src> --podspec <podspec> [--subspecs <subspecs> ...] [--platforms <platforms> ...] [--min-ios <min-ios>] [--deps-prefix <deps-prefix>] [--pods-root <pods-root>] [--frameworks] [--user-options <user-options> ...]

OPTIONS:
  --src <src>             Sources root where Pods directory located (or renamed by podsRoot)
  --podspec <podspec>     podspec.json
  --subspecs <subspecs>   Subspecs list
  --platforms <platforms> Space separated platforms.
                          Valid values are: ios, osx, tvos, watchos.
                          Currently ignored, only 'ios' supported (default: ios)
  --min-ios <min-ios>     Minimum iOS version (default: 13.0)
  --deps-prefix <deps-prefix>
                          Dependencies prefix (default: //Pods)
  --pods-root <pods-root> Pods root relative to workspace. Used for headers search paths (default: Pods)
  -f, --frameworks        Packaging pods in dynamic frameworks if possible (same as `use_frameworks!`)
  --user-options <user-options>
                          User extra options.
                          Supported fields for '+=' (add): 'sdk_dylibs', 'sdk_frameworks', 'weak_sdk_frameworks', 'deps'.
                          Supported fields for '-=' (remove): 'sdk_dylibs', 'sdk_frameworks', 'weak_sdk_frameworks', 'deps'.
                          Supported fields for ':=' (override): 'testonly', 'link_dynamic'.
                          Example:
                          'SomePod.sdk_dylibs += something,something'
                          'SomePod.testonly := true'
  -h, --help              Show help information.
```
## Contributing and issues
`make xcodeproj`
Just contribute and report your issues 
## Credits 
- [`PodToBUILD`](https://github.com/pinterest/PodToBUILD)
- [`rules_ios`](https://github.com/bazel-ios/rules_ios)
- [`cocoapods-bazel`](https://github.com/bazel-ios/cocoapods-bazel)
- [`xcodeproj2bazel`](https://github.com/WeijunDeng/xcodeproj2bazel)
