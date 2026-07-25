# swg SVG Coverage TODO

This checklist is test-gated: only mark an item `- [x]` when there is at least one focused test proving that SVG feature. Existing code without a focused test stays unchecked.

References: SVG 2 specification (https://www.w3.org/TR/SVG/), element index (https://www.w3.org/TR/SVG/eltindex.html), attribute index (https://www.w3.org/TR/SVG/attindex.html), property index (https://www.w3.org/TR/SVG/propidx.html).

## Document Structure and Global Attributes

- [x] `xml:space`.
- [x] `lang` and `xml:lang`.
- [x] `id`.

## Basic Data Types

- [x] `<number>`.
- [x] `<integer>`.
- [x] `<length>` without units.
- [x] Absolute `<length>` units: `px`, `pt`, `pc`, `mm`, `cm`, `in`.
- [x] Font-relative `<length>` units: `em`, `ex`, `ch`, `rem`.
- [x] Viewport-relative `<length>` units: `vw`, `vh`, `vmin`, `vmax`.
- [x] `<percentage>`.
- [x] `<angle>` units: `deg`, `grad`, `rad`, `turn`.
- [x] `<time>`.
- [x] `<frequency>`.
- [x] `<list-of-Ts>` comma-wsp parsing.
- [x] `<paint>`.
- [x] `<url>`.

## Document and Container Elements

- [x] `<svg>` nested viewport behavior.
- [x] `<svg>` `x`, `y`, `width`, `height`.
- [x] `<svg>` `viewBox`.
- [x] `<svg>` `preserveAspectRatio`.
- [x] `<g>`.
- [x] `<defs>`.
- [x] `<symbol>`.
- [x] `<use>`.
- [x] `<switch>`.
- [ ] `<view>`.
- [ ] `<a>`.
- [ ] `<title>`.
- [ ] `<desc>`.
- [ ] `<metadata>`.

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
- [ ] Geometry properties: `x`, `y`, `cx`, `cy`, `r`, `rx`, `ry`, `width`, `height`.

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
- [ ] `vector-effect`.

## Styling and Cascade

- [ ] Presentation attributes.
- [ ] Inline `style` attribute.
- [x] `<style>` element class selector.
- [ ] Type selectors.
- [ ] ID selectors.
- [ ] Multiple classes.
- [ ] Selector specificity.
- [ ] Inheritance.
- [ ] `inherit`.
- [ ] `currentColor`.
- [ ] `<style>` `media`.

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
- [ ] `alignment-baseline`.
- [ ] `font-family`.
- [ ] `font-size`.
- [ ] `font-weight`.
- [ ] `font-style`.
- [ ] `letter-spacing`.
- [ ] `word-spacing`.
- [ ] Text decoration.
- [ ] `white-space`.
- [ ] `inline-size`.
- [ ] Auto-wrapped text.

## Embedded Content

- [ ] `<image>` raster references.
- [ ] `<image>` sizing.
- [ ] `<image>` aspect ratio behavior.
- [ ] `<foreignObject>`.

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
- [ ] Event handler attributes.
- [ ] `pointer-events`.
- [ ] `cursor`.
- [ ] `tabindex`.
- [ ] Accessibility ARIA attributes.
- [ ] `role`.
