// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "LiveVault",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // Core Products
        .library(name: "LiveVaultCommon", targets: ["LiveVaultCommon"]),
        .library(name: "LiveVaultNetwork", targets: ["LiveVaultNetwork"]),
        .library(name: "LiveVaultDatabase", targets: ["LiveVaultDatabase"]),
        .library(name: "LiveVaultDesignSystem", targets: ["LiveVaultDesignSystem"]),
        
        // Feature Products
        .library(name: "FeatureAuth", targets: ["FeatureAuth"]),
        .library(name: "FeatureHome", targets: ["FeatureHome"]),
        .library(name: "FeatureBrowser", targets: ["FeatureBrowser"]),
        .library(name: "FeatureChannel", targets: ["FeatureChannel"]),
        .library(name: "FeatureLibrary", targets: ["FeatureLibrary"]),
        .library(name: "FeaturePlayer", targets: ["FeaturePlayer"]),
        .library(name: "FeatureRecordingDetail", targets: ["FeatureRecordingDetail"]),
        .library(name: "FeatureNotifications", targets: ["FeatureNotifications"]),
        .library(name: "FeatureSettings", targets: ["FeatureSettings"]),
        .library(name: "FeaturePaywall", targets: ["FeaturePaywall"]),
        
        // Main App Module
        .library(name: "LiveVaultAppCore", targets: ["LiveVaultAppCore"])
    ],
    dependencies: [
        // StoreKit 2 is built-in.
    ],
    targets: [
        // ? Core Targets
        .target(
            name: "LiveVaultCommon",
            dependencies: [],
            path: "Sources/LiveVaultCommon"
        ),
        .target(
            name: "LiveVaultNetwork",
            dependencies: [
                "LiveVaultCommon"
            ],
            path: "Sources/LiveVaultNetwork"
        ),
        .target(
            name: "LiveVaultDatabase",
            dependencies: [
                "LiveVaultCommon"
            ],
            path: "Sources/LiveVaultDatabase"
        ),
        .target(
            name: "LiveVaultDesignSystem",
            dependencies: [
                "LiveVaultCommon"
            ],
            path: "Sources/LiveVaultDesignSystem"
        ),
        
        // ? Feature Targets
        .target(
            name: "FeatureAuth",
            dependencies: [
                "LiveVaultCommon",
                "LiveVaultNetwork",
                "LiveVaultDesignSystem"
            ],
            path: "Sources/FeatureAuth"
        ),
        .target(
            name: "FeatureBrowser",
            dependencies: [
                "LiveVaultCommon",
                "LiveVaultDesignSystem"
            ],
            path: "Sources/FeatureBrowser",
            resources: [
                .process("StreamSnifferScript.js")
            ]
        ),
        .target(
            name: "FeatureHome",
            dependencies: [
                "LiveVaultCommon",
                "LiveVaultNetwork",
                "LiveVaultDatabase",
                "LiveVaultDesignSystem"
            ],
            path: "Sources/FeatureHome"
        ),
        .target(
            name: "FeatureChannel",
            dependencies: [
                "LiveVaultCommon",
                "LiveVaultNetwork",
                "LiveVaultDatabase",
                "LiveVaultDesignSystem"
            ],
            path: "Sources/FeatureChannel"
        ),
        .target(
            name: "FeatureLibrary",
            dependencies: [
                "LiveVaultCommon",
                "LiveVaultNetwork",
                "LiveVaultDatabase",
                "LiveVaultDesignSystem"
            ],
            path: "Sources/FeatureLibrary"
        ),
        .target(
            name: "FeaturePlayer",
            dependencies: [
                "LiveVaultCommon",
                "LiveVaultNetwork",
                "LiveVaultDesignSystem"
            ],
            path: "Sources/FeaturePlayer"
        ),
        .target(
            name: "FeatureRecordingDetail",
            dependencies: [
                "LiveVaultCommon",
                "LiveVaultNetwork",
                "LiveVaultDatabase",
                "LiveVaultDesignSystem"
            ],
            path: "Sources/FeatureRecordingDetail"
        ),
        .target(
            name: "FeatureNotifications",
            dependencies: [
                "LiveVaultCommon",
                "LiveVaultNetwork",
                "LiveVaultDatabase",
                "LiveVaultDesignSystem"
            ],
            path: "Sources/FeatureNotifications"
        ),
        .target(
            name: "FeatureSettings",
            dependencies: [
                "LiveVaultCommon",
                "LiveVaultNetwork",
                "LiveVaultDatabase",
                "LiveVaultDesignSystem"
            ],
            path: "Sources/FeatureSettings"
        ),
        .target(
            name: "FeaturePaywall",
            dependencies: [
                "LiveVaultCommon",
                "LiveVaultNetwork",
                "LiveVaultDesignSystem"
            ],
            path: "Sources/FeaturePaywall"
        ),
        
        // ? App Core (Aggregator for App Target)
        .target(
            name: "LiveVaultAppCore",
            dependencies: [
                "LiveVaultCommon",
                "LiveVaultNetwork",
                "LiveVaultDatabase",
                "LiveVaultDesignSystem",
                "FeatureAuth",
                "FeatureBrowser",
                "FeatureHome",
                "FeatureChannel",
                "FeatureLibrary",
                "FeaturePlayer",
                "FeatureRecordingDetail",
                "FeatureNotifications",
                "FeatureSettings",
                "FeaturePaywall"
            ],
            path: "Sources/LiveVaultAppCore"
        ),
        
        // ? Test Targets
        .testTarget(
            name: "LiveVaultNetworkTests",
            dependencies: ["LiveVaultNetwork", "LiveVaultCommon"],
            path: "Tests/LiveVaultNetworkTests"
        ),
        .testTarget(
            name: "LiveVaultViewModelTests",
            dependencies: [
                "LiveVaultAppCore",
                "LiveVaultCommon",
                "LiveVaultNetwork",
                "LiveVaultDatabase",
                "FeatureAuth",
                "FeatureHome",
                "FeatureLibrary",
                "FeaturePlayer",
                "FeatureSettings"
            ],
            path: "Tests/LiveVaultViewModelTests"
        )
    ]
)