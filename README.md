# swg

Swift Vector Graphics. `swg` is an independent Swift package for parsing SVG files into a strongly typed model, converting supported geometry into `CGPath`, editing the parsed document tree, and displaying SVG content with `SVG` in SwiftUI.

The package has no third-party dependencies. XML parsing uses Foundation's `XMLParser`, with `FoundationXML` imported on platforms where that module is split out.

## Status

The parser is built around the SVG 2 specification and is tracked by a test-gated checklist in [TODO.md](TODO.md). A checklist item is checked only when there is a focused test for that feature.

Current coverage is strongest in parser/model behavior. The native SwiftUI renderer displays the shape/path/container subset that can already map through `CGPath`, plus basic native linear gradients, radial gradients, gradient spread modes, pattern fills, local clip paths, local masks, basic text runs, local markers, and a clock-based subset of declarative animation. Browser-equivalent rendering for advanced text layout, filters, contextual marker paint, images, motion paths, event-based animation timing, and advanced paint-server behavior is still renderer work in progress even though much of that structure is parsed and modeled.

The matrix below shows one SVG example per visual feature. Each source SVG is parsed by `swg` and rendered to PNG through the package's `SVG` SwiftUI view.

## SVG View Visual Feature Matrix

These images are generated from one SVG per visual feature by `docs/FeatureGallery.playground/Contents.swift`. The playground writes the source SVGs to `docs/feature-gallery/svg`, parses them with `swg`, renders them through the public `SVG` SwiftUI view, and writes PNGs to `docs/feature-gallery/png`.

The examples use a neutral light/dark duotone palette by default so shape, transform, layout, and paint mechanics are easier to compare without interpreting arbitrary colors. Filled-and-stroked elements use a light fill with a dark stroke; foreground-only fills stay dark when that makes the feature easier to see. Examples stay colorful only when the feature itself is about color or opacity-specific paint, including fills, strokes, gradients, patterns, span paint overrides, and color-bearing filter properties.

The parser/model checklist remains in [TODO.md](TODO.md). This matrix is specifically the native SwiftUI renderer truth table: 133 visual examples, 93 currently render through `SVG`, and 40 are intentionally left blank because the feature is parsed/modelled but not actually painted yet.

Not actually rendering yet: filter primitives, advanced text layout, contextual marker paint, vector-effect stroke behavior, rendering hints, embedded HTML inside `foreignObject`, motion paths, discard animation, and event-based animation timing. Those features are still valuable in the model, but the current `SVG` view either skips them or paints only the static/base geometry.


## Document and Containers

<table width="100%">
<colgroup>
<col width="33.33%">
<col width="33.33%">
<col width="33.33%">
</colgroup>
<thead>
<tr>
<th>Feature</th>
<th>Preview</th>
<th>Notes</th>
</tr>
</thead>
<tbody>
<tr>
<td width="33.33%">Nested &lt;svg&gt; viewport</td>
<td width="33.33%"><img src="docs/feature-gallery/png/nested-svg-viewport.png?v=animation-native" alt="Nested &lt;svg&gt; viewport" width="144"></td>
<td width="33.33%">Nested SVG children paint inside their own viewport.</td>
</tr>
<tr>
<td width="33.33%">viewBox meet</td>
<td width="33.33%"><img src="docs/feature-gallery/png/viewbox-preserve-meet.png?v=animation-native" alt="viewBox meet" width="144"></td>
<td width="33.33%">The document is uniformly fitted into the viewport.</td>
</tr>
<tr>
<td width="33.33%">preserveAspectRatio none</td>
<td width="33.33%"><img src="docs/feature-gallery/png/preserve-aspect-none.png?v=animation-native" alt="preserveAspectRatio none" width="144"></td>
<td width="33.33%">The nested viewport uses non-uniform scaling.</td>
</tr>
<tr>
<td width="33.33%">preserveAspectRatio slice</td>
<td width="33.33%"><img src="docs/feature-gallery/png/preserve-aspect-slice.png?v=animation-native" alt="preserveAspectRatio slice" width="144"></td>
<td width="33.33%">The nested viewport covers and crops the viewBox.</td>
</tr>
<tr>
<td width="33.33%">&lt;g&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/group-container.png?v=animation-native" alt="&lt;g&gt;" width="144"></td>
<td width="33.33%">Groups apply transforms and inherited paint to children.</td>
</tr>
<tr>
<td width="33.33%">&lt;defs&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/defs-hidden.png?v=animation-native" alt="&lt;defs&gt;" width="144"></td>
<td width="33.33%">Definitions stay hidden until referenced.</td>
</tr>
<tr>
<td width="33.33%">&lt;symbol&gt; + &lt;use&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/symbol-use.png?v=animation-native" alt="&lt;symbol&gt; + &lt;use&gt;" width="144"></td>
<td width="33.33%">Simple symbol references render through &lt;use&gt;.</td>
</tr>
<tr>
<td width="33.33%">&lt;switch&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/switch-container.png?v=animation-native" alt="&lt;switch&gt;" width="144"></td>
<td width="33.33%">The selected switch child renders as a normal container.</td>
</tr>
<tr>
<td width="33.33%">&lt;a&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/link-container.png?v=animation-native" alt="&lt;a&gt;" width="144"></td>
<td width="33.33%">Links render their SVG children; interaction metadata is preserved separately.</td>
</tr>
<tr>
<td width="33.33%">&lt;view&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Predefined views are parsed but are not drawable content.</td>
</tr>
</tbody>
</table>

## Basic Shapes

<table width="100%">
<colgroup>
<col width="33.33%">
<col width="33.33%">
<col width="33.33%">
</colgroup>
<thead>
<tr>
<th>Feature</th>
<th>Preview</th>
<th>Notes</th>
</tr>
</thead>
<tbody>
<tr>
<td width="33.33%">&lt;path&gt; element</td>
<td width="33.33%"><img src="docs/feature-gallery/png/shape-path.png?v=animation-native" alt="&lt;path&gt; element" width="144"></td>
<td width="33.33%">Path elements render through CGPath.</td>
</tr>
<tr>
<td width="33.33%">&lt;rect&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/shape-rect.png?v=animation-native" alt="&lt;rect&gt;" width="144"></td>
<td width="33.33%">Rectangles render with fill and stroke.</td>
</tr>
<tr>
<td width="33.33%">&lt;rect rx&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/shape-rounded-rx.png?v=animation-native" alt="&lt;rect rx&gt;" width="144"></td>
<td width="33.33%">Rounded x radius is converted into the path.</td>
</tr>
<tr>
<td width="33.33%">&lt;rect ry&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/shape-rounded-ry.png?v=animation-native" alt="&lt;rect ry&gt;" width="144"></td>
<td width="33.33%">Rounded y radius is converted into the path.</td>
</tr>
<tr>
<td width="33.33%">&lt;circle&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/shape-circle.png?v=animation-native" alt="&lt;circle&gt;" width="144"></td>
<td width="33.33%">Circles render as CGPath ellipses.</td>
</tr>
<tr>
<td width="33.33%">&lt;ellipse&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/shape-ellipse.png?v=animation-native" alt="&lt;ellipse&gt;" width="144"></td>
<td width="33.33%">Ellipses render as CGPath ellipses.</td>
</tr>
<tr>
<td width="33.33%">&lt;line&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/shape-line.png?v=animation-native" alt="&lt;line&gt;" width="144"></td>
<td width="33.33%">Lines render as stroked paths.</td>
</tr>
<tr>
<td width="33.33%">&lt;polyline&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/shape-polyline.png?v=animation-native" alt="&lt;polyline&gt;" width="144"></td>
<td width="33.33%">Polylines render as open stroked paths.</td>
</tr>
<tr>
<td width="33.33%">&lt;polygon&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/shape-polygon.png?v=animation-native" alt="&lt;polygon&gt;" width="144"></td>
<td width="33.33%">Polygons render as closed paths.</td>
</tr>
</tbody>
</table>

## Path Data

<table width="100%">
<colgroup>
<col width="33.33%">
<col width="33.33%">
<col width="33.33%">
</colgroup>
<thead>
<tr>
<th>Feature</th>
<th>Preview</th>
<th>Notes</th>
</tr>
</thead>
<tbody>
<tr>
<td width="33.33%">M/L commands</td>
<td width="33.33%"><img src="docs/feature-gallery/png/path-move-line.png?v=animation-native" alt="M/L commands" width="144"></td>
<td width="33.33%">Moveto and lineto path commands paint.</td>
</tr>
<tr>
<td width="33.33%">H command</td>
<td width="33.33%"><img src="docs/feature-gallery/png/path-horizontal.png?v=animation-native" alt="H command" width="144"></td>
<td width="33.33%">Horizontal line commands paint.</td>
</tr>
<tr>
<td width="33.33%">V command</td>
<td width="33.33%"><img src="docs/feature-gallery/png/path-vertical.png?v=animation-native" alt="V command" width="144"></td>
<td width="33.33%">Vertical line commands paint.</td>
</tr>
<tr>
<td width="33.33%">C command</td>
<td width="33.33%"><img src="docs/feature-gallery/png/path-cubic.png?v=animation-native" alt="C command" width="144"></td>
<td width="33.33%">Cubic Bezier commands paint.</td>
</tr>
<tr>
<td width="33.33%">S command</td>
<td width="33.33%"><img src="docs/feature-gallery/png/path-smooth-cubic.png?v=animation-native" alt="S command" width="144"></td>
<td width="33.33%">Smooth cubic commands paint after cubic control reflection.</td>
</tr>
<tr>
<td width="33.33%">Q command</td>
<td width="33.33%"><img src="docs/feature-gallery/png/path-quadratic.png?v=animation-native" alt="Q command" width="144"></td>
<td width="33.33%">Quadratic Bezier commands paint.</td>
</tr>
<tr>
<td width="33.33%">T command</td>
<td width="33.33%"><img src="docs/feature-gallery/png/path-smooth-quadratic.png?v=animation-native" alt="T command" width="144"></td>
<td width="33.33%">Smooth quadratic commands paint.</td>
</tr>
<tr>
<td width="33.33%">A command</td>
<td width="33.33%"><img src="docs/feature-gallery/png/path-arc.png?v=animation-native" alt="A command" width="144"></td>
<td width="33.33%">Elliptical arcs are converted to cubic path segments.</td>
</tr>
<tr>
<td width="33.33%">Z command</td>
<td width="33.33%"><img src="docs/feature-gallery/png/path-close.png?v=animation-native" alt="Z command" width="144"></td>
<td width="33.33%">Closepath fills and closes the outline.</td>
</tr>
<tr>
<td width="33.33%">Implicit repeated commands</td>
<td width="33.33%"><img src="docs/feature-gallery/png/path-implicit-repeated.png?v=animation-native" alt="Implicit repeated commands" width="144"></td>
<td width="33.33%">Repeated command parameters become additional path segments.</td>
</tr>
</tbody>
</table>

## Coordinate Systems and Transforms

<table width="100%">
<colgroup>
<col width="33.33%">
<col width="33.33%">
<col width="33.33%">
</colgroup>
<thead>
<tr>
<th>Feature</th>
<th>Preview</th>
<th>Notes</th>
</tr>
</thead>
<tbody>
<tr>
<td width="33.33%">matrix()</td>
<td width="33.33%"><img src="docs/feature-gallery/png/transform-matrix.png?v=animation-native" alt="matrix()" width="144"></td>
<td width="33.33%">Matrix transforms are applied before painting.</td>
</tr>
<tr>
<td width="33.33%">translate()</td>
<td width="33.33%"><img src="docs/feature-gallery/png/transform-translate.png?v=animation-native" alt="translate()" width="144"></td>
<td width="33.33%">Translation moves rendered geometry.</td>
</tr>
<tr>
<td width="33.33%">scale()</td>
<td width="33.33%"><img src="docs/feature-gallery/png/transform-scale.png?v=animation-native" alt="scale()" width="144"></td>
<td width="33.33%">Scaling affects the painted path.</td>
</tr>
<tr>
<td width="33.33%">rotate(angle)</td>
<td width="33.33%"><img src="docs/feature-gallery/png/transform-rotate.png?v=animation-native" alt="rotate(angle)" width="144"></td>
<td width="33.33%">Rotation around the origin is applied.</td>
</tr>
<tr>
<td width="33.33%">rotate(angle cx cy)</td>
<td width="33.33%"><img src="docs/feature-gallery/png/transform-rotate-center.png?v=animation-native" alt="rotate(angle cx cy)" width="144"></td>
<td width="33.33%">Centered rotation is applied around the provided pivot.</td>
</tr>
<tr>
<td width="33.33%">skewX()</td>
<td width="33.33%"><img src="docs/feature-gallery/png/transform-skew-x.png?v=animation-native" alt="skewX()" width="144"></td>
<td width="33.33%">Horizontal skew transforms paint.</td>
</tr>
<tr>
<td width="33.33%">skewY()</td>
<td width="33.33%"><img src="docs/feature-gallery/png/transform-skew-y.png?v=animation-native" alt="skewY()" width="144"></td>
<td width="33.33%">Vertical skew transforms paint.</td>
</tr>
<tr>
<td width="33.33%">vector-effect</td>
<td width="33.33%"></td>
<td width="33.33%">Vector-effect is parsed but the renderer does not keep strokes non-scaling.</td>
</tr>
</tbody>
</table>

## Styling and Cascade

<table width="100%">
<colgroup>
<col width="33.33%">
<col width="33.33%">
<col width="33.33%">
</colgroup>
<thead>
<tr>
<th>Feature</th>
<th>Preview</th>
<th>Notes</th>
</tr>
</thead>
<tbody>
<tr>
<td width="33.33%">Inline style</td>
<td width="33.33%"><img src="docs/feature-gallery/png/style-inline.png?v=animation-native" alt="Inline style" width="144"></td>
<td width="33.33%">Inline style declarations feed native paint attributes.</td>
</tr>
<tr>
<td width="33.33%">&lt;style&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/style-element.png?v=animation-native" alt="&lt;style&gt;" width="144"></td>
<td width="33.33%">Simple matching style rules affect painted geometry.</td>
</tr>
<tr>
<td width="33.33%">&lt;style media&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/style-media.png?v=animation-native" alt="&lt;style media&gt;" width="144"></td>
<td width="33.33%">Matching media-filtered rules are applied by the parser.</td>
</tr>
</tbody>
</table>

## Painting

<table width="100%">
<colgroup>
<col width="33.33%">
<col width="33.33%">
<col width="33.33%">
</colgroup>
<thead>
<tr>
<th>Feature</th>
<th>Preview</th>
<th>Notes</th>
</tr>
</thead>
<tbody>
<tr>
<td width="33.33%">fill</td>
<td width="33.33%"><img src="docs/feature-gallery/png/paint-fill.png?v=animation-native" alt="fill" width="144"></td>
<td width="33.33%">Solid fill paint renders.</td>
</tr>
<tr>
<td width="33.33%">fill-opacity</td>
<td width="33.33%"><img src="docs/feature-gallery/png/paint-fill-opacity.png?v=animation-native" alt="fill-opacity" width="144"></td>
<td width="33.33%">Fill opacity multiplies solid paint.</td>
</tr>
<tr>
<td width="33.33%">fill-rule nonzero</td>
<td width="33.33%"><img src="docs/feature-gallery/png/paint-fill-rule-nonzero.png?v=animation-native" alt="fill-rule nonzero" width="144"></td>
<td width="33.33%">Nonzero fill rule paints nested winding normally.</td>
</tr>
<tr>
<td width="33.33%">fill-rule evenodd</td>
<td width="33.33%"><img src="docs/feature-gallery/png/paint-fill-rule-evenodd.png?v=animation-native" alt="fill-rule evenodd" width="144"></td>
<td width="33.33%">Even-odd fill rule cuts out the inner path.</td>
</tr>
<tr>
<td width="33.33%">stroke</td>
<td width="33.33%"><img src="docs/feature-gallery/png/paint-stroke.png?v=animation-native" alt="stroke" width="144"></td>
<td width="33.33%">Solid stroke paint renders.</td>
</tr>
<tr>
<td width="33.33%">stroke-width</td>
<td width="33.33%"><img src="docs/feature-gallery/png/paint-stroke-width.png?v=animation-native" alt="stroke-width" width="144"></td>
<td width="33.33%">Stroke width affects painted outlines.</td>
</tr>
<tr>
<td width="33.33%">stroke-opacity</td>
<td width="33.33%"><img src="docs/feature-gallery/png/paint-stroke-opacity.png?v=animation-native" alt="stroke-opacity" width="144"></td>
<td width="33.33%">Stroke opacity multiplies stroke paint.</td>
</tr>
<tr>
<td width="33.33%">stroke-linecap butt</td>
<td width="33.33%"><img src="docs/feature-gallery/png/paint-linecap-butt.png?v=animation-native" alt="stroke-linecap butt" width="144"></td>
<td width="33.33%">Butt caps end exactly on the path endpoints.</td>
</tr>
<tr>
<td width="33.33%">stroke-linecap round</td>
<td width="33.33%"><img src="docs/feature-gallery/png/paint-linecap-round.png?v=animation-native" alt="stroke-linecap round" width="144"></td>
<td width="33.33%">Round caps extend the path with semicircles.</td>
</tr>
<tr>
<td width="33.33%">stroke-linecap square</td>
<td width="33.33%"><img src="docs/feature-gallery/png/paint-linecap-square.png?v=animation-native" alt="stroke-linecap square" width="144"></td>
<td width="33.33%">Square caps extend the path with square ends.</td>
</tr>
<tr>
<td width="33.33%">stroke-linejoin miter</td>
<td width="33.33%"><img src="docs/feature-gallery/png/paint-linejoin-miter.png?v=animation-native" alt="stroke-linejoin miter" width="144"></td>
<td width="33.33%">Miter joins create pointed corners.</td>
</tr>
<tr>
<td width="33.33%">stroke-linejoin round</td>
<td width="33.33%"><img src="docs/feature-gallery/png/paint-linejoin-round.png?v=animation-native" alt="stroke-linejoin round" width="144"></td>
<td width="33.33%">Round joins create curved corners.</td>
</tr>
<tr>
<td width="33.33%">stroke-linejoin bevel</td>
<td width="33.33%"><img src="docs/feature-gallery/png/paint-linejoin-bevel.png?v=animation-native" alt="stroke-linejoin bevel" width="144"></td>
<td width="33.33%">Bevel joins flatten corners.</td>
</tr>
<tr>
<td width="33.33%">stroke-miterlimit</td>
<td width="33.33%"><img src="docs/feature-gallery/png/paint-miterlimit.png?v=animation-native" alt="stroke-miterlimit" width="144"></td>
<td width="33.33%">Miter limit affects sharp stroked corners.</td>
</tr>
<tr>
<td width="33.33%">stroke-dasharray</td>
<td width="33.33%"><img src="docs/feature-gallery/png/paint-dasharray.png?v=animation-native" alt="stroke-dasharray" width="144"></td>
<td width="33.33%">Dash arrays are passed to SwiftUI stroke style.</td>
</tr>
<tr>
<td width="33.33%">stroke-dashoffset</td>
<td width="33.33%"><img src="docs/feature-gallery/png/paint-dashoffset.png?v=animation-native" alt="stroke-dashoffset" width="144"></td>
<td width="33.33%">Dash offsets shift the dash phase.</td>
</tr>
<tr>
<td width="33.33%">paint-order</td>
<td width="33.33%"><img src="docs/feature-gallery/png/paint-order.png?v=animation-native" alt="paint-order" width="144"></td>
<td width="33.33%">Paint order is honored for fill, stroke, and marker passes.</td>
</tr>
<tr>
<td width="33.33%">currentColor</td>
<td width="33.33%"><img src="docs/feature-gallery/png/paint-current-color.png?v=animation-native" alt="currentColor" width="144"></td>
<td width="33.33%">currentColor resolves into fill or stroke paint.</td>
</tr>
<tr>
<td width="33.33%">rendering hints</td>
<td width="33.33%"></td>
<td width="33.33%">Color, shape, text, and image rendering hints are parsed but do not change native output.</td>
</tr>
</tbody>
</table>

## Gradients and Patterns

<table width="100%">
<colgroup>
<col width="33.33%">
<col width="33.33%">
<col width="33.33%">
</colgroup>
<thead>
<tr>
<th>Feature</th>
<th>Preview</th>
<th>Notes</th>
</tr>
</thead>
<tbody>
<tr>
<td width="33.33%">&lt;linearGradient&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/gradient-linear.png?v=animation-native" alt="&lt;linearGradient&gt;" width="144"></td>
<td width="33.33%">Linear gradient paint servers render natively.</td>
</tr>
<tr>
<td width="33.33%">&lt;radialGradient&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/gradient-radial.png?v=animation-native" alt="&lt;radialGradient&gt;" width="144"></td>
<td width="33.33%">Radial gradient paint servers render natively.</td>
</tr>
<tr>
<td width="33.33%">&lt;stop&gt; offset</td>
<td width="33.33%"><img src="docs/feature-gallery/png/gradient-stop-offset.png?v=animation-native" alt="&lt;stop&gt; offset" width="144"></td>
<td width="33.33%">Stop offsets control native gradient interpolation.</td>
</tr>
<tr>
<td width="33.33%">stop-opacity</td>
<td width="33.33%"><img src="docs/feature-gallery/png/gradient-stop-opacity.png?v=animation-native" alt="stop-opacity" width="144"></td>
<td width="33.33%">Stop opacity contributes to native gradient stop alpha.</td>
</tr>
<tr>
<td width="33.33%">gradientUnits objectBoundingBox</td>
<td width="33.33%"><img src="docs/feature-gallery/png/gradient-object-bounding-box.png?v=animation-native" alt="gradientUnits objectBoundingBox" width="144"></td>
<td width="33.33%">Object-bounding-box gradient units map through the target bounds.</td>
</tr>
<tr>
<td width="33.33%">gradientUnits userSpaceOnUse</td>
<td width="33.33%"><img src="docs/feature-gallery/png/gradient-user-space.png?v=animation-native" alt="gradientUnits userSpaceOnUse" width="144"></td>
<td width="33.33%">User-space gradient units render in SVG user coordinates.</td>
</tr>
<tr>
<td width="33.33%">gradientTransform</td>
<td width="33.33%"><img src="docs/feature-gallery/png/gradient-transform.png?v=animation-native" alt="gradientTransform" width="144"></td>
<td width="33.33%">Gradient transforms are applied to native gradient geometry.</td>
</tr>
<tr>
<td width="33.33%">spreadMethod pad</td>
<td width="33.33%"><img src="docs/feature-gallery/png/gradient-spread-pad.png?v=animation-native" alt="spreadMethod pad" width="144"></td>
<td width="33.33%">Pad spread extends endpoint colors natively.</td>
</tr>
<tr>
<td width="33.33%">spreadMethod reflect</td>
<td width="33.33%"><img src="docs/feature-gallery/png/gradient-spread-reflect.png?v=animation-native" alt="spreadMethod reflect" width="144"></td>
<td width="33.33%">Reflect spread mirrors gradient stops natively.</td>
</tr>
<tr>
<td width="33.33%">spreadMethod repeat</td>
<td width="33.33%"><img src="docs/feature-gallery/png/gradient-spread-repeat.png?v=animation-native" alt="spreadMethod repeat" width="144"></td>
<td width="33.33%">Repeat spread tiles gradient stops natively.</td>
</tr>
<tr>
<td width="33.33%">&lt;pattern&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/pattern.png?v=animation-native" alt="&lt;pattern&gt;" width="144"></td>
<td width="33.33%">Simple pattern paint servers tile native SVG children.</td>
</tr>
<tr>
<td width="33.33%">patternContentUnits</td>
<td width="33.33%"><img src="docs/feature-gallery/png/pattern-content-units.png?v=animation-native" alt="patternContentUnits" width="144"></td>
<td width="33.33%">Object-bounding-box pattern content units map tile children.</td>
</tr>
</tbody>
</table>

## Clipping, Masking, and Compositing

<table width="100%">
<colgroup>
<col width="33.33%">
<col width="33.33%">
<col width="33.33%">
</colgroup>
<thead>
<tr>
<th>Feature</th>
<th>Preview</th>
<th>Notes</th>
</tr>
</thead>
<tbody>
<tr>
<td width="33.33%">&lt;clipPath&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/clip-path-element.png?v=animation-native" alt="&lt;clipPath&gt;" width="144"></td>
<td width="33.33%">Clip path definitions apply their child geometry while rendering.</td>
</tr>
<tr>
<td width="33.33%">clip-path</td>
<td width="33.33%"><img src="docs/feature-gallery/png/clip-path-property.png?v=animation-native" alt="clip-path" width="144"></td>
<td width="33.33%">Local clip-path URL references constrain native drawing.</td>
</tr>
<tr>
<td width="33.33%">clip-rule</td>
<td width="33.33%"><img src="docs/feature-gallery/png/clip-rule.png?v=animation-native" alt="clip-rule" width="144"></td>
<td width="33.33%">Even-odd clip rules cut holes in clip path geometry.</td>
</tr>
<tr>
<td width="33.33%">clipPathUnits</td>
<td width="33.33%"><img src="docs/feature-gallery/png/clip-path-units.png?v=animation-native" alt="clipPathUnits" width="144"></td>
<td width="33.33%">Object-bounding-box clip path units scale against the clipped element.</td>
</tr>
<tr>
<td width="33.33%">&lt;mask&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/mask-element.png?v=animation-native" alt="&lt;mask&gt;" width="144"></td>
<td width="33.33%">Mask definitions apply their rendered luminance coverage.</td>
</tr>
<tr>
<td width="33.33%">mask</td>
<td width="33.33%"><img src="docs/feature-gallery/png/mask-property.png?v=animation-native" alt="mask" width="144"></td>
<td width="33.33%">Local mask URL references constrain native drawing.</td>
</tr>
<tr>
<td width="33.33%">maskUnits</td>
<td width="33.33%"><img src="docs/feature-gallery/png/mask-units.png?v=animation-native" alt="maskUnits" width="144"></td>
<td width="33.33%">User-space mask regions clip the rendered mask source.</td>
</tr>
<tr>
<td width="33.33%">maskContentUnits</td>
<td width="33.33%"><img src="docs/feature-gallery/png/mask-content-units.png?v=animation-native" alt="maskContentUnits" width="144"></td>
<td width="33.33%">Object-bounding-box mask contents scale against the masked element.</td>
</tr>
<tr>
<td width="33.33%">opacity</td>
<td width="33.33%"><img src="docs/feature-gallery/png/opacity.png?v=animation-native" alt="opacity" width="144"></td>
<td width="33.33%">Element and group opacity are applied while rendering.</td>
</tr>
</tbody>
</table>

## Filters

<table width="100%">
<colgroup>
<col width="33.33%">
<col width="33.33%">
<col width="33.33%">
</colgroup>
<thead>
<tr>
<th>Feature</th>
<th>Preview</th>
<th>Notes</th>
</tr>
</thead>
<tbody>
<tr>
<td width="33.33%">&lt;filter&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">filter="url(...)" is parsed but no filter graph is applied.</td>
</tr>
<tr>
<td width="33.33%">filterUnits</td>
<td width="33.33%"></td>
<td width="33.33%">Filter coordinate units are parsed but not applied.</td>
</tr>
<tr>
<td width="33.33%">primitiveUnits</td>
<td width="33.33%"></td>
<td width="33.33%">Primitive coordinate units are parsed but not applied.</td>
</tr>
<tr>
<td width="33.33%">&lt;feGaussianBlur&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Blur primitives are model-only today.</td>
</tr>
<tr>
<td width="33.33%">&lt;feDropShadow&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Drop shadows are parsed but not rendered.</td>
</tr>
<tr>
<td width="33.33%">&lt;feBlend&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Blend primitives are preserved but skipped.</td>
</tr>
<tr>
<td width="33.33%">&lt;feColorMatrix&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Color matrix primitives are preserved but skipped.</td>
</tr>
<tr>
<td width="33.33%">&lt;feComponentTransfer&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Component transfer primitives are preserved but skipped.</td>
</tr>
<tr>
<td width="33.33%">&lt;feFuncR&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Red channel transfer functions are model-only.</td>
</tr>
<tr>
<td width="33.33%">&lt;feFuncG&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Green channel transfer functions are model-only.</td>
</tr>
<tr>
<td width="33.33%">&lt;feFuncB&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Blue channel transfer functions are model-only.</td>
</tr>
<tr>
<td width="33.33%">&lt;feFuncA&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Alpha channel transfer functions are model-only.</td>
</tr>
<tr>
<td width="33.33%">&lt;feComposite&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Composite primitives are preserved but skipped.</td>
</tr>
<tr>
<td width="33.33%">&lt;feConvolveMatrix&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Convolution primitives are model-only.</td>
</tr>
<tr>
<td width="33.33%">&lt;feDiffuseLighting&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Diffuse lighting primitives are model-only.</td>
</tr>
<tr>
<td width="33.33%">&lt;feDisplacementMap&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Displacement map primitives are model-only.</td>
</tr>
<tr>
<td width="33.33%">&lt;feDistantLight&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Distant light data is parsed inside lighting filters only.</td>
</tr>
<tr>
<td width="33.33%">&lt;feFlood&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Flood primitives are preserved but not rendered.</td>
</tr>
<tr>
<td width="33.33%">&lt;feImage&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Filter image primitives are model-only.</td>
</tr>
<tr>
<td width="33.33%">&lt;feMerge&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Merge primitives are preserved but skipped.</td>
</tr>
<tr>
<td width="33.33%">&lt;feMergeNode&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Merge node ordering is model-only.</td>
</tr>
<tr>
<td width="33.33%">&lt;feMorphology&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Morphology primitives are preserved but skipped.</td>
</tr>
<tr>
<td width="33.33%">&lt;feOffset&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Offset primitives are preserved but skipped.</td>
</tr>
<tr>
<td width="33.33%">&lt;fePointLight&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Point light data is parsed inside lighting filters only.</td>
</tr>
<tr>
<td width="33.33%">&lt;feSpecularLighting&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Specular lighting primitives are model-only.</td>
</tr>
<tr>
<td width="33.33%">&lt;feSpotLight&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Spot light data is parsed inside lighting filters only.</td>
</tr>
<tr>
<td width="33.33%">&lt;feTile&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Tile primitives are model-only.</td>
</tr>
<tr>
<td width="33.33%">&lt;feTurbulence&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Turbulence primitives are model-only.</td>
</tr>
</tbody>
</table>

## Text

<table width="100%">
<colgroup>
<col width="33.33%">
<col width="33.33%">
<col width="33.33%">
</colgroup>
<thead>
<tr>
<th>Feature</th>
<th>Preview</th>
<th>Notes</th>
</tr>
</thead>
<tbody>
<tr>
<td width="33.33%">&lt;text&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/text-element.png?v=animation-native" alt="&lt;text&gt;" width="144"></td>
<td width="33.33%">Plain text elements render as native SwiftUI text runs.</td>
</tr>
<tr>
<td width="33.33%">&lt;tspan&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/text-tspan.png?v=animation-native" alt="&lt;tspan&gt;" width="144"></td>
<td width="33.33%">Text spans render with inherited and overridden paint.</td>
</tr>
<tr>
<td width="33.33%">&lt;textPath&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">TextPath references are parsed but text layout along paths is not painted.</td>
</tr>
<tr>
<td width="33.33%">text x/y/dx/dy</td>
<td width="33.33%"></td>
<td width="33.33%">Per-glyph text positioning lists are parsed but not painted.</td>
</tr>
<tr>
<td width="33.33%">text rotate</td>
<td width="33.33%"></td>
<td width="33.33%">Per-glyph text rotation is parsed but not painted.</td>
</tr>
<tr>
<td width="33.33%">text-anchor</td>
<td width="33.33%"><img src="docs/feature-gallery/png/text-anchor.png?v=animation-native" alt="text-anchor" width="144"></td>
<td width="33.33%">Start, middle, and end anchoring affect native text runs.</td>
</tr>
<tr>
<td width="33.33%">dominant-baseline</td>
<td width="33.33%"></td>
<td width="33.33%">Dominant baseline is parsed but not painted.</td>
</tr>
<tr>
<td width="33.33%">alignment-baseline</td>
<td width="33.33%"></td>
<td width="33.33%">Alignment baseline is parsed but not painted.</td>
</tr>
<tr>
<td width="33.33%">white-space</td>
<td width="33.33%"><img src="docs/feature-gallery/png/white-space.png?v=animation-native" alt="white-space" width="144"></td>
<td width="33.33%">Preserved whitespace is passed through to native text drawing.</td>
</tr>
</tbody>
</table>

## Reuse, Linking, and Markers

<table width="100%">
<colgroup>
<col width="33.33%">
<col width="33.33%">
<col width="33.33%">
</colgroup>
<thead>
<tr>
<th>Feature</th>
<th>Preview</th>
<th>Notes</th>
</tr>
</thead>
<tbody>
<tr>
<td width="33.33%">href</td>
<td width="33.33%"><img src="docs/feature-gallery/png/href-use.png?v=animation-native" alt="href" width="144"></td>
<td width="33.33%">Unprefixed href works for simple &lt;use&gt; references.</td>
</tr>
<tr>
<td width="33.33%">xlink:href</td>
<td width="33.33%"><img src="docs/feature-gallery/png/xlink-href-use.png?v=animation-native" alt="xlink:href" width="144"></td>
<td width="33.33%">Deprecated xlink:href is preserved and works for simple &lt;use&gt; references.</td>
</tr>
<tr>
<td width="33.33%">&lt;marker&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/marker-element.png?v=animation-native" alt="&lt;marker&gt;" width="144"></td>
<td width="33.33%">Marker definitions render when referenced by path geometry.</td>
</tr>
<tr>
<td width="33.33%">marker-start</td>
<td width="33.33%"><img src="docs/feature-gallery/png/marker-start.png?v=animation-native" alt="marker-start" width="144"></td>
<td width="33.33%">Start markers paint at the first path vertex.</td>
</tr>
<tr>
<td width="33.33%">marker-mid</td>
<td width="33.33%"><img src="docs/feature-gallery/png/marker-mid.png?v=animation-native" alt="marker-mid" width="144"></td>
<td width="33.33%">Mid markers paint at interior vertices.</td>
</tr>
<tr>
<td width="33.33%">marker-end</td>
<td width="33.33%"><img src="docs/feature-gallery/png/marker-end.png?v=animation-native" alt="marker-end" width="144"></td>
<td width="33.33%">End markers paint at the final path vertex.</td>
</tr>
<tr>
<td width="33.33%">marker orient</td>
<td width="33.33%"><img src="docs/feature-gallery/png/marker-orient.png?v=animation-native" alt="marker orient" width="144"></td>
<td width="33.33%">Auto marker orientation follows the path tangent.</td>
</tr>
<tr>
<td width="33.33%">markerUnits</td>
<td width="33.33%"><img src="docs/feature-gallery/png/marker-units.png?v=animation-native" alt="markerUnits" width="144"></td>
<td width="33.33%">Stroke-width marker units scale marker viewports with stroke width.</td>
</tr>
<tr>
<td width="33.33%">marker viewBox</td>
<td width="33.33%"><img src="docs/feature-gallery/png/marker-viewbox.png?v=animation-native" alt="marker viewBox" width="144"></td>
<td width="33.33%">Marker viewBox mapping fits marker children into the marker viewport.</td>
</tr>
</tbody>
</table>

## Embedded and Dynamic SVG

<table width="100%">
<colgroup>
<col width="33.33%">
<col width="33.33%">
<col width="33.33%">
</colgroup>
<thead>
<tr>
<th>Feature</th>
<th>Preview</th>
<th>Notes</th>
</tr>
</thead>
<tbody>
<tr>
<td width="33.33%">&lt;foreignObject&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">The container's SVG children can render; embedded HTML is not painted.</td>
</tr>
<tr>
<td width="33.33%">&lt;animate&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/animate.png?v=animation-native" alt="&lt;animate&gt;" width="144"></td>
<td width="33.33%">Clock-based numeric animate values render on the native timeline.</td>
</tr>
<tr>
<td width="33.33%">&lt;animateMotion&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Motion animation is parsed but not executed.</td>
</tr>
<tr>
<td width="33.33%">&lt;animateTransform&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/animate-transform.png?v=animation-native" alt="&lt;animateTransform&gt;" width="144"></td>
<td width="33.33%">Clock-based transform animation renders for common transform types.</td>
</tr>
<tr>
<td width="33.33%">&lt;set&gt;</td>
<td width="33.33%"><img src="docs/feature-gallery/png/set-animation.png?v=animation-native" alt="&lt;set&gt;" width="144"></td>
<td width="33.33%">Set animation applies active presentation values at clock begin times.</td>
</tr>
<tr>
<td width="33.33%">&lt;discard&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Discard elements are parsed but do not remove rendered content.</td>
</tr>
<tr>
<td width="33.33%">&lt;mpath&gt;</td>
<td width="33.33%"></td>
<td width="33.33%">Motion path references are parsed but not animated.</td>
</tr>
</tbody>
</table>
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

## Displaying SVG

Use `SVG` when you already have an `SVGDocument`:

```swift
import SwiftUI
import Swg

struct IconPreview: View {
	let document: SVGDocument

	var body: some View {
		SVG(document)
			.frame(width: 120, height: 120)
	}
}
```

You can also construct a view directly from SVG source:

```swift
let source = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
	<circle id="dot" cx="12" cy="12" r="6" fill="#336699"/>
</svg>
"""

if let view = SVG(source: source) {
	view.frame(width: 48, height: 48)
}
```

Or let the view load SVG XML after it appears:

```swift
SVG("checkmark")
SVG("Icons/checkmark.svg", bundle: .main)
SVG(url: URL(string: "https://example.com/icons/check.svg")!)
SVG(file: cachedSVGURL)
```

Use the `document` binding variants when the parsed document should become part of your app state:

```swift
struct RemoteIcon: View {
	let iconURL: URL
	@State private var document: SVGDocument?

	var body: some View {
		SVG(url: iconURL, document: $document)
			.onChange(of: document) { _, document in
				guard let document else { return }
				self.document = document.modifyingElement(id: "mark") { element in
					element.modifyingAttributes { attributes in
						attributes.stroke = .color(.red)
					}
				}
			}
	}
}
```

`SVGRenderOptions` controls SwiftUI layout and root mapping:

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

The current renderer supports native drawing for paths, rectangles, circles, ellipses, lines, polygons, polylines, groups, links, nested SVG viewports, `switch`, `foreignObject` SVG children, unknown SVG containers, simple `use` references, linear gradients, radial gradients, gradient spread modes, simple pattern fills, and local clip paths. Unsupported advanced effects are preserved in the model but skipped by the SwiftUI renderer for now.

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

## Controlling the Document

`SVGDocument` is regular Swift data. You can look up elements by `id`, map the tree, and edit presentation attributes before rendering:

```swift
let highlighted = document.modifyingElement(id: "mark") { element in
	element.modifyingAttributes { attributes in
		attributes.stroke = .color(.red)
		attributes.strokeWidth = 3
		attributes.transform = attributes.transform.scaledBy(x: 1.15, y: 1.15)
	}
}

SVG(highlighted)
```

For broad changes, map every element recursively:

```swift
let muted = document.mapElements { element in
	element.modifyingAttributes { attributes in
		attributes.opacity *= 0.5
	}
}
```

This is the intended control surface for stateful SwiftUI usage: keep the source SVG as a parsed document, derive edited copies from app state, then render the copy with `SVG`.

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
	let cgPath = path.cgPath
	print(cgPath.boundingBox)
}
```

These helpers are the geometry bridge used by the SwiftUI renderer and by callers that want to feed SVG geometry into CoreGraphics directly.

## Validation

Run the package's iOS simulator test gate with:

```sh
xcodebuild test -scheme swg -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

The suite contains focused parser/model tests, public rendering API tests, document-control tests, and fixture-backed visual tests.

## Documentation

API and conceptual reference lives in the DocC catalog at `Sources/Swg/Documentation.docc`. In Xcode, build documentation for the `swg` scheme to browse the module reference.
