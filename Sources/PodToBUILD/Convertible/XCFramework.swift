//
//  XCFrameworkProcessor.swift
//  BazelPods
//
//  Created by Sergey Khliustin on 05.09.2022.
//

import Foundation

struct XCFramework: StarlarkConvertible {
    private let name: String
    private let xcframework: String
    private let input: InputData
    private let options: BuildOptions

    private struct InputData: Codable {
        struct Library: Codable {
            var LibraryIdentifier: String = ""
            var LibraryPath: String = ""
            var SupportedArchitectures: [String] = []
            var SupportedPlatform: String = ""
            var SupportedPlatformVariant: String?
        }
        var AvailableLibraries: [Library] = []
    }
    init?(_ xcframework: String, options: BuildOptions) {
        guard xcframework.hasSuffix("xcframework") else { return nil }
        do {
            self.options = options
            self.xcframework = xcframework
            let frameworkURL = URL(fileURLWithPath: xcframework,
                                   relativeTo: URL(fileURLWithPath: options.podTargetAbsoluteRoot))
            name = frameworkURL.deletingPathExtension().lastPathComponent
            let infoPlistURL = frameworkURL.appendingPathComponent("Info.plist")
            let data = try Data(contentsOf: infoPlistURL)
            input = try PropertyListDecoder().decode(InputData.self, from: data)
        } catch {
            print("Unable to process \(xcframework): \(error)")
            return nil
        }
    }

    func toStarlark() -> StarlarkNode {
        let slices = input.AvailableLibraries.map({
            return [
                "identifier": $0.LibraryIdentifier.toStarlark(),
                "platform": $0.SupportedPlatform.toStarlark(),
                "platform_variant": $0.SupportedPlatformVariant.toStarlark(),
                "supported_archs": $0.SupportedArchitectures.toStarlark(),
                "path": xcframework.appendingPath($0.LibraryIdentifier).appendingPath($0.LibraryPath).toStarlark(),
                "build_type": [
                    "linkage": $0.LibraryPath.hasSuffix("framework") ? "dynamic" : "static",
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
