// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RestaurantSplit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "RestaurantSplit",
            targets: ["RestaurantSplit"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "RestaurantSplit",
            dependencies: []),
        .testTarget(
            name: "RestaurantSplitTests",
            dependencies: ["RestaurantSplit"])
    ]
)
