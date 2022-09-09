//
//  Arch.swift
//  BazelPods
//
//  Created by Sergey Khliustin on 08.09.2022.
//

import Foundation
// LC_VERSION_MIN_IPHONEOS
// OSX_TOOLS_NON_DEVICE_ARCHS = [
//    "darwin_x86_64",
//    "darwin_arm64",
//    "darwin_arm64e",
//    "ios_i386",
//    "ios_x86_64",
//    "ios_sim_arm64",
//    "watchos_arm64",
//    "watchos_i386",
//    "watchos_x86_64",
//    "tvos_x86_64",
//    "tvos_sim_arm64",
// ]
//
// OSX_TOOLS_ARCHS = [
//    "ios_armv7",
//    "ios_arm64",
//    "ios_arm64e",
//    "watchos_armv7k",
//    "watchos_arm64_32",
//    "tvos_arm64",
// ]
enum Arch: String, CaseIterable {
    // Device
    case ios_armv7
    case ios_arm64
    case ios_arm64e

    // Simulator
    case ios_sim_arm64
    case ios_i386
    case ios_x86_64

    static func archs(for framework: String, options: BuildOptions) -> [Arch] {
        let path = frameworkExecutablePath(framework, options: options)
        let archs = frameworkArchs(framework, options: options).map({
            // TODO: Implement resolver
            if $0 == "arm64" {
                let output = SystemShellContext()
                    .shellOut("otool -l -arch arm64 \(path) | grep -m 1 'LC_VERSION_MIN_'")
                    .standardOutputAsString
                if !output.contains("IPHONEOS") {
                    return "sim_arm64"
                } else {
                    return $0
                }
            }
            return $0
        } as (String) -> String)

        return archs.compactMap({ Self.init(rawValue: "ios_" + $0) })
    }
}
