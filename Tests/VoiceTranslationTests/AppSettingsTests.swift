import Foundation
import XCTest
@testable import VoiceTranslation

final class AppSettingsTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "VoiceTranslationTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testDefaultSettingsArePrivateFriendlyAndReadyToUse() {
        let settings = AppSettings.load(defaults: defaults)

        XCTAssertEqual(settings.tone, .casual)
        XCTAssertEqual(settings.outputVariant, .britishEnglish)
        XCTAssertEqual(settings.shortcut, .controlOptionCommandSpace)
        XCTAssertTrue(settings.saveClipboardHistory)
        XCTAssertEqual(settings.contextPrompt, "")
    }

    func testSettingsRoundTrip() {
        let settings = AppSettings(
            tone: .polished,
            outputVariant: .americanEnglish,
            contextPrompt: "Keep replies concise.",
            shortcut: .controlOptionCommandR,
            saveClipboardHistory: false
        )

        settings.save(defaults: defaults)
        let loaded = AppSettings.load(defaults: defaults)

        XCTAssertEqual(loaded.tone, .polished)
        XCTAssertEqual(loaded.outputVariant, .americanEnglish)
        XCTAssertEqual(loaded.contextPrompt, "Keep replies concise.")
        XCTAssertEqual(loaded.shortcut, .controlOptionCommandR)
        XCTAssertFalse(loaded.saveClipboardHistory)
    }
}
