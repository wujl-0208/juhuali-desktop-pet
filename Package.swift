// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "JuhualiPet",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "JuhualiPet", targets: ["JuhualiPet"])],
    targets: [.executableTarget(name: "JuhualiPet", path: "Sources")]
)
