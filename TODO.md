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
- [x] `<view>`.
- [x] `<a>`.
- [x] `<title>`.
- [x] `<desc>`.
- [x] `<metadata>`.

## Basic Shapes

- [x] `<path>` element.
- [x] `<rect>` element.
- [x] `<rect>` rounded corners with `rx`.
- [x] `<rect>` rounded corners with `ry`.
- [x] `<circle>` element.
- [x] `<ellipse>` element.
- [x] `<line>` element.
- [x] `<polyline>` element.
- [x] `<polygon>` element.
- [x] Geometry properties: `x`, `y`, `cx`, `cy`, `r`, `rx`, `ry`, `width`, `height`.

## Path Data

- [x] `M` / `m` moveto.
- [x] `L` / `l` lineto.
- [x] `H` / `h` horizontal lineto.
- [x] `V` / `v` vertical lineto.
- [x] `C` / `c` cubic Bezier.
- [x] `S` / `s` smooth cubic Bezier.
- [x] `Q` / `q` quadratic Bezier.
- [x] `T` / `t` smooth quadratic Bezier.
- [x] `A` / `a` elliptical arc.
- [x] `Z` / `z` closepath.
- [x] Implicit repeated commands after `M`.
- [x] Implicit repeated commands for non-`M` commands.

## Coordinate Systems and Transforms

- [x] User coordinate system.
- [x] Viewport coordinate system.
- [x] `viewBox` to viewport transform.
- [x] `preserveAspectRatio` `none`.
- [x] `preserveAspectRatio` meet.
- [x] `preserveAspectRatio` slice.
- [x] `transform` list ordering.
- [x] `matrix`.
- [x] `translate`.
- [x] `scale`.
- [x] `rotate(angle)`.
- [x] `rotate(angle cx cy)`.
- [x] `skewX`.
- [x] `skewY`.
- [x] `vector-effect`.

## Styling and Cascade

- [x] Presentation attributes.
- [x] Inline `style` attribute.
- [x] `<style>` element.
- [x] Inheritance.
- [x] `inherit`.
- [x] `currentColor`.
- [x] `<style>` `media`.

## Painting

- [x] `fill`.
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
- [ ] `rgb()`.
- [ ] `rgba()`.
- [ ] Percentage RGB values.
- [ ] Named CSS colors.
- [ ] `transparent`.
- [ ] `currentColor`.
- [ ] ICC colors.

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
- [ ] `<pattern>`.
- [ ] `patternContentUnits`.

## Clipping, Masking, and Compositing

- [ ] `<clipPath>`.
- [ ] `clip-path`.
- [ ] `clip-rule`.
- [ ] `clipPathUnits`.
- [ ] `<mask>`.
- [ ] `mask`.
- [ ] `maskUnits`.
- [ ] `maskContentUnits`.
- [ ] `opacity`.

## Filters

- [ ] `<filter>`.
- [ ] `filterUnits`.
- [ ] `primitiveUnits`.
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
- [ ] `x`, `y`, `dx`, `dy` on text content elements.
- [ ] `rotate` on text content elements.
- [ ] `text-anchor`.
- [ ] `dominant-baseline`.
- [ ] `alignment-baseline`.
- [ ] `font-family`.
- [ ] `font-size`.
- [ ] `font-weight`.
- [ ] `font-style`.
- [ ] `letter-spacing`.
- [ ] `word-spacing`.
- [ ] `white-space`.
- [ ] `inline-size`.

## Embedded Content

- [ ] `<foreignObject>`.

## Reuse and Linking

- [ ] `href`.
- [ ] `xlink:href`.

## Markers

- [ ] `<marker>`.
- [ ] `marker-start`.
- [ ] `marker-mid`.
- [ ] `marker-end`.
- [ ] `orient`.
- [ ] `markerUnits`.
- [ ] `viewBox`.

## Animation and Dynamic SVG

- [ ] `<animate>`.
- [ ] `<animateMotion>`.
- [ ] `<animateTransform>`.
- [ ] `<set>`.
- [ ] `<discard>`.
- [ ] `<mpath>`.
- [ ] `begin`, `dur`, `end`, `min`, `max`.
- [ ] `restart`, `repeatCount`, `repeatDur`.
- [ ] `calcMode`, `values`, `keyTimes`, `keySplines`.
- [ ] `additive`.
- [ ] `accumulate`.

## Scripting and Interactivity

- [ ] `<script>`.
- [ ] `on*` event attributes.
- [ ] `pointer-events`.
- [ ] `tabindex`.
- [ ] `role`.
