//
//  SourcesAnalyzer.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 03.02.2023.
//

import Foundation

public struct SourcesAnalyzerResult {
    enum SourcesType {
        case empty
        case headersOnly
        case objcOnly
        case swiftOnly
        case mixed
    }
    let sourceFiles: GlobNode
    let publicHeaders: GlobNode
    let privateHeaders: GlobNode
    let sourcesType: SourcesType
    let linkDynamic: Bool
}

public struct SourcesAnalyzer {
    private let platform: Platform
    private let spec: PodSpec
    private let subspecs: [PodSpec]
    private let options: BuildOptions

    public init(platform: Platform,
                spec: PodSpec,
                subspecs: [PodSpec],
                options: BuildOptions) {
        self.platform = platform
        self.spec = spec
        self.subspecs = subspecs
        self.options = options
    }

    public var result: SourcesAnalyzerResult {
        return run()
    }

    private func run() -> SourcesAnalyzerResult {
        let sourceFiles = spec.getFilesNodes(subspecs: subspecs,
                                             includesKeyPath: \.sourceFiles,
                                             excludesKeyPath: \.excludeFiles,
                                             fileTypes: AnyFileTypes,
                                             options: options)
            .platform(platform)
            .map({ GlobNode(include: $0.include) }) // TODO: Think about it

        let publicHeaders = spec.getFilesNodes(subspecs: subspecs,
                                               includesKeyPath: \.publicHeaders,
                                               excludesKeyPath: \.privateHeaders,
                                               fileTypes: HeaderFileTypes,
                                               options: options)
            .platform(platform)

        let privateHeaders = spec.getFilesNodes(subspecs: subspecs,
                                                includesKeyPath: \.privateHeaders,
                                                fileTypes: HeaderFileTypes,
                                                options: options)
            .platform(platform)
        let allSources = [sourceFiles, publicHeaders, privateHeaders].reduce(Set<String>()) { partialResult, node in
            guard let node else { return partialResult }
            return partialResult.union(node.sourcesOnDisk(options))
        }.setmap(transform: { "." + $0.pathExtenstion })

        let hasSwift = !allSources.intersection(SwiftLikeFileTypes).isEmpty
        let hasObjc = !allSources.intersection(ObjcCppLikeFileTypes).isEmpty
        let hasHeaders = !allSources.intersection(HeaderFileTypes).isEmpty

        let sourcesType: SourcesAnalyzerResult.SourcesType
        if hasSwift && (hasObjc || hasHeaders) {
            sourcesType = .mixed
        } else if hasSwift {
            sourcesType = .swiftOnly
        } else if hasObjc {
            sourcesType = .objcOnly
        } else if hasHeaders {
            sourcesType = .headersOnly
        } else {
            sourcesType = .empty
        }

        let linkDynamic = options.useFrameworks && sourceFiles?.isEmpty == false && !spec.staticFramework

        return SourcesAnalyzerResult(
            sourceFiles: sourceFiles ?? .empty,
            publicHeaders: publicHeaders ?? .empty,
            privateHeaders: privateHeaders ?? .empty,
            sourcesType: sourcesType,
            linkDynamic: linkDynamic
        )
    }
}
