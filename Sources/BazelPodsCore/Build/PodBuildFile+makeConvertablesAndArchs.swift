//
//  PodBuildFile+makeConvertablesAndArchs.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 08.02.2024.
//

import Foundation

extension PodBuildFile {
    static func makeConvertablesAndArchs(fromPodspec spec: PodSpec,
                                         options: BuildOptions)
    -> ([StarlarkConvertible], [Arch]) {
        let subspecs = spec.selectedSubspecs(subspecs: options.subspecs)
        var output: [BazelTarget] = []
        var archs: Set<Arch> = []
        for platform in options.platforms {
            let targetName = TargetName(platform: platform, platformSuffix: options.platforms.count > 1)
            var analyzer: BaseSpecAnalyzer<PodSpec>
            do {
                analyzer = try BaseSpecAnalyzer(targetName: targetName,
                                                platform: platform,
                                                spec: spec,
                                                subspecs: subspecs,
                                                options: options)
            } catch {
                log_debug(error)
                continue
            }

            let (resourceTargets, resourceInfoplists) = makeResourceBundles(
                targetName: targetName,
                baseInfo: analyzer.baseInfo,
                resources: analyzer.resourcesInfo
            )

            let (vendoredTargets, conditions) = makeVendoredTargets(
                targetName: targetName,
                baseInfo: analyzer.baseInfo,
                vendored: analyzer.vendoredDepsInfo)

            let deps = (
                (resourceTargets.map({ $0.name })) +
                analyzer.podDepsInfo.dependencies
            ).sorted()

            let (sourceTargets, infoplists) = makeSourceLibs(analyzer: analyzer,
                                                             deps: deps,
                                                             conditionalDeps: conditions)
            archs = conditions.reduce(archs) { partialResult, element in
                var result = partialResult
                element.value.forEach({
                    result.insert($0)
                })
                return result
            }

            output += sourceTargets
            output += resourceTargets
            output += vendoredTargets
            output += infoplists
            output += resourceInfoplists
        }

        output += makeTestspecs(spec: spec, options: options)
        output += makeAppspecs(spec: spec, options: options)

        output = output.reduce(into: [BazelTarget](), { result, target in
            if result.contains(where: { $0.name == target.name }) {
                log_debug("Duplicated target name: \(target.name)")
            } else {
                result.append(target)
            }
        })

        return (output, archs.sorted())
    }
}
