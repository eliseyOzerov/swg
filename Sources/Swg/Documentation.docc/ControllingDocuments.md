# Controlling Documents

Derive edited SVG documents from application state before rendering.

## Overview

An ``SVGDocument`` is value data. You can parse an SVG once, keep it as your source model, and derive modified copies for SwiftUI state changes.

```swift
let highlighted = document.modifyingElement(id: "mark") { element in
	element.modifyingAttributes { attributes in
		attributes.stroke = .color(.red)
		attributes.strokeWidth = 3
	}
}

SVG(highlighted)
```

You can also ask ``SVG`` to load from a URL, bundled asset, or file and store the parsed document into a binding:

```swift
struct RemoteIcon: View {
	let iconURL: URL
	@State private var document: SVGDocument?

	var body: some View {
		SVG(url: iconURL, document: $document)
			.onChange(of: document) { _, document in
				guard let document else { return }
				self.document = document.modifyingElement(id: "mark") { element in
					element.modifyingAttributes { attributes in
						attributes.stroke = .color(.red)
					}
				}
			}
	}
}
```

## Find Elements

Use ``SVGDocument/element(id:)`` to find the first matching element anywhere in the render tree:

```swift
if let element = document.element(id: "mark") {
	print(element.elementID)
}
```

The lookup includes top-level elements and descendants of groups, links, nested SVG viewports, switches, unknown containers, and foreign objects.

## Edit One Element

Use ``SVGDocument/modifyingElement(id:_:)`` when a control, hover state, selection, or animation state targets one known SVG `id`:

```swift
let selected = document.modifyingElement(id: "badge") { element in
	element.modifyingAttributes { attributes in
		attributes.fill = .color(.blue)
		attributes.opacity = 1
	}
}
```

``SVGElement/modifyingAttributes(_:)`` preserves the element's geometry and children while returning a copy with edited presentation attributes.

## Map the Tree

Use ``SVGDocument/mapElements(_:)`` to apply a broad change recursively:

```swift
let muted = document.mapElements { element in
	element.modifyingAttributes { attributes in
		attributes.opacity *= 0.5
	}
}
```

For in-place updates to a stored variable, use ``SVGDocument/updateElements(_:)``.

## Keep Source and State Separate

In SwiftUI, a practical pattern is to keep the parsed document stable and derive a rendered document from view state:

```swift
struct StatefulIcon: View {
	let source: SVGDocument
	var isSelected: Bool

	var body: some View {
		SVG(renderedDocument)
	}

	private var renderedDocument: SVGDocument {
		source.modifyingElement(id: "mark") { element in
			element.modifyingAttributes { attributes in
				attributes.stroke = .color(isSelected ? .red : .blue)
			}
		}
	}
}
```
