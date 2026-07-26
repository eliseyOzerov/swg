# ``Swg``

Parse, edit, convert, and display SVG content in Swift.

## Overview

`swg` is Swift Vector Graphics: a small, dependency-free Swift package for reading SVG documents and representing their structure, geometry, paint, metadata, and reusable definitions in Swift.

The package can display supported SVG geometry with ``SVG``, convert editable ``Path`` values into CoreGraphics paths, and let callers derive edited copies of an ``SVGDocument`` before rendering.

XML parsing is handled by Foundation's `XMLParser`, with `FoundationXML` imported where that platform separates XML support from the main Foundation module.

The parser/model coverage is broader than the native SwiftUI renderer. The renderer currently draws the path, basic-shape, container, nested viewport, and simple reuse subset that can map through CoreGraphics paths. Text, gradients, filters, masks, clipping, markers, raster images, and animation are preserved in the model but are not full native-renderer features yet.

## Quick Start

Create an ``SVGParser`` and parse either a `String` or `Data` value. Pass the result to ``SVG`` to render supported SVG geometry in SwiftUI.

```swift
import SwiftUI
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

let view = SVG(document)
```

The result is an ``SVGDocument`` containing the root view box, element tree, definitions registry, language metadata, descriptive metadata, animations, scripts, and unknown attributes preserved for callers that need round-trip or diagnostic access.

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

## Validation Strategy

Specification coverage is tracked in the repository checklist. Items are checked only when a focused test exists for the feature.

Render-affecting features also move through visual validation fixtures. See <doc:VisualValidation> for the fixture format and current raster comparison approach.

## Topics

### Parsing

- ``SVGParser``
- ``SVGDocument``
- ``SVGElement``

### Essentials

- <doc:GettingStarted>
- <doc:RenderingSVG>
- <doc:ControllingDocuments>

### SwiftUI Rendering

- ``SVG``
- ``SVGRenderOptions``

### Geometry and Paths

- ``Path``
- ``PathCommand``
- ``Point``
- ``Rect``
- ``Transform``

### Paint Model

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
