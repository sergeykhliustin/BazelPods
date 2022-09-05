# [![bazel-icon](https://user-images.githubusercontent.com/51409210/188334195-d558f4b3-cafb-4501-8dc7-ed4771508a09.svg)](https://bazel.build/) + [![favicon](https://user-images.githubusercontent.com/51409210/188334178-cbb1e7c9-aee3-4802-bcd2-81292d47d02d.png)](https://cocoapods.org/) BazelPods 

One more way to build CocoaPods with Bazel. It generates Bazel's `BUILD` files for pods using awesome [rules_ios](https://github.com/bazel-ios/rules_ios).  
Core idea, Podspec parser, Skylark compiler are forked from Pinterest's [PodToBUILD](https://github.com/pinterest/PodToBUILD)

#

### 🤔 Motivation
There are two existing wonderful alternatives to this project: [cocoapods-bazel](https://github.com/bazel-ios/cocoapods-bazel) and [PodToBUILD](https://github.com/pinterest/PodToBUILD).

`cocoapods-bazel` generates BUILD files based on targets from `Pods.xcodeproj`.  
As a result of this, we will have some aggregated targets needed for Xcode but redundant for Bazel.  
These targets cause issues with resources and module name resolving.  
For example, currently, it not working out of the box for a custom Firebase setup.

`PodToBUILD`'s main idea is to generate BUILD files directly from .podspec info and **it's great!**  
Unfortunately, out of the box, it cannot resolve the whole dependency tree with private pods as Cocoapods do.  
We can solve it by letting Cocoapods do its work and vendorise pods after. (something like [this](https://github.com/pinterest/PodToBUILD/pull/216/files))  
Another problem is "mixed code" (Swift + Objective-C). It's still [`in development`](https://github.com/pinterest/PodToBUILD#does-it-work-with-swift), so you cannot resolve it with reasonable effort.  
Meanwhile, [`rules_ios`](https://github.com/bazel-ios/rules_ios) already supports it.

`BazelPods` uses best of all worlds.  
Let Cocoapods download, resolve and setup everything for us. After that, it will generate `BUILD` files from .podspecs with only needed subspecs with rules from [`rules_ios`](https://github.com/bazel-ios/rules_ios). Written in Swift, so it will do it really fast.

### ⚙️ Features

- Platforms
  - [x] iOS
  - [ ] macOS (soon)
  - [ ] watchOS (soon)
  - [ ] tvOS (soon)
- Linking
  - [x] Static
  - [ ] Dynamic `use_frameworks!` (soon)
  - [ ] Mixed (soon)
- Archs:
  - [x] x86_64 (simulator)
  - [ ] arm64 (currently there are some issues with detecting vendored frameworks architecture, so coming soon)
- Pods: 
  - [x] Almost everything from top pods (vendored frameworks/xcframeworks/libraries, resources/bundles, xcconfigs)
  - [x] Nested subspecs (possibly works, but not tested yet)
  - [ ] Local pods with custom paths (currently supports only pods located at the root of your repo)


### 🎸 Let's rock
Don't forget to setup [`rules_ios`](https://github.com/bazel-ios/rules_ios) first.

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
  development_pods = installer.sandbox.development_pods.keys
  mapped_pods = installer.analysis_result.specifications.reduce({}) { |result, spec|
    result[spec.name] = {
      name: spec.name,
      podspec: "#{spec.defined_in_file.to_s}",
      development: (development_pods.include? spec.name)
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
USAGE: Generator <pods-json> --src <src> [--min-ios <min-ios>] [--concurrent] [--print-output] [--debug] [--add-podspec]

ARGUMENTS:
  <pods-json>             Pods.json

OPTIONS:
  --src <src>             Sources root
  --min-ios <min-ios>     Minimum iOS version if not listed in podspec (default: 13.0)
  -c, --concurrent        Concurrent mode for generating files faster
  -p, --print-output      Print BUILD files contents to terminal output
  -d, --debug             Debug mode. Files will not be written
  -a, --add-podspec       Will add podspec.json to the pod directory. Just for debugging purposes.
  -h, --help              Show help information.
```
### Compiler
```
OVERVIEW: Compiles podspec.json to BUILD file

USAGE: Compiler <podspec-json> [--src <src>] [--subspecs <subspecs> ...] [--min-ios <min-ios>]

ARGUMENTS:
  <podspec-json>          podspec.json

OPTIONS:
  --src <src>             Sources root
  --subspecs <subspecs>   Subspecs list
  --min-ios <min-ios>     Minimum iOS version if not listed in podspec (default: 13.0)
  -h, --help              Show help information.
```
## Contributing and issues
Just contribute and report your issues 
