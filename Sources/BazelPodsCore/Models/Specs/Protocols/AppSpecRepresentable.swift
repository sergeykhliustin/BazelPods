//
//  AppSpecRepresentable.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 08.02.2024.
//

import Foundation

protocol AppSpecRepresentable: BaseRepresentable,
                               BaseInfoRepresentable,
                               SourceFilesRepresentable,
                               SdkDependenciesRepresentable,
                               ResourcesRepresentable,
                               PodDependenciesRepresentable,
                               XCConfigRepresentable,
                               VendoredDependenciesRepresentable,
                               InfoPlistRepresentable {

}
