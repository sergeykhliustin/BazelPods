//
//  RunnerAnalyzer.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 28.02.2024.
//

import Foundation

struct RunnerAnalyzer<S: SchemeRepresentable> {
    struct Result {
        var runnerName: String?
        var testHost: String?
        var timeout: TestsTimeout?
    }

    private let spec: S
    private let options: BuildOptions

    init(spec: S,
         options: BuildOptions) {
        self.spec = spec
        self.options = options
    }

    var result: Result {
        return run()
    }

    private func run() -> Result {
        return Result(
            runnerName: nil,
            testHost: nil,
            timeout: nil
        )
    }
}
