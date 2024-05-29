//
//  XCConfigParser.swift
//  PodToBUILD
//
//  Created by Sergey Khliustin on 02.09.2022.
//

import Foundation

final class XCConfigParser<S: XCConfigRepresentable> {
    private(set) var xcconfig: [String: StarlarkNode] = [:]
    private(set) var swiftCopts: [String] = []
    private(set) var objcCopts: [String] = []
    private(set) var linkOpts: [String] = []
    private(set) var objcDefines: [String] = []
    private(set) var ccCopts: [String] = []
    private let transformers: [String: XCConfigSettingTransformer]
    private let options: BuildOptions
    private let defaultTransformers: [XCConfigSettingTransformer] = [
        HeaderSearchPathTransformer(),
        UserHeaderSearchPathTransformer(),
        ApplicationExtensionAPIOnlyTransformer(),
        CLANG_CXX_LANGUAGE_STANDARD_Transformer(),
        LinkOptsListTransformer("OTHER_LDFLAGS"),
        ObjCOptsListTransformer("OTHER_CFLAGS"),
        ObjCOptsListTransformer("OTHER_CPLUSPLUSFLAGS"),
        ObjcDefinesListTransformer("GCC_PREPROCESSOR_DEFINITIONS")
    ]

    convenience init(spec: S, subspecs: [S] = [], platform: Platform, options: BuildOptions) {
        let xcconfig = spec.collectAttribute(with: subspecs, keyPath: \.xcconfig).platform(platform) ?? [:]
        let podTargetXcconfig = spec.collectAttribute(with: subspecs, keyPath: \.podTargetXcconfig).platform(platform) ?? [:]
        let userTargetXcconfig = spec.collectAttribute(with: subspecs, keyPath: \.userTargetXcconfig).platform(platform) ?? [:]
        let mergedConfig = xcconfig
            .merging(podTargetXcconfig, uniquingKeysWith: { $1 })
            .merging(userTargetXcconfig, uniquingKeysWith: { $1 })

        let compilerFlags = spec.collectAttribute(with: subspecs, keyPath: \.compilerFlags).platform(platform) ?? []

        self.init(mergedConfig, compilerFlags: compilerFlags, options: options)
    }

    private init(_ config: [String: String], compilerFlags: [String], options: BuildOptions) {
        self.options = options

        self.transformers = defaultTransformers.reduce([String: XCConfigSettingTransformer](), { result, transformer in
            var result = result
            result[transformer.key] = transformer
            return result
        })

        let config = replaceEnvVars(in: config)

        for key in config.keys.sorted() {
            guard !XCSpecs.forceIgnore.contains(key) else { continue }
            let node: StarlarkNode?
            let value = replacePodsEnvVars(config[key]!, options: options, absolutePath: false)
            switch XCSpecs.allSettingsKeyType[key] {
            case .boolean, .string, .enumeration:
                node = .string(value)
            case .stringList:
                node = .list(xcconfigSettingToList(value).map({ $0.toStarlark() }))
            case .path:
                node = .string(value)
            case .pathList:
                node = .list(xcconfigSettingToList(value).map({ $0.toStarlark() }))
            case .none:
                node = nil
            }
            var handled = false
            if let node = node, !XCSpecs.xcconfigIgnore.contains(key) {
                xcconfig[key] = node
                handled = true
            }
            if let transformer = self.transformers[key] {
                swiftCopts += (transformer as? SwiftCoptsProvider)?.swiftCopts(value) ?? []
                objcCopts += (transformer as? ObjcCoptsProvider)?.objcCopts(value) ?? []
                linkOpts += (transformer as? LinkOptsProvider)?.linkOpts(value) ?? []
                objcDefines += (transformer as? ObjcDefinesProvider)?.objcDefines(value) ?? []
                ccCopts += (transformer as? CCCOptsProvider)?.cccOpts(value) ?? []
                handled = true
            }
            if !handled {
                log_debug("unhandled xcconfig \(key)")
            }
        }

        for flag in compilerFlags {
            let normalized = replacePodsEnvVars(flag, options: options, absolutePath: false)
            if !normalized.isEmpty {
                ccCopts.append(normalized)
            }
        }
    }

    private func replaceEnvVars(in config: [String: String]) -> [String: String] {
        var config = config.mapValues({
            replacePodsEnvVars($0, options: options, absolutePath: false)
        })
        while config.contains(where: { !$0.value.envVariables.isEmpty }) {
            config = config.reduce(into: config, { result, value in
                let key = value.key
                var value = value.value
                let envVars = value.envVariables
                for envKey in envVars {
                    if let envValue = result[envKey] {
                        value = value.replacingOccurrences(of: "$(\(envKey))", with: envValue)
                        value = value.replacingOccurrences(of: "${\(envKey)}", with: envValue)
                    } else {
                        value = value.replacingOccurrences(of: "$(\(envKey))", with: "")
                        value = value.replacingOccurrences(of: "${\(envKey)}", with: "")
                    }
                }
                result[key] = value
            })
        }
        return config
    }
}

private extension String {
    static let ignore = [
        "SDKROOT"
    ]
    var envVariables: [String] {
        var result = [String]()
        let pattern = #"\$\(([^$)]+)\)|\$\{([^$}]+)\}"#
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))

            for match in matches {
                let nsRange = match.range(at: 1)
                if let range = Range(nsRange, in: self) {
                    let innerVarName = String(self[range])
                    if !Self.ignore.contains(innerVarName) {
                        result.append(innerVarName)
                    }
                }
            }
        } catch {
            log_debug("Error extracting env variables: \(error)")
        }
        return result
    }
}
