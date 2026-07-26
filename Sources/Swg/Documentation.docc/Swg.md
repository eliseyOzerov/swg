# ``Swg``

Parse, edit, convert, and display SVG content in Swift.

## Overview

`swg` is Swift Vector Graphics: a small, dependency-free Swift package for reading SVG documents and representing their structure, geometry, paint, metadata, and reusable definitions in Swift.

The package can display supported SVG geometry with ``SVGView``/``SWGView``, convert editable ``Path`` values into CoreGraphics paths, and let callers derive edited copies of an ``SVGDocument`` before rendering.

XML parsing is handled by Foundation's `XMLParser`, with `FoundationXML` imported where that platform separates XML support from the main Foundation module.

The parser/model coverage is broader than the native SwiftUI renderer. The renderer currently draws the path, basic-shape, container, nested viewport, and simple reuse subset that can map through CoreGraphics paths. Text, gradients, filters, masks, clipping, markers, raster images, and animation are preserved in the model but are not full native-renderer features yet.

## Display a Document

Use ``SVGView`` when you already have an ``SVGDocument``:

```swift
import SwiftUI
import Swg

struct IconPreview: View {
	let document: SVGDocument

	var body: some View {
		SWGView(document)
			.frame(width: 120, height: 120)
	}
}
```

You can also parse source directly at the view boundary:

```swift
let source = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
	<circle id="dot" cx="12" cy="12" r="6" fill="#336699"/>
</svg>
"""

let view = SVGView(svg: source)
```

``SVGRenderOptions`` controls SwiftUI layout content mode, root `preserveAspectRatio` override, and root opacity.

## Parse a Document

Create an ``SVGParser`` and parse either a `String` or `Data` value:

```swift
import Swg

let source = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
	<circle id="dot" cx="12" cy="12" r="6" fill="red"/>
</svg>
"""

guard let document = SVGParser().parse(source) else {
	return
}

print(document.viewBox)
print(document.elementIDs)
```

The result is an ``SVGDocument`` containing the root view box, element tree, definitions registry, language metadata, descriptive metadata, animations, scripts, and unknown attributes preserved for callers that need round-trip or diagnostic access.

## Control a Document

An ``SVGDocument`` is regular Swift data. Use ``SVGDocument/element(id:)`` to inspect a subtree, ``SVGDocument/modifyingElement(id:_:)`` to edit one element by `id`, and ``SVGDocument/mapElements(_:)`` to derive a new document by transforming every element recursively.

```swift
let highlighted = document.modifyingElement(id: "mark") { element in
	element.modifyingAttributes { attributes in
		attributes.stroke = .color(.red)
		attributes.strokeWidth = 3
		attributes.transform = attributes.transform.scaledBy(x: 1.15, y: 1.15)
	}
}

SWGView(highlighted)
```

## Inspect Elements

Top-level and nested SVG content is represented by ``SVGElement``. Each enum case carries a typed data record for the matching SVG construct:

```swift
for element in document.elements {
	switch element {
	case .path(let path):
		print(path.path.commands)
	case .rect(let rect):
		print(rect.path.commands)
	default:
		break
	}
}
```

Container elements such as groups, links, nested SVG viewports, switches, unknown containers, and foreign objects retain their children so callers can traverse the original hierarchy.

## Work with Paths

Use ``Path/init(svgPathData:)`` to parse SVG path data directly, or use shape path helpers such as ``SVGRectData/path``, ``SVGCircleData/path``, ``SVGEllipseData/path``, ``SVGLineData/path``, ``SVGPolylineData/path``, and ``SVGPolygonData/path`` to derive equivalent vector geometry.

```swift
let path = Path(svgPathData: "M0 0 L10 0 L10 10 Z")
let serialized = path.svgPathData()
let cgPath = path.cgPath
```

The public ``Path`` model is editable, serializable, and convertible to `CGPath` through ``Path/cgPath``.

## Style and Paint

Presentation attributes are collected in ``SVGPaintAttributes``. This includes fill and stroke paint, opacity, fill rules, line caps and joins, dash patterns, paint order, transforms, visibility, display, markers, clipping, masking, filters, rendering hints, vector effects, and pointer events.

SVG paint values are represented by ``SVGPaint`` and color data by ``Color``.

## Validation Strategy

Specification coverage is tracked in the repository checklist. Items are checked only when a focused test exists for the feature.

Render-affecting features also move through visual validation fixtures. See <doc:VisualValidation> for the fixture format and current raster comparison approach.

## Topics

### Parsing

- ``SVGParser``
- ``SVGDocument``
- ``SVGElement``

### SwiftUI Rendering

- ``SVGView``
- ``SWGView``
- ``SVGRenderOptions``

### Geometry and Paths

- ``Path``
- ``PathCommand``
- ``Point``
- ``Rect``
- ``Transform``

### Paint and Style

- ``SVGPaintAttributes``
- ``SVGPaint``
- ``Color``
- ``FillRule``
- ``LineCap``
- ``LineJoin``
- ``SVGPointerEvents``

### Definitions and Reuse

- ``SVGDefs``
- ``SVGUseData``
- ``SVGSymbolData``
- ``SVGMarkerDef``
- ``SVGClipPathDef``
- ``SVGMaskDef``

### Text, Metadata, and Animation

- ``SVGTextData``
- ``SVGTitleData``
- ``SVGDescriptionData``
- ``SVGMetadataData``
- ``SVGAnimationElement``
- ``SVGScriptData``

### Testing

- <doc:VisualValidation>
