// swift-tools-version: 6.1

import PackageDescription

let package = Package(
	name: "swg",
	platforms: [.iOS(.v18), .macOS(.v14), .tvOS(.v17), .visionOS(.v1)],
	products: [
		.library(name: "Swg", targets: ["Swg"]),
	],
	targets: [
		.target(name: "Swg"),
		.testTarget(name: "SwgTests", dependencies: ["Swg"]),
	]
)
