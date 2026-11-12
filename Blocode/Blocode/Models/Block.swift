//
//  Block.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import Foundation

// MARK: - IfCondition
/// if 블럭의 조건 타입 — 앞 칸 상태를 기준으로 자식 블럭 실행 여부 결정
enum IfCondition: String, Codable {
    case pathClear   = "pathClear"    // 앞 칸이 이동 가능하면 자식 블럭 실행 (기본값)
    case pathBlocked = "pathBlocked"  // 앞 칸이 막혀있으면 자식 블럭 실행

    /// 조건 설명 텍스트 (블럭 행에 표시)
    var displayName: String {
        switch self {
        case .pathClear:   return "앞이 뚫려있으면"
        case .pathBlocked: return "앞이 막혀있으면"
        }
    }
}

// MARK: - BlockType
/// 코드 블럭의 종류를 정의하는 열거형
/// 실제 프로그래밍 언어의 기본 명령어와 1:1 대응
enum BlockType: String, Codable, CaseIterable {
    case moveForward   = "moveForward"   // 앞으로 이동
    case moveBackward  = "moveBackward"  // 뒤로 이동
    case turnLeft      = "turnLeft"      // 왼쪽으로 90도 회전
    case turnRight     = "turnRight"     // 오른쪽으로 90도 회전
    case repeatBlock   = "repeat"        // 반복 (자식 블럭들을 N번 반복 실행)
    case ifBlock       = "if"            // 조건문 (앞 칸 상태에 따라 자식 블럭 실행)
    case functionBlock = "function"      // 함수 (자식 블럭들을 서브루틴으로 묶어 실행)
    case collectItem   = "collectItem"   // 보석 획득 (현재 칸에 보석이 있을 때만 성공, 아니면 실패 — 챕터6+ 전용)
    case activateSwitch = "activateSwitch" // 스위치 작동 (현재 칸에 스위치가 있을 때만 성공, 아니면 실패 — 챕터7+ 전용)

    /// 화면에 표시할 블럭 이름 (한국어)
    var displayName: String {
        switch self {
        case .moveForward:    return "앞으로"
        case .moveBackward:   return "뒤로"
        case .turnLeft:       return "왼쪽 회전"
        case .turnRight:      return "오른쪽 회전"
        case .repeatBlock:    return "반복"
        case .ifBlock:        return "만약에"
        case .functionBlock:  return "함수"
        case .collectItem:    return "보석 획득"
        case .activateSwitch: return "스위치 작동"
        }
    }

    /// SF Symbols 아이콘 이름 — 블럭 행과 팔레트에서 사용
    var iconName: String {
        switch self {
        case .moveForward:    return "arrow.up"
        case .moveBackward:   return "arrow.down"
        case .turnLeft:       return "arrow.counterclockwise"
        case .turnRight:      return "arrow.clockwise"
        case .repeatBlock:    return "repeat"
        case .ifBlock:        return "arrow.triangle.branch"  // 분기 경로 아이콘
        case .functionBlock:  return "curlybraces"            // 코드 함수 아이콘
        case .collectItem:    return "diamond.fill"           // 맵 위 보석 마커와 동일한 다이아몬드 모양
        case .activateSwitch: return "hand.tap.fill"          // 스위치를 누르는 동작을 표현
        }
    }

    /// 팔레트 카드에 표시할 짧은 이름
    var shortName: String {
        switch self {
        case .moveForward:    return "앞으로"
        case .moveBackward:   return "뒤로"
        case .turnLeft:       return "왼쪽"
        case .turnRight:      return "오른쪽"
        case .repeatBlock:    return "반복"
        case .ifBlock:        return "만약에"
        case .functionBlock:  return "함수"
        case .collectItem:    return "획득"
        case .activateSwitch: return "스위치"
        }
    }

    /// 자식 블럭을 담는 컨테이너 블럭인지 (반복·만약에·함수) — 판정을 한 곳에서만 함
    var isContainer: Bool {
        self == .repeatBlock || self == .ifBlock || self == .functionBlock
    }

    // 색상(blockColor·lightColor)은 View 계층인 AppColors.swift에 있음 — Model은 UI 타입을 모름
}

// MARK: - Block
/// 사용자가 코드 순서 영역에 추가하는 하나의 코드 블럭
struct Block: Identifiable, Codable {
    var id: UUID          // SwiftUI 리스트 식별자 — ForEach에서 고유 키로 사용
    var type: BlockType   // 블럭 종류

    /// repeat 블럭일 때만 사용: 반복 횟수 (스테퍼로 조절, 기본값 2)
    var repeatCount: Int?

    /// repeat / if / function 블럭일 때 사용: 자식 블럭 목록
    var children: [Block]?

    /// if 블럭일 때만 사용: 조건 타입 (기본값 .pathClear)
    var ifCondition: IfCondition?

    // MARK: - 초기화
    init(type: BlockType,
         repeatCount: Int? = nil,
         children: [Block]? = nil,
         ifCondition: IfCondition? = nil) {
        self.id = UUID()  // 항상 새로운 고유 ID 생성
        self.type = type

        // 자식 블럭을 갖는 컨테이너 타입 (repeat / if / function)

        // repeat 블럭: 기본 반복 횟수 2
        self.repeatCount = (type == .repeatBlock) ? (repeatCount ?? 2) : nil

        // 컨테이너 블럭: 빈 자식 배열로 초기화
        self.children = type.isContainer ? (children ?? []) : nil

        // if 블럭: 기본 조건 pathBlocked (앞이 막혀있으면)
        self.ifCondition = (type == .ifBlock) ? (ifCondition ?? .pathBlocked) : nil
    }

    // MARK: - 헬퍼

    /// 자식 블럭 영역을 표시해야 하는 컨테이너 블럭 여부
    /// repeat / if / function 모두 자식 블럭을 가짐
    var hasChildren: Bool {
        type.isContainer
    }

    /// repeat 블럭 여부 확인 (반복 횟수 스테퍼 표시 조건)
    var isRepeatBlock: Bool {
        type == .repeatBlock
    }

    /// 실행 시 실제로 처리되는 총 블럭 수 (별점 계산용)
    /// 컨테이너 블럭은 자식 블럭 수만 카운트 (컨테이너 자체는 제외)
    var flatCount: Int {
        switch type {
        case .repeatBlock, .ifBlock, .functionBlock:
            // 자식 블럭들의 flatCount를 재귀적으로 합산
            return children?.reduce(0) { $0 + $1.flatCount } ?? 0
        default:
            // 일반 블럭은 1개로 카운트
            return 1
        }
    }
}

// MARK: - 블럭 트리 편집
// 코드 블럭 목록을 경로로 다루는 규칙 — 경로 형식은 [최상위], [최상위, 자식], [최상위, 자식, 손자], ...
extension Array where Element == Block {

    /// 경로에 있는 블럭 — 경로가 잘못됐으면 nil
    func block(at path: [Int]) -> Block? {
        var siblings = self
        var found: Block? = nil
        for index in path {
            guard siblings.indices.contains(index) else { return nil }
            found = siblings[index]
            siblings = siblings[index].children ?? []
        }
        return found
    }

    /// 경로의 컨테이너에 넣을 수 있는 블럭 — 스테이지 팔레트 안에서 중첩 규칙을 적용
    /// 규칙: function 중첩 불허, 동일 타입 중첩 불허, 증손자는 기본 동작 블럭만(4단 이상 중첩 방지)
    func allowedChildTypes(at path: [Int], palette: [BlockType]) -> [BlockType] {
        guard let parent = block(at: path), parent.hasChildren else { return [] }
        let isDeepestContainer = path.count >= 3
        return palette.filter { type in
            if type == .functionBlock || type == parent.type { return false }
            if isDeepestContainer && (type == .repeatBlock || type == .ifBlock) { return false }
            return true
        }
    }

    /// 경로의 컨테이너에 자식 블럭 추가 — 허용되지 않는 블럭은 무시
    mutating func addChild(_ type: BlockType, at path: [Int], palette: [BlockType]) {
        guard allowedChildTypes(at: path, palette: palette).contains(type) else { return }
        editBlock(at: path) { $0.children?.append(Block(type: type)) }
    }

    /// 경로의 블럭 삭제 (최상위·중첩 공용) — 경로가 잘못됐으면 무시
    mutating func removeBlock(at path: [Int]) {
        guard block(at: path) != nil, let index = path.last else { return }
        if path.count == 1 {
            remove(at: index)
        } else {
            editBlock(at: Array<Int>(path.dropLast())) { $0.children?.remove(at: index) }
        }
    }

    /// 경로의 if 블럭 조건 변경
    mutating func setIfCondition(_ condition: IfCondition, at path: [Int]) {
        guard block(at: path)?.type == .ifBlock else { return }
        editBlock(at: path) { $0.ifCondition = condition }
    }

    /// 경로의 repeat 블럭 반복 횟수 변경 (1~10회로 제한)
    mutating func setRepeatCount(_ count: Int, at path: [Int]) {
        guard block(at: path)?.isRepeatBlock == true else { return }
        editBlock(at: path) { $0.repeatCount = Swift.max(1, Swift.min(10, count)) }
    }

    /// 최상위 블럭 순서 변경 — destination은 옮기기 전 배열 기준의 삽입 위치 (0...count), 옮겼으면 true
    mutating func moveBlock(from source: Int, to destination: Int) -> Bool {
        guard indices.contains(source), (0...count).contains(destination) else { return false }
        let block = remove(at: source)
        // 앞쪽 블럭을 뺐으므로 그 뒤의 삽입 위치는 한 칸 당겨짐
        insert(block, at: destination > source ? destination - 1 : destination)
        return true
    }

    /// 경로의 블럭을 제자리에서 수정 — 경로가 잘못됐으면 무시
    private mutating func editBlock(at path: [Int], _ edit: (inout Block) -> Void) {
        guard let first = path.first, block(at: path) != nil else { return }
        self[first].edit(remainingPath: path.dropFirst(), edit)
    }
}

private extension Block {

    /// 트리를 따라 내려가 값 타입 블럭을 제자리에서 수정 (경로는 호출부에서 검증됨)
    mutating func edit(remainingPath: ArraySlice<Int>, _ edit: (inout Block) -> Void) {
        guard let next = remainingPath.first else {
            edit(&self)
            return
        }
        children![next].edit(remainingPath: remainingPath.dropFirst(), edit)
    }
}
