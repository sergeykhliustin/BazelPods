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

    convenience init(name: String, resourceBundle: String, info: BaseInfoAnalyzerResult) {
        let data = PlistData(
            CFBundleIdentifier: "org.cocoapods.\(resourceBundle)",
            CFBundleName: resourceBundle,
            CFBundleShortVersionString: info.version,
            CFBundlePackageType: .BNDL,
            MinimumOSVersion: info.platforms.first?.value,
            CFBundleSupportedPlatforms: [.iPhoneSimulator, .iPhoneOS], // TODO: Support platforms
            UIDeviceFamily: [1, 2] // TODO: Investigate
        )
        self.init(name: name, data: data)
    }

    convenience init(framework info: BaseInfoAnalyzerResult) {
        let data = PlistData(
            CFBundleIdentifier: "org.cocoapods.\(info.name)",
            CFBundleName: info.name,
            CFBundleShortVersionString: info.version,
            CFBundlePackageType: .FMWK,
            MinimumOSVersion: info.platforms.first?.value,
            CFBundleSupportedPlatforms: [.iPhoneSimulator, .iPhoneOS], // TODO: Support platforms
            UIDeviceFamily: [1, 2] // TODO: Investigate
        )
        self.init(name: info.name + "_InfoPlist", data: data)
    }
}
