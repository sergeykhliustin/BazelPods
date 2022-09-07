//
//  XCFrameworkProcessor.swift
//  BazelPods
//
//  Created by Sergey Khliustin on 05.09.2022.
//

import Foundation

struct XCFramework: StarlarkConvertible {
    private let name: String
    private let input: InputData

    private struct InputData: Codable {
        struct Library: Codable {
            enum Linkage: String, Codable {
                case dynamic
                case `static`
            }
            var LibraryIdentifier: String = ""
            var LibraryPath: String = ""
            var SupportedArchitectures: [String] = []
            var SupportedPlatform: String = ""
            var SupportedPlatformVariant: String?

            var path: String? = ""
            var linkage: Linkage? = .dynamic
        }
        var AvailableLibraries: [Library] = []
    }

    init?(xcframework: String, options: BuildOptions) {
        guard xcframework.hasSuffix(".xcframework") else { return nil }
        do {
            let frameworkURL = URL(fileURLWithPath: xcframework,
                                   relativeTo: URL(fileURLWithPath: options.podTargetAbsoluteRoot))
            name = frameworkURL.deletingPathExtension().lastPathComponent
            let infoPlistURL = frameworkURL.appendingPathComponent("Info.plist")
            let data = try Data(contentsOf: infoPlistURL)
            var input = try PropertyListDecoder().decode(InputData.self, from: data)
            input.AvailableLibraries = input.AvailableLibraries.map({
                var lib = $0
                lib.path = xcframework.appendingPath($0.LibraryIdentifier).appendingPath($0.LibraryPath)
                lib.linkage = $0.LibraryPath.hasSuffix("framework") ? .dynamic : .static
                return lib
            })
            self.input = input
        } catch {
            print("Unable to process \(xcframework): \(error)")
            return nil
        }
    }
    /// Wrap dynamic framework into xcframework.
    /// Assume that framework can be either device + simulator (x86_64 + arm*) or only for device (arm*).
    init?(dynamicFramework framework: String, options: BuildOptions) {
        guard framework.hasSuffix(".framework") else { return nil }
        let archs = frameworkArchs(framework, options: options)
        guard !archs.isEmpty else { return nil }

        let frameworkURL = URL(fileURLWithPath: framework,
                               relativeTo: URL(fileURLWithPath: options.podTargetAbsoluteRoot))
        name = frameworkURL.deletingPathExtension().lastPathComponent
        var libraries: [InputData.Library] = []
        let deviceArchs = archs.filter({ $0 != "x86_64" }).sorted()
        libraries.append(InputData.Library(LibraryIdentifier: "ios-\(deviceArchs.joined(separator: "_"))",
                                           LibraryPath: framework,
                                           SupportedArchitectures: deviceArchs,
                                           SupportedPlatform: "ios",
                                           SupportedPlatformVariant: nil,
                                           path: framework))

        // We will create slice with static linkage if framework is not build for simulator since it's only way to pass bazel slice strip
        libraries.append(InputData.Library(LibraryIdentifier: "ios-x86_64-simulator",
                                           LibraryPath: framework,
                                           SupportedArchitectures: ["x86_64"],
                                           SupportedPlatform: "ios",
                                           SupportedPlatformVariant: "simulator",
                                           path: framework,
                                           linkage: archs.contains("x86_64") ? .dynamic : .static)) // <- Dirty hack here

        input = InputData(AvailableLibraries: libraries)
    }

    func toStarlark() -> StarlarkNode {
        let slices = input.AvailableLibraries.map({
            return [
                "identifier": $0.LibraryIdentifier.toStarlark(),
                "platform": $0.SupportedPlatform.toStarlark(),
                "platform_variant": $0.SupportedPlatformVariant.toStarlark(),
                "supported_archs": $0.SupportedArchitectures.toStarlark(),
                "path": $0.path.toStarlark(),
                "build_type": [
                    "linkage": $0.linkage?.rawValue ?? "",
                    "packaging": $0.LibraryPath.hasSuffix("framework") ? "framework" : "library"
                ].toStarlark()
            ]
        })
        return [
            "name": name.toStarlark(),
            "slices": slices.toStarlark()
        ].toStarlark()
    }
}
