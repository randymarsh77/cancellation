import PackageDescription

let package = Package(
    name: "Cancellation",
    dependencies: [
		.Package(url: "https://github.com/randymarsh77/idisposable", majorVersion: 1),
	]
)
