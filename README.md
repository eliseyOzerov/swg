# swg

Swift Vector Graphics. `swg` is an independent Swift package for parsing SVG files into a strongly typed model that can feed `CGPath` conversion and, over time, an `SWG` SwiftUI view.

The package has no third-party dependencies. XML parsing uses Foundation's `XMLParser`, with `FoundationXML` imported on platforms where that module is split out.

## Status

The parser is built around the SVG 2 specification and is tracked by a test-gated checklist in [TODO.md](TODO.md). A checklist item is checked only when there is a focused test for that feature.

Current coverage is parser/model coverage, not full browser-equivalent rendering. The gallery below shows the visual TODO groups with SVG examples that are parsed by `swg` and rasterized to PNG by a Swift playground.

## Supported Feature Gallery

These images are generated from SVG files in `docs/feature-gallery/svg` by `docs/FeatureGallery.playground/Contents.swift`. The playground parses each SVG with `swg`, then uses macOS Quick Look to rasterize the SVG and writes PNGs to `docs/feature-gallery/png`.

Parser support is broader than this gallery; see [TODO.md](TODO.md) for the full test-gated checklist. Non-visual items such as metadata selection, script preservation, pointer-event values, and raw animation timing records stay in focused tests rather than being treated as visual output.

### Document, Viewport, and Container Features

Supported here: nested `<svg>` viewports, `viewBox`, `preserveAspectRatio`, `<g>`, `<defs>`, `<symbol>`, `<use>`, `<switch>`, and `<a>`.

<p>
	<img src="docs/feature-gallery/png/viewports-containers.png" alt="Rendered SVG viewport, container, defs, symbol, use, switch, and link example" width="320">
</p>

### Basic Shapes

Supported here: `<rect>`, rounded rectangles, `<circle>`, `<ellipse>`, `<line>`, `<polyline>`, `<polygon>`, fills, strokes, line caps, and line joins.

<p>
	<img src="docs/feature-gallery/png/shapes-basic.png" alt="Rendered SVG basic shapes example" width="320">
	<img src="docs/feature-gallery/png/shapes-rounded-polygons.png" alt="Rendered SVG rounded rectangles and polygons example" width="320">
</p>

### Path Data

Supported here: `M`, `L`, `H`, `V`, `C`, `S`, `Q`, `T`, `A`, `Z`, implicit close/fill behavior, and `fill-rule="evenodd"`.

<p>
	<img src="docs/feature-gallery/png/path-lines-curves.png" alt="Rendered SVG path lines and curves example" width="320">
	<img src="docs/feature-gallery/png/path-arcs-fillrule.png" alt="Rendered SVG arcs and even-odd fill rule example" width="320">
</p>

### Coordinate Systems, Transforms, and Style

Supported here: transform list ordering, `matrix`, `translate`, `scale`, `rotate`, centered rotation, `skewX`, `skewY`, inherited presentation attributes, inline `style`, `<style>`, and media-filtered style rules.

<p>
	<img src="docs/feature-gallery/png/transforms-style.png" alt="Rendered SVG transforms, style, and inheritance example" width="320">
</p>

### Paint and Strokes

Supported here: solid color fill, `fill-opacity`, `fill-rule`, stroke paint, `stroke-width`, `stroke-opacity`, `stroke-linecap`, `stroke-linejoin`, `stroke-miterlimit`, `stroke-dasharray`, `stroke-dashoffset`, `paint-order`, `color`, and rendering hint values.

<p>
	<img src="docs/feature-gallery/png/paint-fill-opacity.png" alt="Rendered SVG fill and opacity example" width="320">
	<img src="docs/feature-gallery/png/paint-strokes.png" alt="Rendered SVG stroke styling example" width="320">
</p>

### Gradients and Patterns

Supported here: `<linearGradient>`, `<radialGradient>`, `<stop>`, `stop-color`, `stop-opacity`, `gradientUnits`, `gradientTransform`, `spreadMethod`, `<pattern>`, and `patternContentUnits`.

<p>
	<img src="docs/feature-gallery/png/gradients-patterns.png" alt="Rendered SVG gradients and pattern example" width="320">
</p>

### Clipping, Masking, and Compositing

Supported here: `<clipPath>`, `clip-path`, `clip-rule`, `clipPathUnits`, `<mask>`, `mask`, `maskUnits`, `maskContentUnits`, and `opacity`.

<p>
	<img src="docs/feature-gallery/png/clip-mask-composite.png" alt="Rendered SVG clipping, masking, and opacity compositing example" width="320">
</p>

### Filters

Supported here: `<filter>`, `filterUnits`, `primitiveUnits`, `<feGaussianBlur>`, `<feDropShadow>`, `<feBlend>`, `<feColorMatrix>`, `<feComponentTransfer>`, `<feFuncR>`, `<feFuncG>`, `<feFuncB>`, `<feFuncA>`, `<feComposite>`, `<feConvolveMatrix>`, `<feDiffuseLighting>`, `<feDisplacementMap>`, `<feDistantLight>`, `<feFlood>`, `<feImage>`, `<feMerge>`, `<feMergeNode>`, `<feMorphology>`, `<feOffset>`, `<fePointLight>`, `<feSpecularLighting>`, `<feSpotLight>`, `<feTile>`, and `<feTurbulence>`.

<p>
	<img src="docs/feature-gallery/png/filters.png" alt="Rendered SVG filter effects example" width="320">
</p>

### Text

Supported here: `<text>`, `<tspan>`, `<textPath>`, text `x`, `y`, `dx`, `dy`, `rotate`, `text-anchor`, `dominant-baseline`, `alignment-baseline`, and `white-space`.

<p>
	<img src="docs/feature-gallery/png/text.png" alt="Rendered SVG text, tspan, rotated text, anchored text, and textPath example" width="320">
</p>

### Reuse, Linking, and Markers

Supported here: `href`, `xlink:href`, `<marker>`, `marker-start`, `marker-mid`, `marker-end`, `orient`, `markerUnits`, and marker `viewBox`.

<p>
	<img src="docs/feature-gallery/png/reuse-markers.png" alt="Rendered SVG symbol reuse and markers example" width="320">
</p>

### Embedded and Dynamic SVG

Visual/model coverage here: `<foreignObject>`, `<animate>`, `<animateMotion>`, `<animateTransform>`, `<set>`, `<discard>`, and `<mpath>`. Related non-visual checked items such as timing attributes, value control attributes, additive/accumulate records, `<script>`, and `pointer-events` remain covered by focused parser tests.

<p>
	<img src="docs/feature-gallery/png/embedded-animation.png" alt="Rendered SVG foreignObject and dynamic SVG example" width="320">
</p>

## Installation

Add `swg` to a Swift Package:

```swift
dependencies: [
	.package(url: "https://github.com/eliseyOzerov/swg.git", branch: "main"),
]
```

Then add the product to your target:

```swift
.target(
	name: "YourTarget",
	dependencies: [
		.product(name: "Swg", package: "swg"),
	]
)
```

## Parsing

Use `SVGParser` to turn SVG XML into an `SVGDocument`:

```swift
import Swg

let source = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
	<path id="mark" d="M4 12 L10 18 L20 6" fill="none" stroke="blue"/>
</svg>
"""

guard let document = SVGParser().parse(source) else {
	return
}

print(document.viewBox)
print(document.elementIDs)
```

`SVGDocument` exposes the root view box, root elements, definitions, metadata, animation records, scripts, and preserved unknown attributes. The element tree is represented by `SVGElement`, with typed data records for shapes, containers, text, images, links, definitions, filters, gradients, patterns, masks, clips, and other SVG constructs.

## Paths

SVG path data is parsed into the package's editable `Path` model:

```swift
let path = Path(svgPathData: "M0 0 H10 V10 Z")
let roundTripped = path.svgPathData()
```

Shape data types that have direct geometry can also expose equivalent paths:

```swift
if case .rect(let rect) = document.elements.first {
	let path = rect.path
	print(path.commands)
}
```

These helpers are the bridge toward platform renderers. The package model is platform-neutral; CoreGraphics conversion currently lives in tests as validation scaffolding rather than public API.

## Styling

Paint and presentation attributes are collected in `SVGPaintAttributes`. The parser handles presentation attributes, inline style declarations, basic cascade/inheritance behavior, transform lists, colors, paint references, opacity, fill rules, stroke properties, markers, clipping, masks, filters, rendering hints, visibility, display, vector effects, and pointer events.

## Validation

Run the package's iOS simulator test gate with:

```sh
xcodebuild test -scheme swg -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

The suite contains focused parser/model tests plus fixture-backed visual tests.

## Visual Tests

Visual validation lives in `Tests/SwgTests/SVGVisualValidationTests.swift`. Each visual case pairs an SVG fixture with a text golden:

| Test | Expected raster |
| --- | --- |
| `basic-paint` | ![Basic paint expected raster](docs/visual-tests/basic-paint-preview.svg) |
| `transforms` | ![Transforms expected raster](docs/visual-tests/transforms-preview.svg) |

```text
Tests/SwgTests/VisualFixtures/basic-paint.svg
Tests/SwgTests/VisualFixtures/basic-paint.golden.txt
```

The test rasterizer parses the SVG, renders the supported visual subset into a deterministic CoreGraphics bitmap with antialiasing disabled, then compares the output against the golden rows. Golden files are written top-to-bottom in SVG/user-space order.

Golden symbols:

```text
. transparent
W white
R red
G green
B blue
? opaque color outside the named buckets
```

Current starter fixtures cover basic paint and transform behavior. The supported feature gallery above is generated from larger documentation examples; these visual tests stay intentionally tiny so they are easy to diff as regression fixtures. As rendering support grows, render-affecting spec items should receive visual fixtures in addition to their focused parser tests. Purely structural or metadata features can stay parser-only unless they affect rendered output.

## Documentation

API and conceptual reference lives in the DocC catalog at `Sources/Swg/Documentation.docc`. In Xcode, build documentation for the `swg` scheme to browse the module reference.
