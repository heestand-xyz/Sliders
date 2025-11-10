//
//  CircleSliderMetadata.swift
//  Sliders
//
//  Created by Anton Heestand on 2025-11-10.
//

import SwiftUI

public struct CircleSliderMetadata: Equatable, Sendable {
    struct Data: Equatable, Sendable {
        let id: String
        var startAngle: Angle
        var currentAngle: Angle
    }
    public internal(set) var pressID: String?
    var isPressing: Bool {
        pressID != nil
    }
    var id: String? {
        data?.id ?? pressID
    }
    var data: Data?
    var anchorPoints: [String: CGPoint] = [:]
    var anchorPoint: CGPoint? {
        guard let id else { return nil }
        return anchorPoints[id]
    }
    public static let inactive: CircleSliderMetadata = .init()
    public static func press(id: String) -> CircleSliderMetadata {
        var metadata = CircleSliderMetadata()
        metadata.pressID = id
        return metadata
    }
    public init() {}
}
