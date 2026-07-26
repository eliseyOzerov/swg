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

- [x] Inline `style` attribute.
- [x] `<style>` element.
- [x] `<style>` `media`.

## Painting

- [x] `fill`.
- [x] `fill-opacity`.
- [x] `fill-rule: nonzero`.
- [x] `fill-rule: evenodd`.
- [x] `stroke`.
- [x] `stroke-width`.
- [x] `stroke-opacity`.
- [x] `stroke-linecap: butt`.
- [x] `stroke-linecap: round`.
- [x] `stroke-linecap: square`.
- [x] `stroke-linejoin: miter`.
- [x] `stroke-linejoin: round`.
- [x] `stroke-linejoin: bevel`.
- [x] `stroke-miterlimit`.
- [x] `stroke-dasharray`.
- [x] `stroke-dashoffset`.
- [x] `paint-order`.
- [x] `color`.
- [x] `color-interpolation`.
- [x] `color-rendering`.
- [x] `shape-rendering`.
- [x] `text-rendering`.
- [x] `image-rendering`.

## Gradients and Patterns

- [x] `<linearGradient>` element with stops.
- [x] `<radialGradient>` element with stops.
- [x] `<stop>` `offset`.
- [x] `<stop>` `stop-color`.
- [x] `<stop>` `stop-opacity`.
- [x] `gradientUnits="objectBoundingBox"`.
- [x] `gradientUnits="userSpaceOnUse"`.
- [x] `gradientTransform`.
- [x] `spreadMethod="pad"`.
- [x] `spreadMethod="reflect"`.
- [x] `spreadMethod="repeat"`.
- [x] `<pattern>`.
- [x] `patternContentUnits`.

## Clipping, Masking, and Compositing

- [x] `<clipPath>`.
- [x] `clip-path`.
- [x] `clip-rule`.
- [x] `clipPathUnits`.
- [x] `<mask>`.
- [x] `mask`.
- [x] `maskUnits`.
- [x] `maskContentUnits`.
- [x] `opacity`.

## Filters

- [x] `<filter>`.
- [x] `filterUnits`.
- [x] `primitiveUnits`.
- [x] `<feGaussianBlur>`.
- [x] `<feDropShadow>`.
- [x] `<feBlend>`.
- [x] `<feColorMatrix>`.
- [x] `<feComponentTransfer>`.
- [x] `<feFuncR>`.
- [x] `<feFuncG>`.
- [x] `<feFuncB>`.
- [x] `<feFuncA>`.
- [x] `<feComposite>`.
- [x] `<feConvolveMatrix>`.
- [x] `<feDiffuseLighting>`.
- [x] `<feDisplacementMap>`.
- [x] `<feDistantLight>`.
- [x] `<feFlood>`.
- [x] `<feImage>`.
- [x] `<feMerge>`.
- [x] `<feMergeNode>`.
- [x] `<feMorphology>`.
- [x] `<feOffset>`.
- [x] `<fePointLight>`.
- [x] `<feSpecularLighting>`.
- [x] `<feSpotLight>`.
- [x] `<feTile>`.
- [x] `<feTurbulence>`.

## Text

- [x] `<text>`.
- [x] `<tspan>`.
- [x] `<textPath>`.
- [x] `x`, `y`, `dx`, `dy` on text content elements.
- [ ] `rotate` on text content elements.
- [ ] `text-anchor`.
- [ ] `dominant-baseline`.
- [ ] `alignment-baseline`.
- [ ] `white-space`.

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
- [ ] `pointer-events`.
