//
//  InfoPlist.swift
//  BazelPods
//
//  Created by Sergey Khliustin on 02.09.2022.
//

import Foundation

final class InfoPlist<S: BaseInfoRepresentable>: GenRule {
    enum PackageType: String, Codable {
        case bundle = "BNDL"
        case framework = "FMWK"
        case application = "APPL"
    }
    enum Platforms: String, Codable {
        case iPhoneSimulator
        case iPhoneOS
    }
    enum Keys: String {
        case CFBundleInfoDictionaryVersion
        case CFBundleSignature
        case CFBundleVersion
        case NSPrincipalClass
        case CFBundleIdentifier
        case CFBundleName
        case CFBundleShortVersionString
        case CFBundlePackageType
        case MinimumOSVersion
        case CFBundleSupportedPlatforms
        case UIDeviceFamily
        case UILaunchStoryboardName
        case UISupportedInterfaceOrientations
        case UISupportedInterfaceOrientationsIpad = "UISupportedInterfaceOrientations~ipad"
        case NSAppTransportSecurity
    }
    static var defaultData: [String: Any] {
        return [
            Keys.CFBundleInfoDictionaryVersion.rawValue: "6.0",
            Keys.CFBundleSignature.rawValue: "????",
            Keys.CFBundleVersion.rawValue: "1"
        ]
    }

    init(name: String, data: [String: Any]) {
        var xml: String = ""
        do {
            let plistData = try PropertyListSerialization.data(fromPropertyList: data, format: .xml, options: 0)
            if let string = String(data: plistData, encoding: .utf8) {
                xml = string
            }
        } catch {
            log_error("encode Info.plist: \(error)")
        }
        let cmd = "cat <<EOF > $@\n\(xml)\nEOF"
        super.init(name: name, outs: ["\(name).plist"], cmd: cmd)
    }

    convenience init(name: String, resourceBundle: String, info: BaseAnalyzer<S>.Result) {
        let data: [String: Any] = [
            Keys.CFBundleIdentifier.rawValue: "org.cocoapods.\(resourceBundle)",
            Keys.CFBundleName.rawValue: resourceBundle,
            Keys.CFBundleShortVersionString.rawValue: info.version,
            Keys.CFBundlePackageType.rawValue: PackageType.bundle.rawValue,
            Keys.MinimumOSVersion.rawValue: (info.platforms.first?.value ?? ""),
            Keys.CFBundleSupportedPlatforms.rawValue: [Platforms.iPhoneSimulator, Platforms.iPhoneOS].map({ $0.rawValue }), // TODO: Support platforms
            Keys.UIDeviceFamily.rawValue: [1, 2] // TODO: Investigate
        ]
        let merged = Self.defaultData.merging(data, uniquingKeysWith: { _, new in new })
        self.init(name: name, data: merged)
    }

    convenience init(name: String, framework info: BaseAnalyzer<S>.Result) {
        let data: [String: Any] = [
            Keys.CFBundleIdentifier.rawValue: "org.cocoapods.\(info.name)",
            Keys.CFBundleName.rawValue: info.name,
            Keys.CFBundleShortVersionString.rawValue: info.version,
            Keys.CFBundlePackageType.rawValue: PackageType.framework.rawValue,
            Keys.MinimumOSVersion.rawValue: (info.platforms.first?.value ?? ""),
            Keys.CFBundleSupportedPlatforms.rawValue: [Platforms.iPhoneSimulator, Platforms.iPhoneOS].map({ $0.rawValue }), // TODO: Support platforms
            Keys.UIDeviceFamily.rawValue: [1, 2] // TODO: Investigate
        ]
        let merged = Self.defaultData.merging(data, uniquingKeysWith: { _, new in new })
        self.init(name: name, data: merged)
    }

    convenience init(name: String, application info: BaseAnalyzer<S>.Result, spec: S) where S: InfoPlistRepresentable {
        var data = Self.defaultData
        data[Keys.CFBundlePackageType.rawValue] = PackageType.application.rawValue
        data[Keys.CFBundleShortVersionString.rawValue] = info.version
        if let infoPlist = spec.infoPlist {
            data = data.merging(infoPlist, uniquingKeysWith: { _, new in new })
        }
        self.init(name: name, data: data)
    }

    convenience init(name: String, test info: BaseAnalyzer<S>.Result, spec: S) where S: InfoPlistRepresentable {
        var data = Self.defaultData
        data[Keys.CFBundlePackageType.rawValue] = PackageType.bundle.rawValue
        data[Keys.CFBundleShortVersionString.rawValue] = info.version
        if let infoPlist = spec.infoPlist {
            data = data.merging(infoPlist, uniquingKeysWith: { _, new in new })
        }
        self.init(name: name, data: data)
    }

    convenience init(name: String, appHost info: BaseAnalyzer<S>.Result) where S: TestSpecRepresentable  {
        var data = Self.defaultData
        data[Keys.CFBundlePackageType.rawValue] = PackageType.application.rawValue
        data[Keys.UILaunchStoryboardName.rawValue] = "LaunchScreen"
        data[Keys.UISupportedInterfaceOrientations.rawValue] = [
            "UIInterfaceOrientationPortrait",
            "UIInterfaceOrientationLandscapeLeft",
            "UIInterfaceOrientationLandscapeRight"
        ]
        data[Keys.UISupportedInterfaceOrientationsIpad.rawValue] = [
            "UIInterfaceOrientationPortrait",
            "UIInterfaceOrientationPortraitUpsideDown",
            "UIInterfaceOrientationLandscapeLeft",
            "UIInterfaceOrientationLandscapeRight"
        ]
        data[Keys.NSAppTransportSecurity.rawValue] = [
            "NSAllowsArbitraryLoads": true
        ]
        data[Keys.CFBundleShortVersionString.rawValue] = info.version
        self.init(name: name, data: data)
    }
}
