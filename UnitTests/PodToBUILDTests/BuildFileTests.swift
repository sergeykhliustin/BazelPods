//
//  BuildFileTests.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 4/14/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import XCTest
@testable import PodToBUILD

class BuildFileTests: XCTestCase {
    func basicGlob(include: Set<String>) -> AttrSet<GlobNode> {
        return AttrSet(basic: GlobNode(include: include))
    }

    // MARK: - Multiplatform Tests

//    func testLibFromPodspec() {
//        let podspec = examplePodSpecNamed(name: "IGListKit")
//        let lib = ObjcLibrary(parentSpecs: [], spec: podspec)
//
//        let expectedFrameworks: AttrSet<[String]> = AttrSet(multi: MultiPlatform(
//            ios: ["UIKit"],
//            osx: ["Cocoa"],
//            watchos: nil,
//            tvos: ["UIKit"]))
//        XCTAssert(lib.sdkFrameworks == expectedFrameworks)
//    }
//
//    func testDependOnDefaultSubspecs() {
//        let podspec = examplePodSpecNamed(name: "IGListKit")
//        let convs = PodBuildFile.makeConvertables(fromPodspec: podspec)
//
//        XCTAssert(
//            AttrSet(basic: [":Default"]) ==
//                (convs.compactMap{ $0 as? ObjcLibrary}.first!).deps
//        )
//    }
//
//    func testDependOnSubspecs() {
//        let podspec = examplePodSpecNamed(name: "PINCache")
//        let convs = PodBuildFile.makeConvertables(fromPodspec: podspec)
//
//        XCTAssert(
//            AttrSet(basic: [":Core", ":Arc-exception-safe"]) ==
//                (convs.compactMap{ $0 as? ObjcLibrary}.first!).deps
//        )
//    }
//
//    // MARK: - Swift tests
//
//    func testSwiftExtractionSubspec() {
//        let podspec = examplePodSpecNamed(name: "ObjcParentWithSwiftSubspecs")
//        let convs = PodBuildFile.makeConvertables(fromPodspec: podspec)
//        XCTAssertEqual(convs.compactMap{ $0 as? ObjcLibrary }.count, 3)
//        // Note that we check for sources on disk to generate this.
//        XCTAssertEqual(convs.compactMap{ $0 as? SwiftLibrary }.count, 0)
//    }
//
//
//    // MARK: - Source File Extraction Tests
//
//    func testExtractionCurly() {
//        let podPattern = "Source/Classes/**/*.{h,m}"
//        let extractedHeaders = extractFiles(fromPattern: AttrSet(basic: [podPattern]),
//                includingFileTypes: HeaderFileTypes).basic
//        let extractedSources = extractFiles(fromPattern: AttrSet(basic: [podPattern]),
//                includingFileTypes: ObjcLikeFileTypes).basic
//        XCTAssertEqual(extractedHeaders, ["Source/Classes/**/*.h"])
//        XCTAssertEqual(extractedSources, ["Source/Classes/**/*.m"])
//    }
//
//    func testExtractionWithBarPattern() {
//        let podPattern = "Source/Classes/**/*.[h,m]"
//        let extractedHeaders = extractFiles(fromPattern: AttrSet(basic: [podPattern]),
//                includingFileTypes: HeaderFileTypes).basic
//        let extractedSources = extractFiles(fromPattern: AttrSet(basic: [podPattern]),
//                includingFileTypes: ObjcLikeFileTypes).basic
//
//        XCTAssertEqual(extractedHeaders, ["Source/Classes/**/*.h"])
//        XCTAssertEqual(extractedSources, ["Source/Classes/**/*.m"])
//    }
//
//    func testExtractionMultiplatform() {
//        let podPattern = "Source/Classes/**/*.[h,m]"
//        let extractedHeaders = extractFiles(fromPattern: AttrSet(basic: [podPattern]),
//                includingFileTypes: HeaderFileTypes)
//        let extractedSources = extractFiles(fromPattern: AttrSet(basic: [podPattern]),
//                includingFileTypes: ObjcLikeFileTypes)
//        XCTAssert(extractedHeaders == AttrSet(basic: ["Source/Classes/**/*.h"]))
//        XCTAssert(extractedSources == AttrSet(basic: ["Source/Classes/**/*.m"]))
//    }
//
//    func testHeaderIncAutoGlob() {
//        let podSpec = examplePodSpecNamed(name: "UICollectionViewLeftAlignedLayout")
//        let library = ObjcLibrary(parentSpecs: [], spec: podSpec)
//        guard let ios = library.headers.multi.ios else {
//            XCTFail("Missing iOS headers for lib \(library)")
//            return
//        }
//        XCTAssertEqual(
//            ios, GlobNode(include: Set([
//                    "UICollectionViewLeftAlignedLayout/**/*.h",
//                    "UICollectionViewLeftAlignedLayout/**/*.hpp",
//                    "UICollectionViewLeftAlignedLayout/**/*.hxx"
//                ]))
//        )
//
//    }
//
//    // MARK: - JSON Examples
//
//    func testGoogleAPISJSONParsing() {
//        let podSpec = examplePodSpecNamed(name: "googleapis")
//        XCTAssertEqual(podSpec.name, "googleapis")
//        XCTAssertEqual(podSpec.sourceFiles, [String]())
//        XCTAssertEqual(podSpec.podTargetXcconfig!, [
//            "USER_HEADER_SEARCH_PATHS": "$SRCROOT/..",
//            "GCC_PREPROCESSOR_DEFINITIONS": "$(inherited) GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1",
//        ]
//        )
//    }
//
//    func testIGListKitJSONParsing() {
//        let podSpec = examplePodSpecNamed(name: "IGListKit")
//        XCTAssertEqual(podSpec.name, "IGListKit")
//        XCTAssertEqual(podSpec.sourceFiles, [String]())
//        XCTAssertEqual(podSpec.podTargetXcconfig!, [
//            "CLANG_CXX_LANGUAGE_STANDARD": "c++11",
//            "CLANG_CXX_LIBRARY": "libc++",
//        ]
//        )
//    }
//
//    // MARK: - XCConfigs
//
//    func testPreProcesorDefsXCConfigs() {
//        // We strip off inherited.
//        let config = [
//            "USER_HEADER_SEARCH_PATHS": "$SRCROOT/..",
//            "GCC_PREPROCESSOR_DEFINITIONS": "$(inherited) GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1",
//        ]
//        let compilerFlags = XCConfigTransformer
//            .defaultTransformer(externalName: "test", sourceType: .objc)
//            .compilerFlags(forXCConfig: config)
//        XCTAssertEqual(compilerFlags, ["-DGPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1"])
//    }
//
//    func testCXXXCConfigs() {
//        let config = [
//            "CLANG_CXX_LANGUAGE_STANDARD": "c++11",
//            "CLANG_CXX_LIBRARY": "libc++",
//        ]
//        let compilerFlags = XCConfigTransformer
//            .defaultTransformer(externalName: "test", sourceType: .cpp)
//            .compilerFlags(forXCConfig: config)
//        XCTAssertEqual(compilerFlags.sorted(by: (<)), ["-std=c++11", "-stdlib=libc++"])
//    }
}
