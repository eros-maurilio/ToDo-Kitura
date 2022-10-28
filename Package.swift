// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ToDoApp",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .executable(
            name: "ToDoApp",
            targets: [ "ToDoApp" ])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.3.2")),
        .package(url: "https://github.com/Kitura/Kitura.git", .upToNextMajor(from: "2.9.200")),
        .package(url: "https://github.com/IBM-Swift/Kitura-OpenAPI.git", from: "1.0.0"),
        .package(url: "https://github.com/Kitura/CloudEnvironment.git", from: "9.1.0"),
        .package(url: "https://github.com/Kitura/Health.git", from: "1.0.5"),
        .package(url: "https://github.com/Kitura/HeliumLogger.git", from: "1.9.0"),
        .package(url: "https://github.com/Kitura/Kitura-CORS.git", from: "2.1.1"),
        .package(url: "https://github.com/Kitura/Swift-Kuery.git", from: "3.0.1"),
        .package(url: "https://github.com/IBM-Swift/SwiftKueryMySQL.git", from: "2.0.2")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ToDoApp",
            dependencies: [
                .target(name: "Application"),
                "CloudEnvironment",
                "Health",
                "HeliumLogger",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "KituraOpenAPI", package: "Kitura-OpenAPI"),

            ]),
        .target(name: "Application", dependencies: [ "Kitura",
                                                     .product(name: "SwiftKueryMySQL", package: "SwiftKueryMySQL"),
                                                     .product(name: "SwiftKuery", package: "Swift-Kuery"),
                                                     .product(name: "KituraCORS", package: "Kitura-CORS"),
]),
        .testTarget(
            name: "ToDoAppTests",
            dependencies: ["ToDoApp"]),
    ]
)
