# swg

Swift Vector Graphics. `swg` is an independent Swift package for parsing SVG files into a strongly typed model, converting supported geometry into `CGPath`, editing the parsed document tree, and displaying SVG content with `SVG` in SwiftUI.

The package has no third-party dependencies. XML parsing uses Foundation's `XMLParser`, with `FoundationXML` imported on platforms where that module is split out.

## Status

The parser is built around the SVG 2 specification and is tracked by a test-gated checklist in [TODO.md](TODO.md). A checklist item is checked only when there is a focused test for that feature.

Current coverage is strongest in parser/model behavior. The native SwiftUI renderer displays the shape/path/container subset that can already map through `CGPath`; browser-equivalent rendering for text, gradients, filters, masks, clipping, markers, images, and animation is still renderer work in progress even though much of that structure is parsed and modeled.

The matrix below shows one SVG example per visual feature. Each source SVG is parsed by `swg` and rendered to PNG through the package's `SVG` SwiftUI view.

## SVG View Visual Feature Matrix

These images are generated from one SVG per visual feature by `docs/FeatureGallery.playground/Contents.swift`. The playground writes the source SVGs to `docs/feature-gallery/svg`, parses them with `swg`, renders them through the public `SVG` SwiftUI view, and writes PNGs to `docs/feature-gallery/png`.

The parser/model checklist remains in [TODO.md](TODO.md). This matrix is specifically the native SwiftUI renderer truth table: 133 visual examples, 59 rendered, 1 partial, 6 static-only animation records, and 67 model-only features.

Not actually rendering yet: gradients and patterns, clipping, masking, filter primitives, native text, markers, vector-effect stroke behavior, rendering hints, embedded HTML inside `foreignObject`, and live animation. Those features are still valuable in the model, but the current `SVG` view either skips them or paints only the static/base geometry.

| Category | Feature | Renderer | Preview | Notes |
| --- | --- | --- | --- | --- |
| Document and Containers | Nested &lt;svg&gt; viewport | Rendered | <img src="docs/feature-gallery/png/nested-svg-viewport.png" alt="Nested &lt;svg&gt; viewport" width="96"> | Nested SVG children paint inside their own viewport. |
| Document and Containers | viewBox meet | Rendered | <img src="docs/feature-gallery/png/viewbox-preserve-meet.png" alt="viewBox meet" width="96"> | The document is uniformly fitted into the viewport. |
| Document and Containers | preserveAspectRatio none | Rendered | <img src="docs/feature-gallery/png/preserve-aspect-none.png" alt="preserveAspectRatio none" width="96"> | The nested viewport uses non-uniform scaling. |
| Document and Containers | preserveAspectRatio slice | Rendered | <img src="docs/feature-gallery/png/preserve-aspect-slice.png" alt="preserveAspectRatio slice" width="96"> | The nested viewport covers and crops the viewBox. |
| Document and Containers | &lt;g&gt; | Rendered | <img src="docs/feature-gallery/png/group-container.png" alt="&lt;g&gt;" width="96"> | Groups apply transforms and inherited paint to children. |
| Document and Containers | &lt;defs&gt; | Rendered | <img src="docs/feature-gallery/png/defs-hidden.png" alt="&lt;defs&gt;" width="96"> | Definitions stay hidden until referenced. |
| Document and Containers | &lt;symbol&gt; + &lt;use&gt; | Rendered | <img src="docs/feature-gallery/png/symbol-use.png" alt="&lt;symbol&gt; + &lt;use&gt;" width="96"> | Simple symbol references render through &lt;use&gt;. |
| Document and Containers | &lt;switch&gt; | Rendered | <img src="docs/feature-gallery/png/switch-container.png" alt="&lt;switch&gt;" width="96"> | The selected switch child renders as a normal container. |
| Document and Containers | &lt;a&gt; | Rendered | <img src="docs/feature-gallery/png/link-container.png" alt="&lt;a&gt;" width="96"> | Links render their SVG children; interaction metadata is preserved separately. |
| Document and Containers | &lt;view&gt; | Model only | <img src="docs/feature-gallery/png/view-element.png" alt="&lt;view&gt;" width="96"> | Predefined views are parsed but are not drawable content. |
| Basic Shapes | &lt;path&gt; element | Rendered | <img src="docs/feature-gallery/png/shape-path.png" alt="&lt;path&gt; element" width="96"> | Path elements render through CGPath. |
| Basic Shapes | &lt;rect&gt; | Rendered | <img src="docs/feature-gallery/png/shape-rect.png" alt="&lt;rect&gt;" width="96"> | Rectangles render with fill and stroke. |
| Basic Shapes | &lt;rect rx&gt; | Rendered | <img src="docs/feature-gallery/png/shape-rounded-rx.png" alt="&lt;rect rx&gt;" width="96"> | Rounded x radius is converted into the path. |
| Basic Shapes | &lt;rect ry&gt; | Rendered | <img src="docs/feature-gallery/png/shape-rounded-ry.png" alt="&lt;rect ry&gt;" width="96"> | Rounded y radius is converted into the path. |
| Basic Shapes | &lt;circle&gt; | Rendered | <img src="docs/feature-gallery/png/shape-circle.png" alt="&lt;circle&gt;" width="96"> | Circles render as CGPath ellipses. |
| Basic Shapes | &lt;ellipse&gt; | Rendered | <img src="docs/feature-gallery/png/shape-ellipse.png" alt="&lt;ellipse&gt;" width="96"> | Ellipses render as CGPath ellipses. |
| Basic Shapes | &lt;line&gt; | Rendered | <img src="docs/feature-gallery/png/shape-line.png" alt="&lt;line&gt;" width="96"> | Lines render as stroked paths. |
| Basic Shapes | &lt;polyline&gt; | Rendered | <img src="docs/feature-gallery/png/shape-polyline.png" alt="&lt;polyline&gt;" width="96"> | Polylines render as open stroked paths. |
| Basic Shapes | &lt;polygon&gt; | Rendered | <img src="docs/feature-gallery/png/shape-polygon.png" alt="&lt;polygon&gt;" width="96"> | Polygons render as closed paths. |
| Path Data | M/L commands | Rendered | <img src="docs/feature-gallery/png/path-move-line.png" alt="M/L commands" width="96"> | Moveto and lineto path commands paint. |
| Path Data | H command | Rendered | <img src="docs/feature-gallery/png/path-horizontal.png" alt="H command" width="96"> | Horizontal line commands paint. |
| Path Data | V command | Rendered | <img src="docs/feature-gallery/png/path-vertical.png" alt="V command" width="96"> | Vertical line commands paint. |
| Path Data | C command | Rendered | <img src="docs/feature-gallery/png/path-cubic.png" alt="C command" width="96"> | Cubic Bezier commands paint. |
| Path Data | S command | Rendered | <img src="docs/feature-gallery/png/path-smooth-cubic.png" alt="S command" width="96"> | Smooth cubic commands paint after cubic control reflection. |
| Path Data | Q command | Rendered | <img src="docs/feature-gallery/png/path-quadratic.png" alt="Q command" width="96"> | Quadratic Bezier commands paint. |
| Path Data | T command | Rendered | <img src="docs/feature-gallery/png/path-smooth-quadratic.png" alt="T command" width="96"> | Smooth quadratic commands paint. |
| Path Data | A command | Rendered | <img src="docs/feature-gallery/png/path-arc.png" alt="A command" width="96"> | Elliptical arcs are converted to cubic path segments. |
| Path Data | Z command | Rendered | <img src="docs/feature-gallery/png/path-close.png" alt="Z command" width="96"> | Closepath fills and closes the outline. |
| Path Data | Implicit repeated commands | Rendered | <img src="docs/feature-gallery/png/path-implicit-repeated.png" alt="Implicit repeated commands" width="96"> | Repeated command parameters become additional path segments. |
| Coordinate Systems and Transforms | matrix() | Rendered | <img src="docs/feature-gallery/png/transform-matrix.png" alt="matrix()" width="96"> | Matrix transforms are applied before painting. |
| Coordinate Systems and Transforms | translate() | Rendered | <img src="docs/feature-gallery/png/transform-translate.png" alt="translate()" width="96"> | Translation moves rendered geometry. |
| Coordinate Systems and Transforms | scale() | Rendered | <img src="docs/feature-gallery/png/transform-scale.png" alt="scale()" width="96"> | Scaling affects the painted path. |
| Coordinate Systems and Transforms | rotate(angle) | Rendered | <img src="docs/feature-gallery/png/transform-rotate.png" alt="rotate(angle)" width="96"> | Rotation around the origin is applied. |
| Coordinate Systems and Transforms | rotate(angle cx cy) | Rendered | <img src="docs/feature-gallery/png/transform-rotate-center.png" alt="rotate(angle cx cy)" width="96"> | Centered rotation is applied around the provided pivot. |
| Coordinate Systems and Transforms | skewX() | Rendered | <img src="docs/feature-gallery/png/transform-skew-x.png" alt="skewX()" width="96"> | Horizontal skew transforms paint. |
| Coordinate Systems and Transforms | skewY() | Rendered | <img src="docs/feature-gallery/png/transform-skew-y.png" alt="skewY()" width="96"> | Vertical skew transforms paint. |
| Coordinate Systems and Transforms | vector-effect | Model only | <img src="docs/feature-gallery/png/vector-effect.png" alt="vector-effect" width="96"> | Vector-effect is parsed but the renderer does not keep strokes non-scaling. |
| Styling and Cascade | Inline style | Rendered | <img src="docs/feature-gallery/png/style-inline.png" alt="Inline style" width="96"> | Inline style declarations feed native paint attributes. |
| Styling and Cascade | &lt;style&gt; | Rendered | <img src="docs/feature-gallery/png/style-element.png" alt="&lt;style&gt;" width="96"> | Simple matching style rules affect painted geometry. |
| Styling and Cascade | &lt;style media&gt; | Rendered | <img src="docs/feature-gallery/png/style-media.png" alt="&lt;style media&gt;" width="96"> | Matching media-filtered rules are applied by the parser. |
| Painting | fill | Rendered | <img src="docs/feature-gallery/png/paint-fill.png" alt="fill" width="96"> | Solid fill paint renders. |
| Painting | fill-opacity | Rendered | <img src="docs/feature-gallery/png/paint-fill-opacity.png" alt="fill-opacity" width="96"> | Fill opacity multiplies solid paint. |
| Painting | fill-rule nonzero | Rendered | <img src="docs/feature-gallery/png/paint-fill-rule-nonzero.png" alt="fill-rule nonzero" width="96"> | Nonzero fill rule paints nested winding normally. |
| Painting | fill-rule evenodd | Rendered | <img src="docs/feature-gallery/png/paint-fill-rule-evenodd.png" alt="fill-rule evenodd" width="96"> | Even-odd fill rule cuts out the inner path. |
| Painting | stroke | Rendered | <img src="docs/feature-gallery/png/paint-stroke.png" alt="stroke" width="96"> | Solid stroke paint renders. |
| Painting | stroke-width | Rendered | <img src="docs/feature-gallery/png/paint-stroke-width.png" alt="stroke-width" width="96"> | Stroke width affects painted outlines. |
| Painting | stroke-opacity | Rendered | <img src="docs/feature-gallery/png/paint-stroke-opacity.png" alt="stroke-opacity" width="96"> | Stroke opacity multiplies stroke paint. |
| Painting | stroke-linecap butt | Rendered | <img src="docs/feature-gallery/png/paint-linecap-butt.png" alt="stroke-linecap butt" width="96"> | Butt caps end exactly on the path endpoints. |
| Painting | stroke-linecap round | Rendered | <img src="docs/feature-gallery/png/paint-linecap-round.png" alt="stroke-linecap round" width="96"> | Round caps extend the path with semicircles. |
| Painting | stroke-linecap square | Rendered | <img src="docs/feature-gallery/png/paint-linecap-square.png" alt="stroke-linecap square" width="96"> | Square caps extend the path with square ends. |
| Painting | stroke-linejoin miter | Rendered | <img src="docs/feature-gallery/png/paint-linejoin-miter.png" alt="stroke-linejoin miter" width="96"> | Miter joins create pointed corners. |
| Painting | stroke-linejoin round | Rendered | <img src="docs/feature-gallery/png/paint-linejoin-round.png" alt="stroke-linejoin round" width="96"> | Round joins create curved corners. |
| Painting | stroke-linejoin bevel | Rendered | <img src="docs/feature-gallery/png/paint-linejoin-bevel.png" alt="stroke-linejoin bevel" width="96"> | Bevel joins flatten corners. |
| Painting | stroke-miterlimit | Rendered | <img src="docs/feature-gallery/png/paint-miterlimit.png" alt="stroke-miterlimit" width="96"> | Miter limit affects sharp stroked corners. |
| Painting | stroke-dasharray | Rendered | <img src="docs/feature-gallery/png/paint-dasharray.png" alt="stroke-dasharray" width="96"> | Dash arrays are passed to SwiftUI stroke style. |
| Painting | stroke-dashoffset | Rendered | <img src="docs/feature-gallery/png/paint-dashoffset.png" alt="stroke-dashoffset" width="96"> | Dash offsets shift the dash phase. |
| Painting | paint-order | Rendered | <img src="docs/feature-gallery/png/paint-order.png" alt="paint-order" width="96"> | Paint order is honored for fill and stroke; marker painting is skipped. |
| Painting | currentColor | Rendered | <img src="docs/feature-gallery/png/paint-current-color.png" alt="currentColor" width="96"> | currentColor resolves into fill or stroke paint. |
| Painting | rendering hints | Model only | <img src="docs/feature-gallery/png/paint-rendering-hints.png" alt="rendering hints" width="96"> | Color, shape, text, and image rendering hints are parsed but do not change native output. |
| Gradients and Patterns | &lt;linearGradient&gt; | Model only | <img src="docs/feature-gallery/png/gradient-linear.png" alt="&lt;linearGradient&gt;" width="96"> | URL paint servers are parsed but skipped by the renderer. |
| Gradients and Patterns | &lt;radialGradient&gt; | Model only | <img src="docs/feature-gallery/png/gradient-radial.png" alt="&lt;radialGradient&gt;" width="96"> | Radial gradient paint is parsed but not painted. |
| Gradients and Patterns | &lt;stop&gt; offset | Model only | <img src="docs/feature-gallery/png/gradient-stop-offset.png" alt="&lt;stop&gt; offset" width="96"> | Stop offsets are model data until gradient rendering exists. |
| Gradients and Patterns | stop-opacity | Model only | <img src="docs/feature-gallery/png/gradient-stop-opacity.png" alt="stop-opacity" width="96"> | Stop opacity is parsed but has no effect without gradient paint. |
| Gradients and Patterns | gradientUnits objectBoundingBox | Model only | <img src="docs/feature-gallery/png/gradient-object-bounding-box.png" alt="gradientUnits objectBoundingBox" width="96"> | Object-bounding-box gradient units are preserved but not rendered. |
| Gradients and Patterns | gradientUnits userSpaceOnUse | Model only | <img src="docs/feature-gallery/png/gradient-user-space.png" alt="gradientUnits userSpaceOnUse" width="96"> | User-space gradient units are preserved but not rendered. |
| Gradients and Patterns | gradientTransform | Model only | <img src="docs/feature-gallery/png/gradient-transform.png" alt="gradientTransform" width="96"> | Gradient transforms are parsed but skipped by native paint. |
| Gradients and Patterns | spreadMethod pad | Model only | <img src="docs/feature-gallery/png/gradient-spread-pad.png" alt="spreadMethod pad" width="96"> | Spread methods are parsed but not rendered. |
| Gradients and Patterns | spreadMethod reflect | Model only | <img src="docs/feature-gallery/png/gradient-spread-reflect.png" alt="spreadMethod reflect" width="96"> | Reflect spread is model-only today. |
| Gradients and Patterns | spreadMethod repeat | Model only | <img src="docs/feature-gallery/png/gradient-spread-repeat.png" alt="spreadMethod repeat" width="96"> | Repeat spread is model-only today. |
| Gradients and Patterns | &lt;pattern&gt; | Model only | <img src="docs/feature-gallery/png/pattern.png" alt="&lt;pattern&gt;" width="96"> | Pattern paint servers are parsed but skipped. |
| Gradients and Patterns | patternContentUnits | Model only | <img src="docs/feature-gallery/png/pattern-content-units.png" alt="patternContentUnits" width="96"> | Pattern content unit mapping is preserved but not painted. |
| Clipping, Masking, and Compositing | &lt;clipPath&gt; | Model only | <img src="docs/feature-gallery/png/clip-path-element.png" alt="&lt;clipPath&gt;" width="96"> | Clip path definitions are parsed but not applied. |
| Clipping, Masking, and Compositing | clip-path | Model only | <img src="docs/feature-gallery/png/clip-path-property.png" alt="clip-path" width="96"> | The clip-path property is parsed but ignored by the renderer. |
| Clipping, Masking, and Compositing | clip-rule | Model only | <img src="docs/feature-gallery/png/clip-rule.png" alt="clip-rule" width="96"> | Clip-rule is preserved, but clipping itself is not applied. |
| Clipping, Masking, and Compositing | clipPathUnits | Model only | <img src="docs/feature-gallery/png/clip-path-units.png" alt="clipPathUnits" width="96"> | Clip path units are model-only today. |
| Clipping, Masking, and Compositing | &lt;mask&gt; | Model only | <img src="docs/feature-gallery/png/mask-element.png" alt="&lt;mask&gt;" width="96"> | Mask definitions are parsed but not applied. |
| Clipping, Masking, and Compositing | mask | Model only | <img src="docs/feature-gallery/png/mask-property.png" alt="mask" width="96"> | The mask property is parsed but ignored by native drawing. |
| Clipping, Masking, and Compositing | maskUnits | Model only | <img src="docs/feature-gallery/png/mask-units.png" alt="maskUnits" width="96"> | Mask units are preserved but not rendered. |
| Clipping, Masking, and Compositing | maskContentUnits | Model only | <img src="docs/feature-gallery/png/mask-content-units.png" alt="maskContentUnits" width="96"> | Mask content units are model-only today. |
| Clipping, Masking, and Compositing | opacity | Rendered | <img src="docs/feature-gallery/png/opacity.png" alt="opacity" width="96"> | Element and group opacity are applied while rendering. |
| Filters | &lt;filter&gt; | Model only | <img src="docs/feature-gallery/png/filter-element.png" alt="&lt;filter&gt;" width="96"> | filter="url(...)" is parsed but no filter graph is applied. |
| Filters | filterUnits | Model only | <img src="docs/feature-gallery/png/filter-units.png" alt="filterUnits" width="96"> | Filter coordinate units are parsed but not applied. |
| Filters | primitiveUnits | Model only | <img src="docs/feature-gallery/png/primitive-units.png" alt="primitiveUnits" width="96"> | Primitive coordinate units are parsed but not applied. |
| Filters | &lt;feGaussianBlur&gt; | Model only | <img src="docs/feature-gallery/png/fe-gaussian-blur.png" alt="&lt;feGaussianBlur&gt;" width="96"> | Blur primitives are model-only today. |
| Filters | &lt;feDropShadow&gt; | Model only | <img src="docs/feature-gallery/png/fe-drop-shadow.png" alt="&lt;feDropShadow&gt;" width="96"> | Drop shadows are parsed but not rendered. |
| Filters | &lt;feBlend&gt; | Model only | <img src="docs/feature-gallery/png/fe-blend.png" alt="&lt;feBlend&gt;" width="96"> | Blend primitives are preserved but skipped. |
| Filters | &lt;feColorMatrix&gt; | Model only | <img src="docs/feature-gallery/png/fe-color-matrix.png" alt="&lt;feColorMatrix&gt;" width="96"> | Color matrix primitives are preserved but skipped. |
| Filters | &lt;feComponentTransfer&gt; | Model only | <img src="docs/feature-gallery/png/fe-component-transfer.png" alt="&lt;feComponentTransfer&gt;" width="96"> | Component transfer primitives are preserved but skipped. |
| Filters | &lt;feFuncR&gt; | Model only | <img src="docs/feature-gallery/png/fe-func-r.png" alt="&lt;feFuncR&gt;" width="96"> | Red channel transfer functions are model-only. |
| Filters | &lt;feFuncG&gt; | Model only | <img src="docs/feature-gallery/png/fe-func-g.png" alt="&lt;feFuncG&gt;" width="96"> | Green channel transfer functions are model-only. |
| Filters | &lt;feFuncB&gt; | Model only | <img src="docs/feature-gallery/png/fe-func-b.png" alt="&lt;feFuncB&gt;" width="96"> | Blue channel transfer functions are model-only. |
| Filters | &lt;feFuncA&gt; | Model only | <img src="docs/feature-gallery/png/fe-func-a.png" alt="&lt;feFuncA&gt;" width="96"> | Alpha channel transfer functions are model-only. |
| Filters | &lt;feComposite&gt; | Model only | <img src="docs/feature-gallery/png/fe-composite.png" alt="&lt;feComposite&gt;" width="96"> | Composite primitives are preserved but skipped. |
| Filters | &lt;feConvolveMatrix&gt; | Model only | <img src="docs/feature-gallery/png/fe-convolve-matrix.png" alt="&lt;feConvolveMatrix&gt;" width="96"> | Convolution primitives are model-only. |
| Filters | &lt;feDiffuseLighting&gt; | Model only | <img src="docs/feature-gallery/png/fe-diffuse-lighting.png" alt="&lt;feDiffuseLighting&gt;" width="96"> | Diffuse lighting primitives are model-only. |
| Filters | &lt;feDisplacementMap&gt; | Model only | <img src="docs/feature-gallery/png/fe-displacement-map.png" alt="&lt;feDisplacementMap&gt;" width="96"> | Displacement map primitives are model-only. |
| Filters | &lt;feDistantLight&gt; | Model only | <img src="docs/feature-gallery/png/fe-distant-light.png" alt="&lt;feDistantLight&gt;" width="96"> | Distant light data is parsed inside lighting filters only. |
| Filters | &lt;feFlood&gt; | Model only | <img src="docs/feature-gallery/png/fe-flood.png" alt="&lt;feFlood&gt;" width="96"> | Flood primitives are preserved but not rendered. |
| Filters | &lt;feImage&gt; | Model only | <img src="docs/feature-gallery/png/fe-image.png" alt="&lt;feImage&gt;" width="96"> | Filter image primitives are model-only. |
| Filters | &lt;feMerge&gt; | Model only | <img src="docs/feature-gallery/png/fe-merge.png" alt="&lt;feMerge&gt;" width="96"> | Merge primitives are preserved but skipped. |
| Filters | &lt;feMergeNode&gt; | Model only | <img src="docs/feature-gallery/png/fe-merge-node.png" alt="&lt;feMergeNode&gt;" width="96"> | Merge node ordering is model-only. |
| Filters | &lt;feMorphology&gt; | Model only | <img src="docs/feature-gallery/png/fe-morphology.png" alt="&lt;feMorphology&gt;" width="96"> | Morphology primitives are preserved but skipped. |
| Filters | &lt;feOffset&gt; | Model only | <img src="docs/feature-gallery/png/fe-offset.png" alt="&lt;feOffset&gt;" width="96"> | Offset primitives are preserved but skipped. |
| Filters | &lt;fePointLight&gt; | Model only | <img src="docs/feature-gallery/png/fe-point-light.png" alt="&lt;fePointLight&gt;" width="96"> | Point light data is parsed inside lighting filters only. |
| Filters | &lt;feSpecularLighting&gt; | Model only | <img src="docs/feature-gallery/png/fe-specular-lighting.png" alt="&lt;feSpecularLighting&gt;" width="96"> | Specular lighting primitives are model-only. |
| Filters | &lt;feSpotLight&gt; | Model only | <img src="docs/feature-gallery/png/fe-spot-light.png" alt="&lt;feSpotLight&gt;" width="96"> | Spot light data is parsed inside lighting filters only. |
| Filters | &lt;feTile&gt; | Model only | <img src="docs/feature-gallery/png/fe-tile.png" alt="&lt;feTile&gt;" width="96"> | Tile primitives are model-only. |
| Filters | &lt;feTurbulence&gt; | Model only | <img src="docs/feature-gallery/png/fe-turbulence.png" alt="&lt;feTurbulence&gt;" width="96"> | Turbulence primitives are model-only. |
| Text | &lt;text&gt; | Model only | <img src="docs/feature-gallery/png/text-element.png" alt="&lt;text&gt;" width="96"> | Text elements are parsed but native text painting is not implemented. |
| Text | &lt;tspan&gt; | Model only | <img src="docs/feature-gallery/png/text-tspan.png" alt="&lt;tspan&gt;" width="96"> | Text spans are parsed but not painted. |
| Text | &lt;textPath&gt; | Model only | <img src="docs/feature-gallery/png/text-path.png" alt="&lt;textPath&gt;" width="96"> | TextPath references are parsed but text layout along paths is not painted. |
| Text | text x/y/dx/dy | Model only | <img src="docs/feature-gallery/png/text-positioning.png" alt="text x/y/dx/dy" width="96"> | Text positioning lists are model-only until text rendering exists. |
| Text | text rotate | Model only | <img src="docs/feature-gallery/png/text-rotate.png" alt="text rotate" width="96"> | Per-glyph text rotation is parsed but not painted. |
| Text | text-anchor | Model only | <img src="docs/feature-gallery/png/text-anchor.png" alt="text-anchor" width="96"> | Text anchoring is parsed but not painted. |
| Text | dominant-baseline | Model only | <img src="docs/feature-gallery/png/dominant-baseline.png" alt="dominant-baseline" width="96"> | Dominant baseline is parsed but not painted. |
| Text | alignment-baseline | Model only | <img src="docs/feature-gallery/png/alignment-baseline.png" alt="alignment-baseline" width="96"> | Alignment baseline is parsed but not painted. |
| Text | white-space | Model only | <img src="docs/feature-gallery/png/white-space.png" alt="white-space" width="96"> | Text whitespace handling is parsed but not painted. |
| Reuse, Linking, and Markers | href | Rendered | <img src="docs/feature-gallery/png/href-use.png" alt="href" width="96"> | Unprefixed href works for simple &lt;use&gt; references. |
| Reuse, Linking, and Markers | xlink:href | Rendered | <img src="docs/feature-gallery/png/xlink-href-use.png" alt="xlink:href" width="96"> | Deprecated xlink:href is preserved and works for simple &lt;use&gt; references. |
| Reuse, Linking, and Markers | &lt;marker&gt; | Model only | <img src="docs/feature-gallery/png/marker-element.png" alt="&lt;marker&gt;" width="96"> | Marker definitions are parsed but marker painting is skipped. |
| Reuse, Linking, and Markers | marker-start | Model only | <img src="docs/feature-gallery/png/marker-start.png" alt="marker-start" width="96"> | Start markers are parsed but not painted. |
| Reuse, Linking, and Markers | marker-mid | Model only | <img src="docs/feature-gallery/png/marker-mid.png" alt="marker-mid" width="96"> | Mid markers are parsed but not painted. |
| Reuse, Linking, and Markers | marker-end | Model only | <img src="docs/feature-gallery/png/marker-end.png" alt="marker-end" width="96"> | End markers are parsed but not painted. |
| Reuse, Linking, and Markers | marker orient | Model only | <img src="docs/feature-gallery/png/marker-orient.png" alt="marker orient" width="96"> | Marker orientation is parsed but has no renderer effect. |
| Reuse, Linking, and Markers | markerUnits | Model only | <img src="docs/feature-gallery/png/marker-units.png" alt="markerUnits" width="96"> | Marker unit scaling is parsed but not painted. |
| Reuse, Linking, and Markers | marker viewBox | Model only | <img src="docs/feature-gallery/png/marker-viewbox.png" alt="marker viewBox" width="96"> | Marker viewBox data is parsed but not rendered. |
| Embedded and Dynamic SVG | &lt;foreignObject&gt; | Partial | <img src="docs/feature-gallery/png/foreign-object.png" alt="&lt;foreignObject&gt;" width="96"> | The container's SVG children can render; embedded HTML is not painted. |
| Embedded and Dynamic SVG | &lt;animate&gt; | Static only | <img src="docs/feature-gallery/png/animate.png" alt="&lt;animate&gt;" width="96"> | Animation records are parsed; the native view paints the initial static geometry only. |
| Embedded and Dynamic SVG | &lt;animateMotion&gt; | Static only | <img src="docs/feature-gallery/png/animate-motion.png" alt="&lt;animateMotion&gt;" width="96"> | Motion animation is parsed but not executed. |
| Embedded and Dynamic SVG | &lt;animateTransform&gt; | Static only | <img src="docs/feature-gallery/png/animate-transform.png" alt="&lt;animateTransform&gt;" width="96"> | Transform animation is parsed but not executed. |
| Embedded and Dynamic SVG | &lt;set&gt; | Static only | <img src="docs/feature-gallery/png/set-animation.png" alt="&lt;set&gt;" width="96"> | Set animation elements are parsed but do not mutate rendered output. |
| Embedded and Dynamic SVG | &lt;discard&gt; | Static only | <img src="docs/feature-gallery/png/discard-animation.png" alt="&lt;discard&gt;" width="96"> | Discard elements are parsed but do not remove rendered content. |
| Embedded and Dynamic SVG | &lt;mpath&gt; | Static only | <img src="docs/feature-gallery/png/mpath.png" alt="&lt;mpath&gt;" width="96"> | Motion path references are parsed but not animated. |

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

The current renderer supports native drawing for paths, rectangles, circles, ellipses, lines, polygons, polylines, groups, links, nested SVG viewports, `switch`, `foreignObject` SVG children, unknown SVG containers, and simple `use` references. Unsupported visual paint servers and advanced effects are preserved in the model but skipped by the SwiftUI renderer for now.

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
