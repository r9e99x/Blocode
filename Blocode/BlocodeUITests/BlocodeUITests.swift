//
//  BlocodeUITests.swift
//  BlocodeUITests
//
//  실제 앱을 macOS에서 띄워서 홈 → 챕터맵 → 챕터 진입까지 화면을 실제로 구동해 검증.
//  BlocodeTests(유닛 테스트)와 달리 화면 접근성 트리를 통해 실제 탭 동작까지 확인한다.
//  진행도(별점/클리어 기록)에 영향받지 않는 구조적 내비게이션만 검증 — 챕터 1은 항상 해금 상태이므로
//  진행도 상태와 무관하게 항상 안정적으로 통과함.

import XCTest

final class BlocodeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func test_appLaunches_andShowsChapterBrowseButton() throws {
        let app = XCUIApplication()
        app.launch()

        let browseButton = app.buttons["챕터 둘러보기"]
        XCTAssertTrue(browseButton.waitForExistence(timeout: 5), "홈 화면에 '챕터 둘러보기' 버튼이 안 보임")
    }

    @MainActor
    func test_tappingChapterBrowseButton_navigatesToChapterMap() throws {
        let app = XCUIApplication()
        app.launch()

        let browseButton = app.buttons["챕터 둘러보기"]
        XCTAssertTrue(browseButton.waitForExistence(timeout: 5))
        browseButton.tap()

        // 챕터맵 화면의 "chapter map" 타이틀 + 항상 해금 상태인 챕터 1("기본기")이 보여야 함
        XCTAssertTrue(app.staticTexts["chapter map"].waitForExistence(timeout: 5), "챕터맵 화면으로 전환 안 됨")
        XCTAssertTrue(app.staticTexts["기본기"].waitForExistence(timeout: 5), "챕터 1(기본기) 카드가 안 보임")
    }

    @MainActor
    func test_enteringFirstChapter_showsFirstStageName() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["챕터 둘러보기"].tap()

        let chapterOneCard = app.staticTexts["기본기"]
        XCTAssertTrue(chapterOneCard.waitForExistence(timeout: 5))
        chapterOneCard.tap()

        // 챕터 1의 첫 스테이지 이름("첫 걸음")이 스테이지 목록에 보여야 함 —
        // 진행도(클리어 여부)와 무관하게 챕터 1 진입 자체는 항상 가능
        XCTAssertTrue(app.staticTexts["첫 걸음"].waitForExistence(timeout: 5), "챕터 1 진입 후 첫 스테이지 이름이 안 보임")
    }
}
