//
//  TestSpecRepresentable.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 02.02.2024.
//

import Foundation

enum TestSpecTestType: String {
    case unit
    case ui
}

protocol TestSpecRepresentable: BaseRepresentable,
                                BaseInfoRepresentable,
                                SourceFilesRepresentable,
                                SdkDependenciesRepresentable,
                                ResourcesRepresentable,
                                PodDependenciesRepresentable,
                                XCConfigRepresentable,
                                VendoredDependenciesRepresentable,
                                InfoPlistRepresentable,
                                SchemeRepresentable {
    var testType: TestSpecTestType { get }
    var appHostName: String? { get }
    var requiresAppHost: Bool { get }
}
