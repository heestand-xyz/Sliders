//
//  CircleSliderButton.swift
//  Sliders
//
//  Created by Anton Heestand on 2025-11-10.
//

import SwiftUI

public struct CircleSliderButton: View {
    
    let id: String
    
    @Binding var value: CGFloat
    let valueScale: CGFloat

    @Binding var metadata: CircleSliderMetadata

    let coordinateSpaceName: String

    var didStart: () -> ()
    var didEnd: (CGFloat, CGFloat) -> ()
    
    public init(
        id: String,
        value: Binding<CGFloat>,
        valueScale: CGFloat = 1.0,
        metadata: Binding<CircleSliderMetadata>,
        coordinateSpaceName: String,
        willChange: @escaping () -> Void = {},
        didChange: @escaping (CGFloat, CGFloat) -> Void = { _, _ in}
    ) {
        self.id = id
        _value = value
        self.valueScale = valueScale
        _metadata = metadata
        self.coordinateSpaceName = coordinateSpaceName
        self.didStart = willChange
        self.didEnd = didChange
    }
    
    @State private var isHovering: Bool = false
    @State private var isPressing: Bool = false
    
    @State private var startValue: CGFloat?
    @State private var lastAngle: Angle?
    
    @State private var gestureState = GestureState<Bool?>()
    
    public var body: some View {
        Group {
            if isPressing {
                Circle()
                    .foregroundColor(.white)
            } else {
                ZStack {
                    Circle()
                        .foregroundColor(.accentColor)
                    Circle()
                        .foregroundStyle(.white)
                        .padding(isHovering ? CircleSliderOverlay.thickness / 6 : CircleSliderOverlay.thickness / 4)
                        .animation(.easeInOut(duration: 0.1), value: isHovering)
                }
            }
        }
        .frame(width: CircleSliderOverlay.thickness,
               height: CircleSliderOverlay.thickness)
        .opacity(metadata.data?.id == id ? 0.0 : 1.0)
        .onGeometryChange(for: CGPoint.self) { geometry in
            let frame = geometry.frame(in: .named(coordinateSpaceName))
            return CGPoint(x: frame.midX, y: frame.midY)
        } action: { newPoint in
            metadata.anchorPoints[id] = newPoint
        }
        .padding(8)
        .contentShape(.circle)
        .gesture(dragGesture)
        .simultaneousGesture(pressGesture)
        .onHover { active in
            isHovering = active
        }
        .padding(-8)
        .accessibilityLabel("Circle Slider")
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let angle = Angle(radians: atan2(value.translation.height, value.translation.width))
                if metadata.data == nil {
                    metadata.data = CircleSliderMetadata.Data(id: id, startAngle: angle, currentAngle: .zero)
                    startValue = self.value
                    didStart()
                } else if let data = metadata.data, lastAngle != nil, let startValue {
                    guard data.id == id else { return }
                    let relativeAngle: Angle = narrow(angle: angle - lastAngle!)
                    let currentAngle: Angle = metadata.data!.currentAngle + relativeAngle
                    metadata.data!.currentAngle = currentAngle
                    self.value = startValue + (currentAngle.degrees / 360) * valueScale
                }
                guard metadata.data?.id == id else { return }
                lastAngle = angle
            }
            .onEnded { _ in
                guard let data = metadata.data, data.id == id else { return }
                if let startValue: CGFloat = startValue {
                    let value: CGFloat = (data.currentAngle.degrees / 360) * valueScale
                    didEnd(startValue, value)
                }
                metadata.data = nil
                startValue = nil
                lastAngle = nil
            }
    }
    
    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0.0)
            .onChanged { value in
                if !isPressing {
                    isPressing = true
                    metadata.pressID = id
                }
            }
            .onEnded { _ in
                isPressing = false
                if metadata.pressID == id {
                    metadata.pressID = nil
                }
            }
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
