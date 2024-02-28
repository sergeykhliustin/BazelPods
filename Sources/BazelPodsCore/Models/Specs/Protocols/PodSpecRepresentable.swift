//
//  PodSpecRepresentable.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 02.02.2024.
//

import Foundation

protocol PodSpecRepresentable: BaseInfoRepresentable,
                               SourceFilesRepresentable,
                               SdkDependenciesRepresentable,
                               ResourcesRepresentable,
                               PodDependenciesRepresentable,
                               VendoredDependenciesRepresentable,
                               XCConfigRepresentable,
                               InfoPlistRepresentable {
    var subspecs: [Self] { get }
    var compilerFlags: [String] { get }
    var source: PodSpecSource? { get }
    var headerDirectory: String? { get }
    var prefixHeaderContents: String? { get }
    var prefixHeaderFile: Either<Bool, String>? { get }
    var preservePaths: [String] { get }
    var defaultSubspecs: [String] { get }
    var testspecs: [TestSpec] { get }
}
