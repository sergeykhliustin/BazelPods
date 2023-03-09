//
//  SourcesAnalyzer.swift
//  CompilerCore
//
//  Created by Sergey Khliustin on 03.02.2023.
//

import Foundation

private let ObjcLikeFileTypes = Set([".m", ".c", ".s", ".S"])
private let CppLikeFileTypes  = Set([".mm", ".cpp", ".cxx", ".cc"])
private let SwiftLikeFileTypes  = Set([".swift"])
private let HeaderFileTypes = Set([".h", ".hpp", ".hxx"])
private let ObjcCppLikeFileTypes = ObjcLikeFileTypes.union(CppLikeFileTypes)
private let AnyFileTypes = ObjcLikeFileTypes
    .union(CppLikeFileTypes)
    .union(SwiftLikeFileTypes)
    .union(HeaderFileTypes)

public struct SourcesAnalyzer {
    public struct Result {
        enum SourcesType {
            case empty
            case headersOnly
            case objcOnly
            case swiftOnly
            case mixed

            func oneOf(_ values: Self...) -> Bool {
                return values.contains(self)
            }
        }
        let sourceFiles: GlobNodeV2
        let publicHeaders: GlobNodeV2
        let privateHeaders: GlobNodeV2
        let sourcesType: SourcesType
        var linkDynamic: Bool
    }

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

    public var result: Result {
        return run()
    }

    private func run() -> Result {
        var sourceFiles = getFilesNodes(spec: spec,
                                        subspecs: subspecs,
                                        includesKeyPath: \.sourceFiles,
                                        excludesKeyPath: \.excludeFiles,
                                        fileTypes: AnyFileTypes,
                                        options: options)
            .platform(platform)
            .map({ GlobNodeV2(include: $0.include) })

        var publicHeaders = getFilesNodes(spec: spec,
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

        let sourcesType: Result.SourcesType
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

        if sourcesType == .headersOnly {
            if let lpublicHeaders = publicHeaders {
                if let sourceFiles {
                    publicHeaders = lpublicHeaders <> sourceFiles
                }
            } else {
                publicHeaders = sourceFiles
            }
            sourceFiles = nil
        }

        let linkDynamic =
        platform.supportsDynamic &&
        options.useFrameworks &&
        !spec.staticFramework &&
        sourcesType.oneOf(.swiftOnly, .objcOnly, .mixed)

        return Result(
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
                       options: BuildOptions) -> AttrSet<GlobNodeV2> {
        let (implFiles, implExcludes) = getFiles(spec: spec,
                                                 subspecs: subspecs,
                                                 includesKeyPath: includesKeyPath,
                                                 excludesKeyPath: excludesKeyPath,
                                                 fileTypes: fileTypes,
                                                 options: options)

        return implFiles.zip(implExcludes).map {
            GlobNodeV2(include: $0.first?.sorted() ?? [], exclude: $0.second?.sorted() ?? [])
        }
    }

    func getFiles(spec: PodSpec,
                  subspecs: [PodSpec] = [],
                  includesKeyPath: KeyPath<PodSpecRepresentable, [String]>,
                  excludesKeyPath: KeyPath<PodSpecRepresentable, [String]>? = nil,
                  fileTypes: Set<String>,
                  options: BuildOptions) -> (includes: AttrSet<Set<String>>, excludes: AttrSet<Set<String>>) {
        let includePattern = spec.collectAttribute(with: subspecs, keyPath: includesKeyPath)
        let depsIncludes = extractFiles(fromPattern: includePattern, includingFileTypes: fileTypes)
            .map({ Set($0) })

        let depsExcludes: AttrSet<Set<String>>
        if let excludesKeyPath = excludesKeyPath {
            let excludesPattern = spec.collectAttribute(with: subspecs, keyPath: excludesKeyPath)
            depsExcludes = extractFiles(fromPattern: excludesPattern, includingFileTypes: fileTypes)
                .map({ Set($0) })
        } else {
            depsExcludes = .empty
        }

        return (depsIncludes, depsExcludes)
    }

    private func extractFiles(fromPattern patternSet: AttrSet<[String]>,
                              includingFileTypes: Set<String>) -> AttrSet<[String]> {
        return patternSet.map { (patterns: [String]) -> [String] in
            let result = patterns.flatMap { (p: String) -> [String] in
                pattern(fromPattern: p, includingFileTypes:
                            includingFileTypes)
            }
            return result
        }
    }
}
