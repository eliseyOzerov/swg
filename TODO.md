# swg SVG Coverage TODO

`swg` aims to load an SVG file, parse it into an inspectable Swift model, convert supported vector content into `CGPath`, and expose a SwiftUI `SwgView`.

This checklist is test-gated: only mark an item `- [x]` when there is at least one focused test proving that feature. Existing code without a focused test stays unchecked.

Primary references:

- SVG 2 specification: https://www.w3.org/TR/SVG/
- SVG 2 element index: https://www.w3.org/TR/SVG/eltindex.html
- SVG 2 attribute index: https://www.w3.org/TR/SVG/attindex.html
- SVG 2 property index: https://www.w3.org/TR/SVG/propidx.html

## Product Milestones

- [ ] Parse SVG file data from `Data`, `String`, local URL, and bundle resource.
- [ ] Preserve an inspectable `SVGDocument` tree with definitions, metadata, styling, and unsupported nodes.
- [ ] Convert supported static vector shapes into one or more `CGPath` values.
- [ ] Convert supported static vector shapes plus paint into a render plan for SwiftUI.
- [ ] Provide `SwgView` for SwiftUI rendering.
- [ ] Provide snapshot or pixel tests for `SwgView`.
- [ ] Provide conformance fixture tests from real SVG files.
- [ ] Provide error reporting that identifies unsupported SVG features without silently corrupting output.

## Current Tested Coverage

- [x] Parse SVG XML with Foundation `XMLParser`.
- [x] Parse root `svg` `viewBox`.
- [ ] Parse root `svg` `width` and `height` fallback through document parsing.
- [x] Parse `<g>` as a grouped element.
- [x] Parse `transform="translate(...)"` on a group.
- [x] Parse `<style>` class rules.
- [x] Apply class-based `fill` style to a path.
- [x] Apply class-based `stroke-width` style to a path.
- [x] Parse `<linearGradient>` with `<stop>` children.
- [x] Parse SVG path data relative `h`, `v`, and `l` commands.
- [x] Parse SVG path data closepath `z`.
- [x] Parse SVG path data smooth cubic `S` reflection.
- [x] Convert SVG path data elliptical arc `A` commands into cubic path commands.
- [x] Serialize editable path commands back to SVG path data.
- [x] Create `SVGPathData` from an editable `Path`.

## Core Parsing Infrastructure

- [ ] XML namespaces, including default SVG namespace and `xlink`.
- [ ] XML entity handling.
- [ ] XML comments and processing instructions.
- [ ] Unknown element preservation.
- [ ] Unknown attribute preservation.
- [ ] Parser diagnostics with line and column.
- [ ] Whitespace normalization rules.
- [ ] `xml:space`.
- [ ] `lang` and `xml:lang`.
- [ ] `id` uniqueness diagnostics.
- [ ] URL reference resolution.
- [ ] Fragment references.
- [ ] External resource references.
- [ ] Data URI references.
- [ ] Error handling for malformed SVG.

## Basic Data Types

- [ ] Number parsing, including signs, decimals, and exponents.
- [ ] Integer parsing.
- [ ] Length parsing without units.
- [ ] Absolute length units: `px`, `pt`, `pc`, `mm`, `cm`, `in`.
- [ ] Font-relative length units: `em`, `ex`, `ch`, `rem`.
- [ ] Viewport-relative length units: `vw`, `vh`, `vmin`, `vmax`.
- [ ] Percentage lengths.
- [ ] Angle units: `deg`, `grad`, `rad`, `turn`.
- [ ] Time units for animations.
- [ ] Frequency units.
- [ ] List parsing with comma and whitespace separators.
- [ ] Paint value parsing.
- [ ] IRI and functional IRI parsing.
- [ ] Preserve invalid values for diagnostics.

## Document and Container Elements

- [ ] `<svg>` nested viewport behavior.
- [ ] `<svg>` `x`, `y`, `width`, `height`.
- [ ] `<svg>` `viewBox`.
- [ ] `<svg>` `preserveAspectRatio`.
- [ ] `<g>`.
- [ ] `<defs>`.
- [ ] `<symbol>`.
- [ ] `<use>`.
- [ ] `<switch>`.
- [ ] `<view>`.
- [ ] `<a>`.
- [ ] `<title>`.
- [ ] `<desc>`.
- [ ] `<metadata>`.
- [ ] `<unknown>` / foreign unknown SVG elements.

## Basic Shapes to Path

- [ ] `<path>` element.
- [ ] `<rect>` element.
- [ ] `<rect>` rounded corners with `rx`.
- [ ] `<rect>` rounded corners with `ry`.
- [ ] `<circle>` element.
- [ ] `<ellipse>` element.
- [ ] `<line>` element.
- [ ] `<polyline>` element.
- [ ] `<polygon>` element.
- [ ] Geometry properties as CSS properties for `x`, `y`, `cx`, `cy`, `r`, `rx`, `ry`, `width`, `height`.

## Path Data

- [x] `M` / `m` moveto through relative-line fixture.
- [x] `L` / `l` lineto through relative-line fixture.
- [x] `H` / `h` horizontal lineto.
- [x] `V` / `v` vertical lineto.
- [x] `C` / `c` cubic Bezier.
- [x] `S` / `s` smooth cubic Bezier.
- [ ] `Q` / `q` quadratic Bezier.
- [ ] `T` / `t` smooth quadratic Bezier.
- [x] `A` / `a` elliptical arc.
- [x] `Z` / `z` closepath.
- [ ] Implicit repeated commands after `M`.
- [ ] Implicit repeated commands for non-`M` commands.
- [ ] Compact number tokenization such as `M10-20`.
- [ ] Exponent tokenization.
- [ ] Arc large-arc and sweep flag combinations.
- [ ] Arc radius correction.
- [ ] Degenerate arc handling.
- [ ] Path data error recovery.
- [ ] Path bounds.
- [ ] Path transform application.
- [ ] Path to `CGPath`.

## Coordinate Systems and Transforms

- [ ] User coordinate system.
- [ ] Viewport coordinate system.
- [ ] `viewBox` to viewport transform.
- [ ] `preserveAspectRatio` `none`.
- [ ] `preserveAspectRatio` meet.
- [ ] `preserveAspectRatio` slice.
- [ ] `transform` list ordering.
- [ ] `matrix`.
- [x] `translate`.
- [ ] `scale`.
- [ ] `rotate(angle)`.
- [ ] `rotate(angle cx cy)`.
- [ ] `skewX`.
- [ ] `skewY`.
- [ ] Transform inheritance.
- [ ] Gradient transforms.
- [ ] Pattern transforms.
- [ ] Vector-effect transforms.

## Styling and Cascade

- [ ] Presentation attributes.
- [ ] Inline `style` attribute.
- [x] `<style>` element class selector.
- [ ] Type selectors.
- [ ] ID selectors.
- [ ] Multiple classes.
- [ ] Selector specificity.
- [ ] Inheritance.
- [ ] CSS custom properties.
- [ ] `inherit`.
- [ ] `initial`.
- [ ] `unset`.
- [ ] `currentColor`.
- [ ] Media queries.
- [ ] Style parse diagnostics.

## Painting

- [ ] `fill`.
- [ ] `fill-opacity`.
- [ ] `fill-rule: nonzero`.
- [ ] `fill-rule: evenodd`.
- [ ] `stroke`.
- [x] `stroke-width`.
- [ ] `stroke-opacity`.
- [ ] `stroke-linecap: butt`.
- [ ] `stroke-linecap: round`.
- [ ] `stroke-linecap: square`.
- [ ] `stroke-linejoin: miter`.
- [ ] `stroke-linejoin: round`.
- [ ] `stroke-linejoin: bevel`.
- [ ] `stroke-miterlimit`.
- [ ] `stroke-dasharray`.
- [ ] `stroke-dashoffset`.
- [ ] `paint-order`.
- [ ] `color`.
- [ ] `color-interpolation`.
- [ ] `color-rendering`.
- [ ] `shape-rendering`.
- [ ] `text-rendering`.
- [ ] `image-rendering`.
- [ ] Markers on stroked paths.

## Colors

- [x] Hex color through CSS class fill fixture.
- [ ] Short hex color.
- [ ] Eight-digit hex with alpha.
- [ ] `rgb()`.
- [ ] `rgba()`.
- [ ] Percentage RGB values.
- [ ] Named CSS colors.
- [ ] `transparent`.
- [ ] `currentColor`.
- [ ] ICC color / color profiles policy.

## Gradients and Patterns

- [x] `<linearGradient>` element with stops.
- [ ] `<radialGradient>` element with stops.
- [ ] `<stop>` `offset`.
- [ ] `<stop>` `stop-color`.
- [ ] `<stop>` `stop-opacity`.
- [ ] `gradientUnits="objectBoundingBox"`.
- [ ] `gradientUnits="userSpaceOnUse"`.
- [ ] `gradientTransform`.
- [ ] `spreadMethod="pad"`.
- [ ] `spreadMethod="reflect"`.
- [ ] `spreadMethod="repeat"`.
- [ ] Gradient template inheritance via `href`.
- [ ] `<pattern>`.
- [ ] Pattern content coordinate systems.
- [ ] Pattern template inheritance via `href`.
- [ ] Paint server fallback colors.
- [ ] Paint servers in SwiftUI render plan.

## Clipping, Masking, and Compositing

- [ ] `<clipPath>`.
- [ ] `clip-path`.
- [ ] `clip-rule`.
- [ ] Clip path units.
- [ ] Nested clip paths.
- [ ] `<mask>`.
- [ ] `mask`.
- [ ] Mask coordinate systems.
- [ ] Mask luminance vs alpha policy.
- [ ] `opacity`.
- [ ] Group opacity.
- [ ] `mix-blend-mode`.
- [ ] `isolation`.
- [ ] Overflow clipping.

## Filters

- [ ] `<filter>`.
- [ ] Filter primitive region calculation.
- [ ] Parse `<feGaussianBlur>` primitive.
- [ ] Parse `<feDropShadow>` primitive.
- [ ] `<feBlend>`.
- [ ] `<feColorMatrix>`.
- [ ] `<feComponentTransfer>`.
- [ ] `<feFuncR>`.
- [ ] `<feFuncG>`.
- [ ] `<feFuncB>`.
- [ ] `<feFuncA>`.
- [ ] `<feComposite>`.
- [ ] `<feConvolveMatrix>`.
- [ ] `<feDiffuseLighting>`.
- [ ] `<feDisplacementMap>`.
- [ ] `<feDistantLight>`.
- [ ] `<feFlood>`.
- [ ] `<feImage>`.
- [ ] `<feMerge>`.
- [ ] `<feMergeNode>`.
- [ ] `<feMorphology>`.
- [ ] `<feOffset>`.
- [ ] `<fePointLight>`.
- [ ] `<feSpecularLighting>`.
- [ ] `<feSpotLight>`.
- [ ] `<feTile>`.
- [ ] `<feTurbulence>`.
- [ ] Filter render support in SwiftUI or documented fallback.

## Text

- [ ] `<text>`.
- [ ] `<tspan>`.
- [ ] `<textPath>`.
- [ ] Text `x`, `y`, `dx`, `dy`.
- [ ] Text `rotate`.
- [ ] `text-anchor`.
- [ ] `dominant-baseline`.
- [ ] Baseline alignment.
- [ ] Font family.
- [ ] Font size.
- [ ] Font weight.
- [ ] Font style.
- [ ] Letter spacing.
- [ ] Word spacing.
- [ ] Text decoration.
- [ ] `white-space`.
- [ ] `inline-size`.
- [ ] Auto-wrapped text.
- [ ] Text-to-path conversion for `CGPath`.
- [ ] Text rendering in `SwgView`.

## Embedded Content

- [ ] `<image>` raster references.
- [ ] `<image>` data URIs.
- [ ] `<image>` sizing.
- [ ] `<image>` aspect ratio behavior.
- [ ] `<foreignObject>` preservation.
- [ ] `<audio>` policy.
- [ ] `<video>` policy.
- [ ] `<iframe>` policy.
- [ ] `<canvas>` policy.

## Reuse and Linking

- [ ] `href`.
- [ ] `xlink:href`.
- [ ] `<use>` with element references.
- [ ] `<use>` with symbol references.
- [ ] Shadow tree style inheritance behavior.
- [ ] Cyclic reference detection.
- [ ] External document references.
- [ ] `<a>` link preservation.

## Markers

- [ ] `<marker>`.
- [ ] `marker-start`.
- [ ] `marker-mid`.
- [ ] `marker-end`.
- [ ] Marker orientation.
- [ ] Marker units.
- [ ] Marker viewBox.
- [ ] Marker rendering in SwiftUI.

## Animation and Dynamic SVG

- [ ] `<animate>`.
- [ ] `<animateMotion>`.
- [ ] `<animateTransform>`.
- [ ] `<set>`.
- [ ] `<discard>`.
- [ ] `<mpath>`.
- [ ] Timing attributes.
- [ ] Value interpolation.
- [ ] Additive and accumulate behavior.
- [ ] Static rendering policy for animated SVG.
- [ ] SwiftUI animation mapping policy.

## Scripting and Interactivity

- [ ] `<script>` preservation or rejection policy.
- [ ] Event attributes policy.
- [ ] Pointer-events property.
- [ ] Cursor property.
- [ ] Focus and tab index attributes.
- [ ] Accessibility ARIA attributes.
- [ ] `role`.

## Swift and Apple Rendering

- [ ] Add Apple-only `CGPath` conversion API.
- [ ] Convert path data to `CGPath`.
- [ ] Convert rect to `CGPath`.
- [ ] Convert rounded rect to `CGPath`.
- [ ] Convert circle to `CGPath`.
- [ ] Convert ellipse to `CGPath`.
- [ ] Convert line to `CGPath`.
- [ ] Convert polyline to `CGPath`.
- [ ] Convert polygon to `CGPath`.
- [ ] Apply transforms to `CGPath`.
- [ ] Resolve `<use>` before path conversion.
- [ ] Resolve clipping before rendering.
- [ ] Create SwiftUI `Shape` wrapper.
- [ ] Create SwiftUI `View` wrapper.
- [ ] Render fills in SwiftUI.
- [ ] Render strokes in SwiftUI.
- [ ] Render gradients in SwiftUI.
- [ ] Render masks/clips in SwiftUI.
- [ ] Render text in SwiftUI.
- [ ] Render images in SwiftUI.

## Test Fixtures and Quality Gates

- [ ] Add fixture loader for SVG files.
- [ ] Add W3C-style tiny fixtures by feature.
- [ ] Add real-world icon fixtures.
- [ ] Add malformed-input fixtures.
- [ ] Add parser diagnostics assertions.
- [ ] Add `CGPath` structural assertions.
- [ ] Add SwiftUI snapshot tests.
- [ ] Add golden SVG-to-model tests.
- [ ] Add performance tests for large SVG files.
- [ ] Add fuzz tests for path data tokenization.
