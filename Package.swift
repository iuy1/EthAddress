// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "EthAddress",
  // platforms: [.macOS(.v13)],

  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    .package(url: "https://github.com/schwa/MetalCompilerPlugin", branch: "main"),
    // .package(url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.4.0")),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "Headers",
      publicHeadersPath: ".",
    ),
    .target(
      name: "EthAddress",
      dependencies: ["Headers"],
      plugins: [
        .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
      ],
    ),
    .executableTarget(
      name: "Cli",
      dependencies: ["EthAddress"]
    ),
    .testTarget(
      name: "Tests",
      dependencies: ["EthAddress"]
    ),
    // .executableTarget(
    //   name: "Benches",
    //   dependencies: [
    //     .product(name: "Benchmark", package: "package-benchmark")
    //   ],
    //   path: "Benchmarks/BenchmarkTarget",
    //   plugins: [
    //     .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
    //   ]
    // ),
  ]
)
