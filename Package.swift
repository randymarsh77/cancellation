// swift-tools-version:5.1
import PackageDescription

let package = Package(
	name: "Cancellation",
	products: [
		.library(
			name: "Cancellation",
			targets: ["Cancellation"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/randymarsh77/idisposable", .branch("master")),
	],
	targets: [
		.target(
			name: "Cancellation",
			dependencies: ["IDisposable"]
		),
		.testTarget(name: "CancellationTests", dependencies: ["Cancellation"]),
	]
)
