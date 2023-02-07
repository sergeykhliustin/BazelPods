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
        guard xcframework.pathExtention == "xcframework" else { return nil }
        do {
            let frameworkURL = URL(fileURLWithPath: xcframework,
                                   relativeTo: URL(fileURLWithPath: options.podTargetAbsoluteRoot))
            name = frameworkURL.deletingPathExtension().lastPathComponent
            let infoPlistURL = frameworkURL.appendingPathComponent("Info.plist")
            let data = try Data(contentsOf: infoPlistURL)
            var input = try PropertyListDecoder().decode(InputData.self, from: data)
            input.AvailableLibraries = input.AvailableLibraries.map({
                var lib = $0
                let path = xcframework.appendingPath($0.LibraryIdentifier).appendingPath($0.LibraryPath)
                lib.path = path
                if $0.LibraryPath.hasSuffix("framework") {
                    lib.linkage = isDynamicFramework(path, options: options) ? .dynamic : .static
                } else {
                    lib.linkage = .static
                }
                if lib.SupportedPlatformVariant == "simulator" && lib.SupportedPlatform == "ios" {
                    lib.SupportedArchitectures = lib.SupportedArchitectures.map({
                        $0.replacingOccurrences(of: "arm64", with: "sim_arm64")
                    })
                }
                return lib
            })
            .sorted(by: { $0.LibraryIdentifier < $1.LibraryIdentifier })
            self.input = input
        } catch {
            log_error("Unable to process \(xcframework): \(error)")
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
