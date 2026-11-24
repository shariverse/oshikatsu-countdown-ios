//
//  PlusEntryPolicyTests.swift
//  OshiConTests
//

@testable import OshiCon
import StoreKit
import Testing

struct PlusEntryPolicyTests {
    @Test("DEBUG のビルドは、取引の環境にかかわらず開発版")
    func debugBuild() {
        #expect(AppDistribution.resolve(isDebugBuild: true, storeEnvironment: .production) == .development)
        #expect(AppDistribution.resolve(isDebugBuild: true, storeEnvironment: .sandbox) == .development)
        #expect(AppDistribution.resolve(isDebugBuild: true, storeEnvironment: nil) == .development)
    }

    @Test("リリースのビルドは、取引の環境で見分ける（TestFlight は sandbox）")
    func releaseBuild() {
        #expect(AppDistribution.resolve(isDebugBuild: false, storeEnvironment: .sandbox) == .testFlight)
        #expect(AppDistribution.resolve(isDebugBuild: false, storeEnvironment: .production) == .appStore)
        #expect(AppDistribution.resolve(isDebugBuild: false, storeEnvironment: .xcode) == .development)
    }

    @Test("取引の環境が分からないときは App Store 版として扱い、入口は出す")
    func unknownEnvironment() {
        let distribution = AppDistribution.resolve(isDebugBuild: false, storeEnvironment: nil)
        #expect(distribution == .appStore)
        #expect(PlusEntryPolicy.showsEntry(in: distribution))
    }

    @Test("入口は App Store 版を含むどの配り方でも出す（1.3.0 で Plus を売り始めた）")
    func showsEntry() {
        #expect(PlusEntryPolicy.showsEntry(in: .development))
        #expect(PlusEntryPolicy.showsEntry(in: .testFlight))
        #expect(PlusEntryPolicy.showsEntry(in: .appStore))
    }

    @Test("見分ける口は差し替えられる")
    func fixedDetector() async {
        #expect(await AppDistributionDetector.fixed(.testFlight)() == .testFlight)
        #expect(await AppDistributionDetector.fixed(.appStore)() == .appStore)
    }

    @Test("テストのホストのアプリ（DEBUG のビルド）は開発版として入口を出す")
    func liveDetectorInDebugBuild() async {
        #expect(await AppDistributionDetector.live() == .development)
    }
}
