//
//  IncrementalSlider.swift
//
//
//  Created by Anton Heestand on 2021-04-24.
//

import SwiftUI

struct IncrementalSlider: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let defaultValue: CGFloat
    
    @Binding var relativeValue: CGFloat
        
    var willChange: () -> ()
    var didChangeRelativeValue: (CGFloat, CGFloat) -> ()

    let relativeZero: CGFloat
    
    let relativeIncrement: CGFloat?
    private var incrementCount: Int {
        guard let increment: CGFloat = relativeIncrement else { return 1 }
        guard increment != 0.0 else { return 1 }
        let count: CGFloat = 1.0 / increment
        return Int(round(count * 1_000) / 1_000)
    }
    private let incrementValueRadius: CGFloat = 0.025
    
    private var barHeight: CGFloat {
#if os(macOS)
        4
#else
        5
#endif
    }
    private var circleRadius: CGFloat {
#if os(macOS)
        10
#else
        15
#endif
    }
    private var incrementSpacing: CGFloat {
        barHeight * 0.75
    }
    
    @State private var isDragging: Bool = false
    @State private var atIncrementIndex: Int?
    @State private var startValue: CGFloat?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                
                Color(white: 0.5, opacity: 0.001)
                
                ZStack(alignment: .leading) {
                    
                    HStack(spacing: 0.0) {
                        ForEach(0..<incrementCount, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: barHeight / 2)
                                .opacity(0.1)
                                .padding(.horizontal, incrementSpacing / 2)
                        }
                    }
                    
                    Rectangle()
                        .frame(width: abs(min(max(relativeZero, 0.0), 1.0) - min(max(relativeValue, 0.0), 1.0)) * (geometry.size.width - circleRadius * 2))
                        .offset(x: min(max(min(relativeZero, relativeValue), 0.0), 1.0) * (geometry.size.width - circleRadius * 2))
                        .foregroundColor(.accentColor)
                        .frame(width: (geometry.size.width - circleRadius * 2), alignment: .leading)
                        .mask(
                            HStack(spacing: 0.0) {
                                ForEach(0..<incrementCount, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: barHeight / 2)
                                        .padding(.horizontal, incrementSpacing / 2)
                                }
                            }
                        )
                    
                }
                .frame(height: barHeight)
                .padding(.horizontal, circleRadius)
                
                circleContainer(size: geometry.size)
            }
            .gesture(dragGesture(size: geometry.size))
        }
        .frame(height: circleRadius * 2)
        .padding(1)
        .onTapGesture(count: 2) {
            relativeValue = defaultValue
        }
    }
    
    private func circleContainer(size: CGSize) -> some View {
        Group {
            if isDragging {
                circleContent
            } else {
                circleContent
#if !os(macOS)
                    .hoverEffect(.lift)
#endif
            }
        }
        .frame(width: circleRadius * 2,
               height: circleRadius * 2)
        .offset(x: min(max(relativeValue, 0.0), 1.0) * (size.width - circleRadius * 2))
    }
    
    private var circleContent: some View {
        Circle()
            .foregroundColor(Color(white: isDragging ? 0.95 : 1.0))
            .overlay {
                Circle()
                    .stroke()
                    .opacity(0.2)
            }
            .overlay {
                Group {
                    if relativeValue == defaultValue {
                        Circle()
                            .frame(width: circleRadius / 1.5,
                                   height: circleRadius / 1.5)
                    } else {
                        Group {
                            if relativeValue < 0.0 {
                                Image(systemName: "chevron.left")
                            } else if relativeValue > 1.0 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .imageScale(.small)
                        .fontWeight(.black)
                    }
                }
                .foregroundColor(Color(white: 0.75))
            }
    }
    
    private func dragGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                if !isDragging {
                    guard abs(value.translation.width) > 10 else { return }
                    startValue = relativeValue
                    isDragging = true
                    willChange()
                }
                var value: CGFloat = (value.location.x - circleRadius) / (size.width - circleRadius * 2)
                value = min(max(value, 0.0), 1.0)
                if let incrementIndex: Int = findIncrementIndex(value) {
                    if atIncrementIndex != incrementIndex {
                        atIncrementIndex = incrementIndex
                        setIncrement(index: incrementIndex)
                    }
                } else {
                    if atIncrementIndex != nil {
                        atIncrementIndex = nil
                    }
                    set(value: value)
                }
            }
            .onEnded { _ in
                if let startValue: CGFloat = startValue {
                    didChangeRelativeValue(startValue, relativeValue)
                }
                isDragging = false
                startValue = nil
            }
    }
    
    private func set(value: CGFloat) {
        relativeValue = value
    }
    
    private func setIncrement(index: Int) {
        relativeValue = incrementValue(index: index)
#if os(macOS)
        NSHapticFeedbackManager.defaultPerformer
            .perform(.generic, performanceTime: .now)
#elseif os(iOS)
        UIImpactFeedbackGenerator(style: .light)
            .impactOccurred()
#endif
    }
    
    private func findIncrementIndex(_ value: CGFloat) -> Int? {
        for index in 0...incrementCount {
            let incrementValue: CGFloat = CGFloat(index) / CGFloat(incrementCount)
            if value > incrementValue - incrementValueRadius && value < incrementValue + incrementValueRadius {
                return index
            }
        }
        return nil
    }
    
    private func incrementValue(index: Int) -> CGFloat {
        CGFloat(index) * (1.0 / CGFloat(incrementCount))
    }
}

#Preview(traits: .fixedLayout(width: 200, height: 1000)) {
    @Previewable @State var value: CGFloat = 0.5
    ScrollView {
        Group {
            Text("Live")
                .bold()
            IncrementalSlider(defaultValue: 0.5, relativeValue: $value, willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 0.0, relativeIncrement: 0.25)
        }
        Divider()
        Group {
            Text("Zero at -0.5")
                .bold()
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(-0.25), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: -0.5, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(0.0), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: -0.5, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(0.25), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: -0.5, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(0.5), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: -0.5, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(0.75), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: -0.5, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(1.0), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: -0.5, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(1.25), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: -0.5, relativeIncrement: 0.25)
        }
        Divider()
        Group {
            Text("Zero at 0.0")
                .bold()
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(-0.25), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 0.0, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(0.0), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 0.0, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(0.25), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 0.0, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(0.5), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 0.0, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(0.75), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 0.0, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(1.0), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 0.0, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(1.25), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 0.0, relativeIncrement: 0.25)
        }
        Divider()
        Group {
            Text("Zero at 0.5")
                .bold()
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(-0.25), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 0.5, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(0.0), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 0.5, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(0.25), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 0.5, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(0.5), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 0.5, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(0.75), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 0.5, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(1.0), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 0.5, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(1.25), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 0.5, relativeIncrement: 0.25)
        }
        Divider()
        Group {
            Text("Zero at 1.0")
                .bold()
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(-0.25), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 1.0, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(0.0), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 1.0, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(0.25), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 1.0, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(0.5), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 1.0, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(0.75), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 1.0, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(1.0), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 1.0, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(1.25), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 1.0, relativeIncrement: 0.25)
        }
        Divider()
        Group {
            Text("Zero at 1.5")
                .bold()
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(-0.25), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 1.5, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(0.0), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 1.5, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(0.25), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 1.5, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(0.5), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 1.5, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(0.75), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 1.5, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(1.0), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 1.5, relativeIncrement: 0.25)
            IncrementalSlider(defaultValue: 0.0, relativeValue: .constant(1.25), willChange: {}, didChangeRelativeValue: { _, _ in }, relativeZero: 1.5, relativeIncrement: 0.25)
        }
    }
    .padding(10)
}
