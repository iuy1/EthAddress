// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "EthAddress",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "Cli", targets: ["Cli"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    .package(url: "https://github.com/schwa/MetalCompilerPlugin", branch: "main"),
  ],
  targets: [
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
      dependencies: [
        "EthAddress",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .testTarget(
      name: "Tests",
      dependencies: ["EthAddress"]
    ),
  ]
)
