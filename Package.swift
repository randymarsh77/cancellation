// swift-tools-version:6.0
import PackageDescription

let package = Package(
	name: "Cancellation",
	products: [
		.library(
			name: "Cancellation",
			targets: ["Cancellation"]
		)
	],
	dependencies: [
		.package(url: "https://github.com/randymarsh77/idisposable", branch: "master")
	],
	targets: [
		.target(
			name: "Cancellation",
			dependencies: [.product(name: "IDisposable", package: "IDisposable")]
		),
		.testTarget(name: "CancellationTests", dependencies: ["Cancellation"]),
	]
)
