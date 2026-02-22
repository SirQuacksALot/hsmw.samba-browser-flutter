// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "samba_browser",
    platforms: [
        .iOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/amosavian/AMSMB2", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "samba_browser",
            dependencies: ["AMSMB2"]
        )
    ]
)
