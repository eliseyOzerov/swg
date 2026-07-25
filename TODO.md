# swg SVG Coverage TODO

This checklist is test-gated: only mark an item `- [x]` when there is at least one focused test proving that SVG feature. Existing code without a focused test stays unchecked.

References: SVG 2 specification (https://www.w3.org/TR/SVG/), element index (https://www.w3.org/TR/SVG/eltindex.html), attribute index (https://www.w3.org/TR/SVG/attindex.html), property index (https://www.w3.org/TR/SVG/propidx.html).

## Core Parsing Infrastructure

- [x] XML namespaces, including default SVG namespace and `xlink`.
- [x] XML entity handling.
- [x] XML comments and processing instructions.
- [x] Whitespace normalization rules.
- [x] `xml:space`.
- [ ] `lang` and `xml:lang`.
- [ ] `id`.

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

## Document and Container Elements

- [ ] `<svg>` nested viewport behavior.
- [ ] `<svg>` `x`, `y`, `width`, `height`.
- [x] `<svg>` `viewBox`.
- [ ] `<svg>` `preserveAspectRatio`.
- [x] `<g>`.
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

## Basic Shapes

- [x] `<path>` element.
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

- [x] `M` / `m` moveto.
- [x] `L` / `l` lineto.
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

- [x] Hex color.
- [ ] Short hex color.
- [ ] Eight-digit hex with alpha.
- [ ] `rgb()`.
- [ ] `rgba()`.
- [ ] Percentage RGB values.
- [ ] Named CSS colors.
- [ ] `transparent`.
- [ ] `currentColor`.
- [ ] ICC color and color profiles.

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

## Clipping, Masking, and Compositing

- [ ] `<clipPath>`.
- [ ] `clip-path`.
- [ ] `clip-rule`.
- [ ] Clip path units.
- [ ] Nested clip paths.
- [ ] `<mask>`.
- [ ] `mask`.
- [ ] Mask coordinate systems.
- [ ] Mask luminance and alpha behavior.
- [ ] `opacity`.
- [ ] Group opacity.
- [ ] `mix-blend-mode`.
- [ ] `isolation`.
- [ ] Overflow clipping.

## Filters

- [ ] `<filter>`.
- [ ] Filter primitive region calculation.
- [ ] `<feGaussianBlur>`.
- [ ] `<feDropShadow>`.
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

## Embedded Content

- [ ] `<image>` raster references.
- [ ] `<image>` data URIs.
- [ ] `<image>` sizing.
- [ ] `<image>` aspect ratio behavior.
- [ ] `<foreignObject>`.
- [ ] `<audio>`.
- [ ] `<video>`.
- [ ] `<iframe>`.
- [ ] `<canvas>`.

## Reuse and Linking

- [ ] `href`.
- [ ] `xlink:href`.
- [ ] `<use>` with element references.
- [ ] `<use>` with symbol references.
- [ ] Shadow tree style inheritance behavior.
- [ ] Cyclic reference detection.
- [ ] External document references.
- [ ] `<a>` linking.

## Markers

- [ ] `<marker>`.
- [ ] `marker-start`.
- [ ] `marker-mid`.
- [ ] `marker-end`.
- [ ] Marker orientation.
- [ ] Marker units.
- [ ] Marker viewBox.

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

## Scripting and Interactivity

- [ ] `<script>`.
- [ ] Event attributes.
- [ ] Pointer-events property.
- [ ] Cursor property.
- [ ] Focus and tab index attributes.
- [ ] Accessibility ARIA attributes.
- [ ] `role`.
