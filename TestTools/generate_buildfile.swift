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
let object = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: String]
let keys = object.keys.sorted()

let pods = keys.map({
    "  pod '\($0)', '\(object[$0]!)'"
}).joined(separator: "\n")

let deps = keys.map({
    "      \"\(dep_prefix)/Pods/\($0)\""
}).joined(separator: ",\n")

let buildfile = try String(contentsOf: URL(fileURLWithPath: templateFile), encoding: .utf8).replacingOccurrences(of: "[[DEPS]]", with: deps)

print(buildfile)
