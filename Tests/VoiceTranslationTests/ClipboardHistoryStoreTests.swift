import Foundation
import XCTest
@testable import VoiceTranslation

final class ClipboardHistoryStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: ClipboardHistoryStore!

    override func setUp() {
        super.setUp()
        suiteName = "ClipboardHistoryStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        store = ClipboardHistoryStore(defaults: defaults)
    }

    override func tearDown() {
        store = nil
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testAddDeduplicatesAndKeepsLatestFirst() {
        store.add("First reply")
        store.add("Second reply")
        store.add("First reply")

        let items = store.items()

        XCTAssertEqual(items.map(\.text), ["First reply", "Second reply"])
    }

    func testHistoryIsCappedAtTwentyItems() {
        for index in 1...25 {
            store.add("Reply \(index)")
        }

        let items = store.items()

        XCTAssertEqual(items.count, 20)
        XCTAssertEqual(items.first?.text, "Reply 25")
        XCTAssertEqual(items.last?.text, "Reply 6")
    }

    func testEmptyRepliesAreIgnored() {
        store.add("   \n ")

        XCTAssertTrue(store.items().isEmpty)
    }
}
