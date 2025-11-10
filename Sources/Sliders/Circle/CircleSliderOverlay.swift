//
//  CircleSlider.swift
//  Properties
//
//  Created by Anton Heestand on 2021-09-09.
//

import SwiftUI

public struct CircleSliderOverlay: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    let metadata: CircleSliderMetadata
    let coordinateSpaceName: String
    
    public init(
        metadata: CircleSliderMetadata,
        coordinateSpaceName: String
    ) {
        self.metadata = metadata
        self.coordinateSpaceName = coordinateSpaceName
    }

    static var radius: CGFloat {
#if os(macOS)
        40
#else
        60
#endif
    }
    static var thickness: CGFloat {
#if os(macOS)
        20
#else
        40
#endif
    }
    
    public var body: some View {
        GeometryReader { geometry in
            if let anchorPoint: CGPoint = metadata.anchorPoint {
                ZStack {
                    if let data: CircleSliderMetadata.Data = metadata.data {
                        mainBody(data: data)
                    } else if metadata.isPressing {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                Circle()
                                    .opacity(0.1)
                            }
                            .mask(circleWithHole())
                    }
                    Group {
                        Circle()
                            .stroke()
                        Circle()
                            .stroke()
                            .padding(Self.thickness)
                    }
                    .opacity(0.2)
                }
                .offset(x: anchorPoint.x - geometry.frame(in: .named(coordinateSpaceName)).midX,
                        y: anchorPoint.y - geometry.frame(in: .named(coordinateSpaceName)).midY)
            }
        }
        .frame(width: Self.radius * 2,
               height: Self.radius * 2)
    }
    
    @ViewBuilder
    func mainBody(data: CircleSliderMetadata.Data) -> some View {
        
        var startAngle: Angle {
            data.startAngle
        }
        var currentAngle: Angle {
            data.currentAngle
        }
        var angle: Angle {
            startAngle + currentAngle
        }
        
        ZStack {
            /// Donut
            Circle()
                .fill(.ultraThinMaterial)
                .overlay {
                    Circle()
                        .opacity(0.1)
                }
                .mask(circleWithHole())
            /// Fill
            Group {
                /// Arc
                CircleSliderArcShape(
                    width: Self.thickness,
                    angle: narrow(angle: Angle(degrees: startAngle.degrees + angle.degrees) / 2.0),
                    length: Angle(degrees: abs(startAngle.degrees - angle.degrees))
                )
                /// Start Circle
                Circle()
                    .frame(width: Self.thickness, height: Self.thickness)
                    .offset(x: cos(startAngle.radians) * (Self.radius - Self.thickness / 2),
                            y: sin(startAngle.radians) * (Self.radius - Self.thickness / 2))
            }
            .foregroundColor(.accentColor)
            /// Current Circle
            Circle()
                .foregroundColor(.white)
                .overlay {
                    Circle()
                        .stroke()
                        .opacity(0.2)
                }
                .frame(width: Self.thickness, height: Self.thickness)
                .offset(x: cos(angle.radians) * (Self.radius - Self.thickness / 2),
                        y: sin(angle.radians) * (Self.radius - Self.thickness / 2))
        }
        .compositingGroup()
    }
    
    private func circleWithHole() -> some View {
        ZStack {
            Circle()
                .foregroundColor(.white)
            Circle()
                .foregroundColor(.black)
                .mask(
                    Circle()
                        .padding(Self.thickness)
                )
        }
        .compositingGroup()
        .luminanceToAlpha()
    }
    
    private func narrow(angle: Angle) -> Angle {
        var angle: Angle = angle
        if angle.degrees > 0.0 {
            if angle.degrees > 180 {
                angle -= Angle(degrees: 360)
            }
        } else if angle.degrees < 0.0 {
            if angle.degrees < -180 {
                angle += Angle(degrees: 360)
            }
        }
        return angle
    }
}

#Preview(traits: .fixedLayout(width: 200, height: 200)) {
    @Previewable @State var value: CGFloat = 0.0
    @Previewable @State var metadata: CircleSliderMetadata = .inactive
    let coordinateSpaceName: String = "circle-slider"
    ZStack {
        CircleSliderButton(
            id: "first",
            value: $value,
            valueScale: 1.0,
            metadata: $metadata,
            coordinateSpaceName: coordinateSpaceName,
            willChange: {},
            didChange: { _, _ in }
        )
        CircleSliderOverlay(
            metadata: metadata,
            coordinateSpaceName: coordinateSpaceName
        )
    }
    .frame(width: 200, height: 200)
    .coordinateSpace(name: coordinateSpaceName)
}
