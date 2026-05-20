// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AtlasShared",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "AtlasShared", targets: ["AtlasShared"]),
    ],
    targets: [
        .target(
            name: "AtlasShared",
            path: "Sources/AtlasShared"
        ),
    ]
)
