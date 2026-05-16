//
//  Block.swift
//  Blocode
//
//  Created by 조준희 on 5/10/26.
//

import Foundation
import SwiftUI

// MARK: - BlockType
/// 코드 블럭의 종류를 정의하는 열거형
/// 실제 프로그래밍 언어의 기본 명령어와 1:1 대응
enum BlockType: String, Codable, CaseIterable {
    case moveForward  = "moveForward"   // 앞으로 이동
    case moveBackward = "moveBackward"  // 뒤로 이동
    case turnLeft     = "turnLeft"      // 왼쪽으로 90도 회전
    case turnRight    = "turnRight"     // 오른쪽으로 90도 회전
    case repeatBlock  = "repeat"        // 반복 (자식 블럭들을 N번 반복 실행)

    /// 화면에 표시할 블럭 이름 (한국어)
    var displayName: String {
        switch self {
        case .moveForward:  return "앞으로"
        case .moveBackward: return "뒤로"
        case .turnLeft:     return "왼쪽 회전"
        case .turnRight:    return "오른쪽 회전"
        case .repeatBlock:  return "반복"
        }
    }

    /// SF Symbols 아이콘 이름 — 블럭 행과 팔레트에서 사용
    var iconName: String {
        switch self {
        case .moveForward:  return "arrow.up"
        case .moveBackward: return "arrow.down"
        case .turnLeft:     return "arrow.counterclockwise"
        case .turnRight:    return "arrow.clockwise"
        case .repeatBlock:  return "repeat"
        }
    }

    /// 팔레트 카드에 표시할 짧은 이름
    var shortName: String {
        switch self {
        case .moveForward:  return "앞으로"
        case .moveBackward: return "뒤로"
        case .turnLeft:     return "왼쪽"
        case .turnRight:    return "오른쪽"
        case .repeatBlock:  return "반복"
        }
    }

    /// 블럭 고유 색상 — 프로토타입 파스텔 톤
    var blockColor: Color {
        switch self {
        case .moveForward:  return Color(red: 124/255, green: 196/255, blue: 158/255) // 민트 그린
        case .moveBackward: return Color(red: 207/255, green: 127/255, blue: 122/255) // 살먼 로즈
        case .turnLeft:     return Color(red: 142/255, green: 176/255, blue: 200/255) // 뮤트 블루
        case .turnRight:    return Color(red: 142/255, green: 176/255, blue: 200/255) // 뮤트 블루
        case .repeatBlock:  return Color(red: 168/255, green: 141/255, blue: 192/255) // 라벤더
        }
    }

    /// 연한 배경색 (블럭 행 하이라이트용) — 불투명도 12%로 적용
    var lightColor: Color {
        blockColor.opacity(0.12)
    }

    /// 최소화 칩에 쓸 작은 아이콘 (iconName과 동일하지만 alias로 명시)
    var shortIconName: String { iconName }
}

// MARK: - Block
/// 사용자가 코드 순서 영역에 추가하는 하나의 코드 블럭
struct Block: Identifiable, Codable {
    var id: UUID          // SwiftUI 리스트 식별자 — ForEach에서 고유 키로 사용
    var type: BlockType   // 블럭 종류 (이동/회전/반복)

    /// repeat 블럭일 때만 사용: 반복 횟수 (스테퍼로 조절, 기본값 2)
    var repeatCount: Int?

    /// repeat 블럭일 때만 사용: 반복 내부에 들어가는 자식 블럭 목록
    var children: [Block]?

    // MARK: - 초기화
    init(type: BlockType, repeatCount: Int? = nil, children: [Block]? = nil) {
        self.id = UUID()  // 항상 새로운 고유 ID 생성
        self.type = type
        // repeat 블럭이면 기본 반복 횟수 2로 설정, 아니면 nil
        self.repeatCount = (type == .repeatBlock) ? (repeatCount ?? 2) : nil
        // repeat 블럭이면 빈 자식 배열로 초기화, 아니면 nil
        self.children = (type == .repeatBlock) ? (children ?? []) : nil
    }

    // MARK: - 헬퍼

    /// repeat 블럭 여부 확인 — isRepeatBlock이 true일 때 자식 블럭 영역 표시
    var isRepeatBlock: Bool {
        return type == .repeatBlock
    }

    /// 실행 시 실제로 처리되는 총 블럭 수 (별점 계산용)
    /// repeat 블럭은 자식 블럭 수만 카운트 (repeat 블럭 자체는 제외)
    var flatCount: Int {
        switch type {
        case .repeatBlock:
            // 자식 블럭들의 flatCount를 재귀적으로 합산
            return children?.reduce(0) { $0 + $1.flatCount } ?? 0
        default:
            // 일반 블럭은 1개로 카운트
            return 1
        }
    }
}
