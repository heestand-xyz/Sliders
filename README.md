# Sliders

```swift
.package(url: "https://github.com/heestand-xyz/Sliders", from: "1.0.0")
```

## Incremental Slider

<img src="https://github.com/heestand-xyz/Sliders/blob/main/Assets/IncrementalSlider2.png" width="398"/>

> Default value is indicated by a circle.

> Out-of-bound values are indicated by chevrons.

<img src="https://github.com/heestand-xyz/Sliders/blob/main/Assets/IncrementalSlider1.png" width="397"/>

> Haptic feedback is run when the slider passes over an increment.

```swift
@State var value: CGFloat = 0.5

IncrementalSlider(
    value: $value,
    default: 0.5,
    minimum: 0.0,
    maximum: 1.0,
    increment: 0.25,
    willChange: {
        print("Value will change...")
    },
    didChange: { oldValue, newValue in
        print("Value did change from \(oldValue) to \(newValue)")
    }
)
```

## Circle Slider

<img src="https://github.com/heestand-xyz/Sliders/blob/main/Assets/CircleSlider1.png" width="77"/>

> Once pressed and dragged the circle slider appears, allowing relative adjustments in an angular way.

<img src="https://github.com/heestand-xyz/Sliders/blob/main/Assets/CircleSlider2.png" width="202"/> <img src="https://github.com/heestand-xyz/Sliders/blob/main/Assets/CircleSlider3.png" width="202"/>

```swift
let coordinateSpaceName: String = "circle-slider"

@State var value: CGFloat = 0.5
@State var metadata: CircleSliderMetadata = .inactive

ZStack {
    VStack {
        CircleSliderButton(
            value: $value,
            metadata: $metadata,
            coordinateSpace: .named(coordinateSpaceName),
            willChange: {
                print("Value will change...")
            },
            didChange: { oldValue, newValue in 
                print("Value did change from \(oldValue) to \(newValue)")
            }
        )
        // Other UI...
    }
    CircleSliderOverlay(
        metadata: metadata,
        coordinateSpace: .named(coordinateSpaceName)
    )
}
.coordinateSpace(name: coordinateSpaceName)
```

---

Created by [Anton Heestand](https://heestand.xyz)
