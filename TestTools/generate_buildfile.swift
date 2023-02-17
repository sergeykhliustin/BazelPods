import Foundation

let args = CommandLine.arguments
if args.count != 4 {
    print("\(args.first ?? "command") [Pods.json] [template] [dep_prefix]")
    exit(0)
}

let podsJsonFile = args[1]
let templateFile = args[2]
let dep_prefix = args[3]

let data = try NSData(contentsOfFile: podsJsonFile) as Data
let object = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: [String: String]]

var buildfile = try String(contentsOf: URL(fileURLWithPath: templateFile), encoding: .utf8)

for platform in object.keys {
    let platformPods = object[platform]!
    let keys = platformPods.keys.sorted()
    let deps = keys.map({
        "      \"\(dep_prefix)/Pods/\($0):\($0)_\(platform)\""
    }).joined(separator: ",\n")

    buildfile = buildfile.replacingOccurrences(of: "[[\(platform.uppercased())_DEPS]]", with: deps)
}

print(buildfile)
