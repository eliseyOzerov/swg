# Rendering SVG

Display parsed SVG documents with the package's native SwiftUI renderer.

## Overview

``SVG`` is a SwiftUI `View` backed by a parsed ``SVGDocument``. It maps the document's root ``SVGDocument/viewBox`` into the SwiftUI layout size, then draws supported elements through the package's ``Path`` to `CGPath` conversion.

```swift
SVG(document)
	.frame(width: 96, height: 96)
```

## Render from Source

Use ``SVG/init(source:parser:options:)`` for compact preview or asset-loading code where the source and view live together:

```swift
let icon = SVG(source: """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
	<path d="M4 12 L10 18 L20 6" fill="none" stroke="blue"/>
</svg>
""")
```

If parsing failure should be surfaced to users or logs, parse with ``SVGParser`` first and handle the optional document explicitly.

## Load After Appearance

Use ``SVG/init(url:document:options:)`` to load SVG XML from a network URL:

```swift
SVG(url: URL(string: "https://example.com/icons/check.svg")!)
```

Use ``SVG/init(_:bundle:document:options:)`` to load a bundled SVG resource by name or relative path:

```swift
SVG("checkmark")
SVG("Icons/checkmark.svg", bundle: .main)
```

Use the file URL or filesystem path initializers to load cached or downloaded SVG XML from the app's filesystem:

```swift
SVG(file: cachedSVGURL)
SVG(file: cachedSVGPath)
```

Each loading initializer has a `document` binding variant. The parsed document is written into the binding after loading so callers can inspect or modify it:

```swift
struct RemoteIcon: View {
	let iconURL: URL
	@State private var document: SVGDocument?

	var body: some View {
		SVG(url: iconURL, document: $document)
	}
}
```

## Configure Rendering

``SVGRenderOptions`` controls the root rendering pass:

```swift
SVG(
	document,
	options: SVGRenderOptions(
		contentMode: .fit,
		preserveAspectRatio: .default,
		opacity: 0.8
	)
)
```

Use `contentMode` for SwiftUI layout behavior, `preserveAspectRatio` to override the document root mapping, and `opacity` to apply an overall alpha multiplier.

## Supported Native Drawing

The native renderer currently draws:

- ``SVGPathData`` through SVG path data.
- ``SVGRectData``, ``SVGCircleData``, ``SVGEllipseData``, ``SVGLineData``, ``SVGPolygonData``, and ``SVGPolylineData`` through shape path helpers.
- ``SVGGroupData``, ``SVGSwitchData``, ``SVGLinkData``, ``SVGViewportData``, ``SVGForeignObjectData``, and ``SVGUnknownElementData`` as renderable containers.
- Simple ``SVGUseData`` references to reusable elements and symbols.
- Solid fill and stroke paint, fill opacity, stroke opacity, fill rules, stroke width, line caps, line joins, dash arrays, paint order, opacity, display, visibility, and transforms.

The parser also preserves text, gradients, patterns, masks, clipping, filters, markers, images, metadata, scripts, and animation records. Basic linear gradients, radial gradients, spread methods, and pattern fills render natively; the rest remains available in the model even when the SwiftUI renderer skips or simplifies the visual behavior.

## Use CoreGraphics Directly

Call ``Path/cgPath`` when you want to build a renderer, hit-test geometry, or feed parsed SVG paths into another drawing stack:

```swift
let path = Path(svgPathData: "M0 0 H10 V10 Z")
let cgPath = path.cgPath
```

The geometry bridge also includes CoreGraphics conversions for ``Point``, ``Rect``, ``Transform``, ``Color``, ``LineCap``, and ``LineJoin``.
