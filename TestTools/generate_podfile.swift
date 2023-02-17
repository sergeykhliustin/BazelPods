import Foundation

let args = CommandLine.arguments
if args.count != 3 {
    print("\(args.first ?? "command") [Pods.json] [template]")
    exit(0)
}

let podsJsonFile = args[1]
let templateFile = args[2]

let data = try NSData(contentsOfFile: podsJsonFile) as Data
let object = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: [String: String]]

var podfile = try String(contentsOf: URL(fileURLWithPath: templateFile), encoding: .utf8)

for platform in object.keys {
    let platformPods = object[platform]!
    let keys = platformPods.keys.sorted()
    let pods = keys.map({
        if let version = platformPods[$0], !version.isEmpty {
            return "  pod '\($0)', '\(version)'"
        } else {
            return "  pod '\($0)'"
        }
    }).joined(separator: "\n")

    podfile = podfile.replacingOccurrences(of: "[[\(platform.uppercased())_PODS]]", with: pods)
}
print(podfile)
