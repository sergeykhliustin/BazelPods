import Foundation

let args = CommandLine.arguments
if args.count != 3 {
    print("\(args.first ?? "command") [Pods.json] [template]")
    exit(0)
}

let podsJsonFile = args[1]
let templateFile = args[2]

let data = try NSData(contentsOfFile: podsJsonFile) as Data
let object = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]

var podfile = try String(contentsOf: URL(fileURLWithPath: templateFile), encoding: .utf8)

for platform in object.keys {
    let platformPods = object[platform] as! [String: Any]
    let keys = platformPods.keys.sorted()
    let pods = keys.map({
        let podInfo = platformPods[$0] as! [String: Any]
        var result = ["  pod '\($0)'"]
        let version = podInfo["version"] as! String
        result.append("'\(version)'")
        if let testspecs = podInfo["testspecs"] as? [String] {
            result.append(":testspecs => [\(testspecs.map({ "\"\($0)\"" }).joined(separator: ", "))]")
        }
        if let appspecs = podInfo["appspecs"] as? [String] {
            result.append(":appspecs => [\(appspecs.map({ "\"\($0)\"" }).joined(separator: ", "))]")
        }
        return result.joined(separator: ", ")
    }).joined(separator: "\n")

    podfile = podfile.replacingOccurrences(of: "[[\(platform.uppercased())_PODS]]", with: pods)
}
print(podfile)
