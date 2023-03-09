//
//  XCConfigParser.swift
//  PodToBUILD
//
//  Created by Sergey Khliustin on 02.09.2022.
//

import Foundation

final class XCConfigParser {
    private(set) var xcconfig: [String: StarlarkNode] = [:]
    private(set) var swiftCopts: [String] = []
    private(set) var objcCopts: [String] = []
    private(set) var linkOpts: [String] = []
    private let transformers: [String: XCConfigSettingTransformer]
    private static let defaultTransformers: [XCConfigSettingTransformer] = [
        HeaderSearchPathTransformer(),
        ApplicationExtensionAPIOnlyTransformer(),
        LinkOptsListTransformer("OTHER_LDFLAGS"),
        ObjCOptsListTransformer("OTHER_CFLAGS"),
        ObjCOptsListTransformer("OTHER_CPLUSPLUSFLAGS")
    ]

    convenience init(spec: PodSpec, subspecs: [PodSpec] = [], options: BuildOptions) {
        let resolved =
        spec.collectAttribute(with: subspecs, keyPath: \.xcconfig) <>
        spec.collectAttribute(with: subspecs, keyPath: \.podTargetXcconfig) <>
        spec.collectAttribute(with: subspecs, keyPath: \.userTargetXcconfig)

        self.init(resolved.multi.ios ?? [:], options: options)
    }

    init(_ config: [String: String],
         options: BuildOptions,
         transformers: [XCConfigSettingTransformer] = defaultTransformers) {

        self.transformers = transformers.reduce([String: XCConfigSettingTransformer](), { result, transformer in
            var result = result
            result[transformer.key] = transformer
            return result
        })

        for key in config.keys {
            guard !XCSpecs.forceIgnore.contains(key) else { continue }
            let node: StarlarkNode?
            let value = replacePodsEnvVars(config[key]!, options: options)
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
            if let node = node {
                xcconfig[key] = node
            } else if let transformer = self.transformers[key] {
                swiftCopts += (transformer as? SwiftCoptsProvider)?.swiftCopts(value) ?? []
                objcCopts += (transformer as? ObjcCoptsProvider)?.objcCopts(value) ?? []
                linkOpts += (transformer as? LinkOptsProvider)?.linkOpts(value) ?? []
            } else {
                log_debug("unhandled xcconfig \(key)")
            }
        }
    }
}
