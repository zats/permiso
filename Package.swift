// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Permiso",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "Permiso",
            targets: ["Permiso"]
        )
    ],
    targets: [
        .target(
            name: "Permiso"
        ),
        .testTarget(
            name: "PermisoTests",
            dependencies: ["Permiso"]
        )
    ]
)
