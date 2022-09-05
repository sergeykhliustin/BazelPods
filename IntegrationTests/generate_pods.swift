#! /bin/sh
import Foundation
let data = try NSData(contentsOfFile: "TopPods.json") as Data
let object = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: String]
let keys = object.keys.sorted()

let pods = keys.map({
    "  pod '\($0)', '\(object[$0]!)'"
}).joined(separator: "\n")

let podfile = try String(contentsOf: URL(fileURLWithPath: "Podfile_template"), encoding: .utf8).replacingOccurrences(of: "[[PODS]]", with: pods)
try podfile.data(using: .utf8)?.write(to: URL(fileURLWithPath: "Podfile"))

let deps = keys.map({
    "      \"//IntegrationTests/Pods/\($0)\""
}).joined(separator: ",\n")

let buildfile = try String(contentsOf: URL(fileURLWithPath: "BUILD_template"), encoding: .utf8).replacingOccurrences(of: "[[DEPS]]", with: deps)
try buildfile.data(using: .utf8)?.write(to: URL(fileURLWithPath: "BUILD.bazel"))
