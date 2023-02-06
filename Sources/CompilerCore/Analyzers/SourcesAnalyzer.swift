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
        let sourceFiles = getFilesNodes(spec: spec,
                                        subspecs: subspecs,
                                        includesKeyPath: \.sourceFiles,
                                        excludesKeyPath: \.excludeFiles,
                                        fileTypes: AnyFileTypes,
                                        options: options)
            .platform(platform)
            .map({ GlobNode(include: $0.include) }) // TODO: Think about it

        let publicHeaders = getFilesNodes(spec: spec,
                                          subspecs: subspecs,
                                          includesKeyPath: \.publicHeaders,
                                          excludesKeyPath: \.privateHeaders,
                                          fileTypes: HeaderFileTypes,
                                          options: options)
            .platform(platform)

        let privateHeaders = getFilesNodes(spec: spec,
                                           subspecs: subspecs,
                                           includesKeyPath: \.privateHeaders,
                                           fileTypes: HeaderFileTypes,
                                           options: options)
            .platform(platform)
        let allSources = [sourceFiles, publicHeaders, privateHeaders].reduce(Set<String>()) { partialResult, node in
            guard let node else { return partialResult }
            return partialResult.union(node.sourcesOnDisk(options))
        }.setmap(transform: { "." + $0.pathExtention })

        let hasSwift = !allSources.isDisjoint(with: SwiftLikeFileTypes)
        let hasObjc = !allSources.isDisjoint(with: ObjcCppLikeFileTypes)
        let hasHeaders = !allSources.isDisjoint(with: HeaderFileTypes)

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

    func getFilesNodes(spec: PodSpec,
                       subspecs: [PodSpec] = [],
                       includesKeyPath: KeyPath<PodSpecRepresentable, [String]>,
                       excludesKeyPath: KeyPath<PodSpecRepresentable, [String]>? = nil,
                       fileTypes: Set<String>,
                       options: BuildOptions) -> AttrSet<GlobNode> {
        let (implFiles, implExcludes) = getFiles(spec: spec,
                                                 subspecs: subspecs,
                                                 includesKeyPath: includesKeyPath,
                                                 excludesKeyPath: excludesKeyPath,
                                                 fileTypes: fileTypes,
                                                 options: options)

        return implFiles.zip(implExcludes).map {
            GlobNode(include: .left($0.first?.sorted() ?? []), exclude: .left($0.second?.sorted() ?? []))
        }
    }

    func getFiles(spec: PodSpec,
                  subspecs: [PodSpec] = [],
                  includesKeyPath: KeyPath<PodSpecRepresentable, [String]>,
                  excludesKeyPath: KeyPath<PodSpecRepresentable, [String]>? = nil,
                  fileTypes: Set<String>,
                  options: BuildOptions) -> (includes: AttrSet<Set<String>>, excludes: AttrSet<Set<String>>) {
        let includePattern = spec.collectAttribute(with: subspecs, keyPath: includesKeyPath)
        let depsIncludes = extractFiles(fromPattern: includePattern, includingFileTypes: fileTypes, options: options)
            .map({ Set($0) })

        let depsExcludes: AttrSet<Set<String>>
        if let excludesKeyPath = excludesKeyPath {
            let excludesPattern = spec.collectAttribute(with: subspecs, keyPath: excludesKeyPath)
            depsExcludes = extractFiles(fromPattern: excludesPattern, includingFileTypes: fileTypes, options: options)
                .map({ Set($0) })
        } else {
            depsExcludes = .empty
        }

        return (depsIncludes, depsExcludes)
    }
}
