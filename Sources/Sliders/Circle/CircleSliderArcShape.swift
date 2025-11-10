//
//  CircleSliderArcShape.swift
//  Sliders
//
//  Created by Anton Heestand on 2025-11-10.
//

import SwiftUI

struct CircleSliderArcShape: Shape {
    
    let width: CGFloat
    let angle: Angle
    let length: Angle
    
    func path(in rect: CGRect) -> Path {
        
        let outerRadius: CGFloat = min(rect.width, rect.height) / 2
        let innerRadius: CGFloat = outerRadius - width
        
        return Path { path in
            path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                        radius: innerRadius,
                        startAngle: angle - length / 2,
                        endAngle: angle + length / 2,
                        clockwise: false)
            path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                        radius: outerRadius,
                        startAngle: angle + length / 2,
                        endAngle: angle - length / 2,
                        clockwise: true)
        }
    }
}
