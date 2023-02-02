//
//  InfoPlist.swift
//  BazelPods
//
//  Created by Sergey Khliustin on 02.09.2022.
//

import Foundation

final class InfoPlist: GenRule {
    struct PlistData: Codable {
        enum PackageType: String, Codable {
            case BNDL
            case FMWK
        }
        enum Platforms: String, Codable {
            case iPhoneSimulator
            case iPhoneOS
        }

        var CFBundleInfoDictionaryVersion = "6.0"
        var CFBundleSignature = "????"
        var CFBundleVersion = "1"
        var NSPrincipalClass: String?
        let CFBundleIdentifier: String
        let CFBundleName: String
        let CFBundleShortVersionString: String
        let CFBundlePackageType: PackageType
        let MinimumOSVersion: String?
        let CFBundleSupportedPlatforms: [Platforms]
        let UIDeviceFamily: [Int]

    }

    init(name: String, data: PlistData) {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        var xml: String = ""
        do {
            let encoded = try encoder.encode(data)
            xml = String(data: encoded, encoding: .utf8) ?? ""
        } catch {
            log_error("encode Info.plist: \(error)")
        }
        let cmd = "cat <<EOF > $@\n\(xml)\nEOF"
        super.init(name: name, outs: ["\(name).plist"], cmd: cmd)
    }

    convenience init(bundle: AppleResourceBundle, spec: PodSpec, options: BuildOptions) {
        let data = PlistData(
            CFBundleIdentifier: "org.cocoapods.\(bundle.bundleName)",
            CFBundleName: bundle.bundleName,
            CFBundleShortVersionString: spec.version ?? "1.0",
            CFBundlePackageType: .BNDL,
            MinimumOSVersion: options.resolvePlatforms(spec.platforms)["ios"],
            CFBundleSupportedPlatforms: [.iPhoneSimulator, .iPhoneOS],
            UIDeviceFamily: [1, 2]
        )
        self.init(name: bundle.name + "_InfoPlist", data: data)
    }

    convenience init(framework: AppleFramework, spec: PodSpec, options: BuildOptions) {
        let data = PlistData(
            CFBundleIdentifier: "org.cocoapods.\(framework.name)",
            CFBundleName: framework.name,
            CFBundleShortVersionString: spec.version ?? "1.0",
            CFBundlePackageType: .FMWK,
            MinimumOSVersion: options.resolvePlatforms(spec.platforms)["ios"],
            CFBundleSupportedPlatforms: [.iPhoneSimulator, .iPhoneOS],
            UIDeviceFamily: [1, 2]
        )
        self.init(name: framework.name + "_InfoPlist", data: data)
    }
}
