# Getting Started

Parse an SVG string, display it in SwiftUI, and convert its geometry when you need CoreGraphics.

## Overview

`swg` starts with an SVG source string or data value. ``SVGParser`` turns that source into an ``SVGDocument``, which you can inspect, edit, convert to paths, or pass directly to ``SVGView``.

```swift
import SwiftUI
import Swg

let source = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
	<circle id="dot" cx="12" cy="12" r="6" fill="#336699"/>
</svg>
"""

guard let document = SVGParser().parse(source) else {
	fatalError("Invalid SVG")
}
```

## Display the Document

Use ``SWGView`` or ``SVGView`` in SwiftUI:

```swift
struct IconPreview: View {
	let document: SVGDocument

	var body: some View {
		SWGView(document)
			.frame(width: 120, height: 120)
	}
}
```

If parsing belongs at the view boundary, construct the view directly from SVG source:

```swift
let view = SVGView(svg: source)
```

## Inspect the Tree

The document exposes its root viewport, parsed elements, reusable definitions, metadata, scripts, and animation records:

```swift
print(document.viewBox)
print(document.elementIDs)
```

Use ``SVGDocument/element(id:)`` to find a nested element without writing your own traversal.

## Convert Geometry

Path data and basic shapes expose editable ``Path`` values. Convert those paths to CoreGraphics when you need a platform drawing primitive:

```swift
if case .circle(let circle)? = document.element(id: "dot") {
	let cgPath = circle.path.cgPath
	print(cgPath.boundingBox)
}
```

## Current Renderer Scope

The parser/model coverage is broader than the native SwiftUI renderer. The renderer currently draws paths, basic shapes, containers, nested SVG viewports, simple reuse, and basic fill/stroke paint. More advanced SVG paint and effects are preserved in the model while renderer support grows.
