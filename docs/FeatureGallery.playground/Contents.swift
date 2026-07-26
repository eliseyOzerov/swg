import CoreGraphics
import Foundation
import ImageIO
import Swg
import SwiftUI
import UniformTypeIdentifiers

struct FeatureExample {
	let slug: String
	let title: String
	let category: String
	let rendererStatus: RendererStatus
	let note: String
	let width: Int
	let height: Int
	let svg: String
}

enum RendererStatus: String {
	case rendered = "Rendered"
	case partial = "Partial"
	case modelOnly = "Model only"
	case staticOnly = "Static only"
}

let containerExamples = [
	example("nested-svg-viewport", "Nested <svg> viewport", "Document and Containers", .rendered, "Nested SVG children paint inside their own viewport.") {
		"""
		<svg x="28" y="18" width="64" height="44" viewBox="0 0 80 40" preserveAspectRatio="xMidYMid meet">
			<rect width="80" height="40" fill="#dbeafe"/>
			<circle cx="40" cy="20" r="16" fill="#2563eb"/>
		</svg>
		"""
	},
	example("viewbox-preserve-meet", "viewBox meet", "Document and Containers", .rendered, "The document is uniformly fitted into the viewport.") {
		"""
		<svg x="22" y="12" width="76" height="56" viewBox="0 0 80 40" preserveAspectRatio="xMidYMid meet">
			<rect width="80" height="40" fill="#dcfce7"/>
			<circle cx="20" cy="20" r="13" fill="#16a34a"/>
			<rect x="44" y="10" width="24" height="20" fill="#15803d"/>
		</svg>
		"""
	},
	example("preserve-aspect-none", "preserveAspectRatio none", "Document and Containers", .rendered, "The nested viewport uses non-uniform scaling.") {
		"""
		<svg x="24" y="12" width="72" height="56" viewBox="0 0 80 40" preserveAspectRatio="none">
			<rect width="80" height="40" fill="#fef3c7"/>
			<circle cx="40" cy="20" r="15" fill="#f97316"/>
		</svg>
		"""
	},
	example("preserve-aspect-slice", "preserveAspectRatio slice", "Document and Containers", .rendered, "The nested viewport covers and crops the viewBox.") {
		"""
		<svg x="26" y="12" width="68" height="56" viewBox="0 0 120 50" preserveAspectRatio="xMidYMid slice">
			<rect width="120" height="50" fill="#fce7f3"/>
			<circle cx="20" cy="25" r="16" fill="#db2777"/>
			<circle cx="100" cy="25" r="16" fill="#be185d"/>
		</svg>
		"""
	},
	example("group-container", "<g>", "Document and Containers", .rendered, "Groups apply transforms and inherited paint to children.") {
		"""
		<g transform="translate(28 18)" fill="#38bdf8" stroke="#075985" stroke-width="3">
			<rect width="28" height="28"/>
			<circle cx="54" cy="14" r="14"/>
		</g>
		"""
	},
	example("defs-hidden", "<defs>", "Document and Containers", .rendered, "Definitions stay hidden until referenced.") {
		"""
		<defs>
			<rect id="hidden-def" x="12" y="12" width="96" height="56" fill="#ef4444"/>
		</defs>
		<rect x="36" y="24" width="48" height="32" rx="8" fill="#22c55e"/>
		"""
	},
	example("symbol-use", "<symbol> + <use>", "Document and Containers", .rendered, "Simple symbol references render through <use>.") {
		"""
		<defs>
			<symbol id="spark" viewBox="0 0 64 64">
				<path d="M32 4 L40 24 L60 32 L40 40 L32 60 L24 40 L4 32 L24 24 Z" fill="#facc15" stroke="#92400e" stroke-width="4" stroke-linejoin="round"/>
			</symbol>
		</defs>
		<use href="#spark" x="22" y="12" width="34" height="34"/>
		<use href="#spark" x="64" y="26" width="38" height="38" transform="rotate(12 83 45)"/>
		"""
	},
	example("switch-container", "<switch>", "Document and Containers", .rendered, "The selected switch child renders as a normal container.") {
		"""
		<switch>
			<g>
				<rect x="24" y="20" width="72" height="40" rx="16" fill="#eef2ff"/>
				<circle cx="44" cy="40" r="10" fill="#6366f1"/>
				<path d="M62 40 H86" stroke="#475569" stroke-width="7" stroke-linecap="round"/>
			</g>
		</switch>
		"""
	},
	example("link-container", "<a>", "Document and Containers", .rendered, "Links render their SVG children; interaction metadata is preserved separately.") {
		"""
		<a href="https://www.w3.org/TR/SVG/">
			<rect x="24" y="18" width="72" height="44" rx="14" fill="#dbeafe" stroke="#60a5fa" stroke-width="3"/>
			<path d="M44 42 L56 30 L74 48" fill="none" stroke="#2563eb" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>
		</a>
		"""
	},
	example("view-element", "<view>", "Document and Containers", .modelOnly, "Predefined views are parsed but are not drawable content.") {
		"""
		<defs>
			<view id="detail" viewBox="20 20 60 40"/>
		</defs>
		<rect x="24" y="22" width="72" height="36" rx="10" fill="#e2e8f0" stroke="#94a3b8" stroke-width="3"/>
		"""
	},
]

let shapeExamples = [
	example("shape-path", "<path> element", "Basic Shapes", .rendered, "Path elements render through CGPath.") {
		##"<path d="M24 56 C36 18 66 18 96 56 Z" fill="#38bdf8" stroke="#075985" stroke-width="4"/>"##
	},
	example("shape-rect", "<rect>", "Basic Shapes", .rendered, "Rectangles render with fill and stroke.") {
		##"<rect x="24" y="18" width="72" height="44" fill="#38bdf8" stroke="#075985" stroke-width="4"/>"##
	},
	example("shape-rounded-rx", "<rect rx>", "Basic Shapes", .rendered, "Rounded x radius is converted into the path.") {
		##"<rect x="22" y="18" width="76" height="44" rx="16" fill="#22c55e" stroke="#14532d" stroke-width="4"/>"##
	},
	example("shape-rounded-ry", "<rect ry>", "Basic Shapes", .rendered, "Rounded y radius is converted into the path.") {
		##"<rect x="22" y="18" width="76" height="44" ry="18" fill="#fb7185" stroke="#881337" stroke-width="4"/>"##
	},
	example("shape-circle", "<circle>", "Basic Shapes", .rendered, "Circles render as CGPath ellipses.") {
		##"<circle cx="60" cy="40" r="24" fill="#f97316" stroke="#7c2d12" stroke-width="4"/>"##
	},
	example("shape-ellipse", "<ellipse>", "Basic Shapes", .rendered, "Ellipses render as CGPath ellipses.") {
		##"<ellipse cx="60" cy="40" rx="34" ry="20" fill="#a78bfa" stroke="#4c1d95" stroke-width="4"/>"##
	},
	example("shape-line", "<line>", "Basic Shapes", .rendered, "Lines render as stroked paths.") {
		##"<line x1="22" y1="58" x2="98" y2="22" stroke="#0f172a" stroke-width="8" stroke-linecap="round"/>"##
	},
	example("shape-polyline", "<polyline>", "Basic Shapes", .rendered, "Polylines render as open stroked paths.") {
		##"<polyline points="18,58 38,28 60,54 82,26 102,58" fill="none" stroke="#2563eb" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>"##
	},
	example("shape-polygon", "<polygon>", "Basic Shapes", .rendered, "Polygons render as closed paths.") {
		##"<polygon points="60,12 100,34 84,66 36,66 20,34" fill="#facc15" stroke="#713f12" stroke-width="4" stroke-linejoin="round"/>"##
	},
]

let pathExamples = [
	example("path-move-line", "M/L commands", "Path Data", .rendered, "Moveto and lineto path commands paint.") {
		##"<path d="M20 58 L48 22 L76 58 L100 30" fill="none" stroke="#2563eb" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>"##
	},
	example("path-horizontal", "H command", "Path Data", .rendered, "Horizontal line commands paint.") {
		##"<path d="M18 30 H102 M18 52 H82" fill="none" stroke="#16a34a" stroke-width="7" stroke-linecap="round"/>"##
	},
	example("path-vertical", "V command", "Path Data", .rendered, "Vertical line commands paint.") {
		##"<path d="M34 18 V62 M60 18 V62 M86 18 V62" fill="none" stroke="#f97316" stroke-width="7" stroke-linecap="round"/>"##
	},
	example("path-cubic", "C command", "Path Data", .rendered, "Cubic Bezier commands paint.") {
		##"<path d="M16 54 C28 12 54 12 66 42 C78 72 94 66 104 26" fill="none" stroke="#dc2626" stroke-width="7" stroke-linecap="round"/>"##
	},
	example("path-smooth-cubic", "S command", "Path Data", .rendered, "Smooth cubic commands paint after cubic control reflection.") {
		##"<path d="M14 48 C30 12 48 12 62 42 S92 72 106 30" fill="none" stroke="#e11d48" stroke-width="7" stroke-linecap="round"/>"##
	},
	example("path-quadratic", "Q command", "Path Data", .rendered, "Quadratic Bezier commands paint.") {
		##"<path d="M16 56 Q60 8 104 56" fill="none" stroke="#0891b2" stroke-width="7" stroke-linecap="round"/>"##
	},
	example("path-smooth-quadratic", "T command", "Path Data", .rendered, "Smooth quadratic commands paint.") {
		##"<path d="M14 54 Q36 18 58 48 T106 46" fill="none" stroke="#7c3aed" stroke-width="7" stroke-linecap="round"/>"##
	},
	example("path-arc", "A command", "Path Data", .rendered, "Elliptical arcs are converted to cubic path segments.") {
		##"<path d="M18 58 A42 30 0 0 1 102 58 M24 28 A34 16 0 1 0 92 28" fill="none" stroke="#f97316" stroke-width="6" stroke-linecap="round"/>"##
	},
	example("path-close", "Z command", "Path Data", .rendered, "Closepath fills and closes the outline.") {
		##"<path d="M24 60 L60 16 L96 60 Z" fill="#facc15" stroke="#713f12" stroke-width="4" stroke-linejoin="round"/>"##
	},
	example("path-implicit-repeated", "Implicit repeated commands", "Path Data", .rendered, "Repeated command parameters become additional path segments.") {
		##"<path d="M20 58 44 22 68 58 92 22" fill="none" stroke="#16a34a" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>"##
	},
]

let transformExamples = [
	example("transform-matrix", "matrix()", "Coordinate Systems and Transforms", .rendered, "Matrix transforms are applied before painting.") {
		##"<rect x="30" y="24" width="46" height="30" transform="matrix(1 0.18 -0.25 1 14 -4)" fill="#38bdf8" stroke="#075985" stroke-width="4"/>"##
	},
	example("transform-translate", "translate()", "Coordinate Systems and Transforms", .rendered, "Translation moves rendered geometry.") {
		##"<rect x="18" y="22" width="40" height="34" fill="#cbd5e1"/><rect x="18" y="22" width="40" height="34" transform="translate(42 0)" fill="#22c55e" stroke="#14532d" stroke-width="4"/>"##
	},
	example("transform-scale", "scale()", "Coordinate Systems and Transforms", .rendered, "Scaling affects the painted path.") {
		##"<rect x="34" y="26" width="26" height="20" transform="scale(1.55 1.25)" fill="#a855f7" stroke="#581c87" stroke-width="3"/>"##
	},
	example("transform-rotate", "rotate(angle)", "Coordinate Systems and Transforms", .rendered, "Rotation around the origin is applied.") {
		##"<rect x="34" y="16" width="44" height="30" transform="rotate(18)" fill="#facc15" stroke="#713f12" stroke-width="4"/>"##
	},
	example("transform-rotate-center", "rotate(angle cx cy)", "Coordinate Systems and Transforms", .rendered, "Centered rotation is applied around the provided pivot.") {
		##"<rect x="36" y="24" width="48" height="32" transform="rotate(24 60 40)" fill="#fb7185" stroke="#881337" stroke-width="4"/>"##
	},
	example("transform-skew-x", "skewX()", "Coordinate Systems and Transforms", .rendered, "Horizontal skew transforms paint.") {
		##"<rect x="34" y="22" width="52" height="36" transform="skewX(-18)" fill="#60a5fa" stroke="#1d4ed8" stroke-width="4"/>"##
	},
	example("transform-skew-y", "skewY()", "Coordinate Systems and Transforms", .rendered, "Vertical skew transforms paint.") {
		##"<rect x="34" y="22" width="52" height="36" transform="skewY(14)" fill="#34d399" stroke="#047857" stroke-width="4"/>"##
	},
	example("vector-effect", "vector-effect", "Coordinate Systems and Transforms", .modelOnly, "Vector-effect is parsed but the renderer does not keep strokes non-scaling.") {
		##"<path d="M24 40 H96" transform="scale(1 2)" vector-effect="non-scaling-stroke" stroke="#ef4444" stroke-width="8" stroke-linecap="round"/>"##
	},
]

let styleExamples = [
	example("style-inline", "Inline style", "Styling and Cascade", .rendered, "Inline style declarations feed native paint attributes.") {
		##"<rect x="24" y="18" width="72" height="44" style="fill:#22c55e;stroke:#14532d;stroke-width:4"/>"##
	},
	example("style-element", "<style>", "Styling and Cascade", .rendered, "Simple matching style rules affect painted geometry.") {
		##"<style>.chip{fill:#38bdf8;stroke:#075985;stroke-width:4}</style><rect class="chip" x="24" y="18" width="72" height="44" rx="14"/>"##
	},
	example("style-media", "<style media>", "Styling and Cascade", .rendered, "Matching media-filtered rules are applied by the parser.") {
		##"<style media="all">.media{fill:#f97316;stroke:#7c2d12;stroke-width:4}</style><circle class="media" cx="60" cy="40" r="24"/>"##
	},
]

let paintExamples = [
	example("paint-fill", "fill", "Painting", .rendered, "Solid fill paint renders.") {
		##"<rect x="24" y="18" width="72" height="44" fill="#38bdf8"/>"##
	},
	example("paint-fill-opacity", "fill-opacity", "Painting", .rendered, "Fill opacity multiplies solid paint.") {
		##"<circle cx="48" cy="40" r="26" fill="#ef4444" fill-opacity="0.7"/><circle cx="72" cy="40" r="26" fill="#3b82f6" fill-opacity="0.7"/>"##
	},
	example("paint-fill-rule-nonzero", "fill-rule nonzero", "Painting", .rendered, "Nonzero fill rule paints nested winding normally.") {
		##"<path d="M20 14 H100 V66 H20 Z M38 30 H82 V50 H38 Z" fill="#a855f7" fill-rule="nonzero" opacity="0.82"/>"##
	},
	example("paint-fill-rule-evenodd", "fill-rule evenodd", "Painting", .rendered, "Even-odd fill rule cuts out the inner path.") {
		##"<path d="M20 14 H100 V66 H20 Z M38 30 H82 V50 H38 Z" fill="#a855f7" fill-rule="evenodd" opacity="0.82"/>"##
	},
	example("paint-stroke", "stroke", "Painting", .rendered, "Solid stroke paint renders.") {
		##"<path d="M18 52 C42 18 78 18 102 52" fill="none" stroke="#2563eb" stroke-width="8" stroke-linecap="round"/>"##
	},
	example("paint-stroke-width", "stroke-width", "Painting", .rendered, "Stroke width affects painted outlines.") {
		##"<path d="M18 28 H102" stroke="#94a3b8" stroke-width="3" stroke-linecap="round"/><path d="M18 52 H102" stroke="#0f172a" stroke-width="10" stroke-linecap="round"/>"##
	},
	example("paint-stroke-opacity", "stroke-opacity", "Painting", .rendered, "Stroke opacity multiplies stroke paint.") {
		##"<path d="M18 40 H102" stroke="#ef4444" stroke-width="16" stroke-opacity="0.45" stroke-linecap="round"/>"##
	},
	example("paint-linecap-butt", "stroke-linecap butt", "Painting", .rendered, "Butt caps end exactly on the path endpoints.") {
		##"<path d="M24 40 H96" stroke="#ef4444" stroke-width="14" stroke-linecap="butt"/>"##
	},
	example("paint-linecap-round", "stroke-linecap round", "Painting", .rendered, "Round caps extend the path with semicircles.") {
		##"<path d="M24 40 H96" stroke="#22c55e" stroke-width="14" stroke-linecap="round"/>"##
	},
	example("paint-linecap-square", "stroke-linecap square", "Painting", .rendered, "Square caps extend the path with square ends.") {
		##"<path d="M24 40 H96" stroke="#3b82f6" stroke-width="14" stroke-linecap="square"/>"##
	},
	example("paint-linejoin-miter", "stroke-linejoin miter", "Painting", .rendered, "Miter joins create pointed corners.") {
		##"<polyline points="26,60 60,18 94,60" fill="none" stroke="#0f172a" stroke-width="12" stroke-linejoin="miter"/>"##
	},
	example("paint-linejoin-round", "stroke-linejoin round", "Painting", .rendered, "Round joins create curved corners.") {
		##"<polyline points="26,60 60,18 94,60" fill="none" stroke="#a855f7" stroke-width="12" stroke-linejoin="round"/>"##
	},
	example("paint-linejoin-bevel", "stroke-linejoin bevel", "Painting", .rendered, "Bevel joins flatten corners.") {
		##"<polyline points="26,60 60,18 94,60" fill="none" stroke="#f97316" stroke-width="12" stroke-linejoin="bevel"/>"##
	},
	example("paint-miterlimit", "stroke-miterlimit", "Painting", .rendered, "Miter limit affects sharp stroked corners.") {
		##"<polyline points="30,62 60,18 90,62" fill="none" stroke="#475569" stroke-width="10" stroke-linejoin="miter" stroke-miterlimit="1"/>"##
	},
	example("paint-dasharray", "stroke-dasharray", "Painting", .rendered, "Dash arrays are passed to SwiftUI stroke style.") {
		##"<path d="M18 40 H102" stroke="#0f172a" stroke-width="8" stroke-linecap="round" stroke-dasharray="10 8"/>"##
	},
	example("paint-dashoffset", "stroke-dashoffset", "Painting", .rendered, "Dash offsets shift the dash phase.") {
		##"<path d="M18 30 H102" stroke="#cbd5e1" stroke-width="7" stroke-dasharray="10 7"/><path d="M18 52 H102" stroke="#2563eb" stroke-width="7" stroke-dasharray="10 7" stroke-dashoffset="9"/>"##
	},
	example("paint-order", "paint-order", "Painting", .rendered, "Paint order is honored for fill and stroke; marker painting is skipped.") {
		##"<path d="M26 60 L60 16 L94 60 Z" fill="#facc15" stroke="#713f12" stroke-width="12" paint-order="stroke fill markers" stroke-linejoin="round"/>"##
	},
	example("paint-current-color", "currentColor", "Painting", .rendered, "currentColor resolves into fill or stroke paint.") {
		##"<g color="#2563eb"><circle cx="46" cy="40" r="22" fill="currentColor"/><path d="M74 24 L96 56" stroke="currentColor" stroke-width="8" stroke-linecap="round"/></g>"##
	},
	example("paint-rendering-hints", "rendering hints", "Painting", .modelOnly, "Color, shape, text, and image rendering hints are parsed but do not change native output.") {
		##"<rect x="24" y="18" width="72" height="44" rx="10" fill="#e2e8f0" stroke="#64748b" stroke-width="4" color-rendering="optimizeQuality" shape-rendering="crispEdges" text-rendering="geometricPrecision" image-rendering="pixelated"/>"##
	},
]

let gradientAndPatternExamples = [
	example("gradient-linear", "<linearGradient>", "Gradients and Patterns", .modelOnly, "URL paint servers are parsed but skipped by the renderer.") {
		##"<defs><linearGradient id="g"><stop offset="0" stop-color="#38bdf8"/><stop offset="1" stop-color="#ec4899"/></linearGradient></defs><rect x="22" y="16" width="76" height="48" rx="12" fill="url(#g)" stroke="#94a3b8" stroke-width="3"/>"##
	},
	example("gradient-radial", "<radialGradient>", "Gradients and Patterns", .modelOnly, "Radial gradient paint is parsed but not painted.") {
		##"<defs><radialGradient id="g"><stop offset="0" stop-color="#fef08a"/><stop offset="1" stop-color="#f97316"/></radialGradient></defs><circle cx="60" cy="40" r="26" fill="url(#g)" stroke="#94a3b8" stroke-width="3"/>"##
	},
	example("gradient-stop-offset", "<stop> offset", "Gradients and Patterns", .modelOnly, "Stop offsets are model data until gradient rendering exists.") {
		##"<defs><linearGradient id="g"><stop offset="0.2" stop-color="#22c55e"/><stop offset="0.8" stop-color="#2563eb"/></linearGradient></defs><rect x="22" y="18" width="76" height="44" fill="url(#g)" stroke="#94a3b8" stroke-width="3"/>"##
	},
	example("gradient-stop-opacity", "stop-opacity", "Gradients and Patterns", .modelOnly, "Stop opacity is parsed but has no effect without gradient paint.") {
		##"<defs><linearGradient id="g"><stop offset="0" stop-color="#ef4444" stop-opacity="0.1"/><stop offset="1" stop-color="#ef4444" stop-opacity="1"/></linearGradient></defs><rect x="22" y="18" width="76" height="44" fill="url(#g)" stroke="#94a3b8" stroke-width="3"/>"##
	},
	example("gradient-object-bounding-box", "gradientUnits objectBoundingBox", "Gradients and Patterns", .modelOnly, "Object-bounding-box gradient units are preserved but not rendered.") {
		##"<defs><linearGradient id="g" gradientUnits="objectBoundingBox" x1="0" x2="1"><stop offset="0" stop-color="#38bdf8"/><stop offset="1" stop-color="#0f172a"/></linearGradient></defs><rect x="20" y="18" width="80" height="44" fill="url(#g)" stroke="#94a3b8" stroke-width="3"/>"##
	},
	example("gradient-user-space", "gradientUnits userSpaceOnUse", "Gradients and Patterns", .modelOnly, "User-space gradient units are preserved but not rendered.") {
		##"<defs><linearGradient id="g" gradientUnits="userSpaceOnUse" x1="20" x2="100"><stop offset="0" stop-color="#f97316"/><stop offset="1" stop-color="#7c2d12"/></linearGradient></defs><rect x="20" y="18" width="80" height="44" fill="url(#g)" stroke="#94a3b8" stroke-width="3"/>"##
	},
	example("gradient-transform", "gradientTransform", "Gradients and Patterns", .modelOnly, "Gradient transforms are parsed but skipped by native paint.") {
		##"<defs><linearGradient id="g" gradientTransform="rotate(20)"><stop offset="0" stop-color="#22c55e"/><stop offset="1" stop-color="#a855f7"/></linearGradient></defs><rect x="22" y="18" width="76" height="44" fill="url(#g)" stroke="#94a3b8" stroke-width="3"/>"##
	},
	example("gradient-spread-pad", "spreadMethod pad", "Gradients and Patterns", .modelOnly, "Spread methods are parsed but not rendered.") {
		##"<defs><linearGradient id="g" x2=".35" spreadMethod="pad"><stop offset="0" stop-color="#38bdf8"/><stop offset="1" stop-color="#2563eb"/></linearGradient></defs><rect x="22" y="18" width="76" height="44" fill="url(#g)" stroke="#94a3b8" stroke-width="3"/>"##
	},
	example("gradient-spread-reflect", "spreadMethod reflect", "Gradients and Patterns", .modelOnly, "Reflect spread is model-only today.") {
		##"<defs><linearGradient id="g" x2=".35" spreadMethod="reflect"><stop offset="0" stop-color="#38bdf8"/><stop offset="1" stop-color="#2563eb"/></linearGradient></defs><rect x="22" y="18" width="76" height="44" fill="url(#g)" stroke="#94a3b8" stroke-width="3"/>"##
	},
	example("gradient-spread-repeat", "spreadMethod repeat", "Gradients and Patterns", .modelOnly, "Repeat spread is model-only today.") {
		##"<defs><linearGradient id="g" x2=".35" spreadMethod="repeat"><stop offset="0" stop-color="#38bdf8"/><stop offset="1" stop-color="#2563eb"/></linearGradient></defs><rect x="22" y="18" width="76" height="44" fill="url(#g)" stroke="#94a3b8" stroke-width="3"/>"##
	},
	example("pattern", "<pattern>", "Gradients and Patterns", .modelOnly, "Pattern paint servers are parsed but skipped.") {
		##"<defs><pattern id="p" width="12" height="12" patternUnits="userSpaceOnUse"><rect width="12" height="12" fill="#fef3c7"/><circle cx="6" cy="6" r="3" fill="#f97316"/></pattern></defs><rect x="22" y="16" width="76" height="48" fill="url(#p)" stroke="#94a3b8" stroke-width="3"/>"##
	},
	example("pattern-content-units", "patternContentUnits", "Gradients and Patterns", .modelOnly, "Pattern content unit mapping is preserved but not painted.") {
		##"<defs><pattern id="p" width=".25" height=".25" patternContentUnits="objectBoundingBox"><circle cx=".12" cy=".12" r=".05" fill="#2563eb"/></pattern></defs><rect x="22" y="16" width="76" height="48" fill="url(#p)" stroke="#94a3b8" stroke-width="3"/>"##
	},
]

let clipMaskExamples = [
	example("clip-path-element", "<clipPath>", "Clipping, Masking, and Compositing", .modelOnly, "Clip path definitions are parsed but not applied.") {
		##"<defs><clipPath id="clip"><circle cx="60" cy="40" r="24"/></clipPath></defs><rect x="28" y="12" width="64" height="56" fill="#38bdf8" clip-path="url(#clip)"/>"##
	},
	example("clip-path-property", "clip-path", "Clipping, Masking, and Compositing", .modelOnly, "The clip-path property is parsed but ignored by the renderer.") {
		##"<defs><clipPath id="clip"><path d="M20 40 L60 14 L100 40 L60 66 Z"/></clipPath></defs><rect x="20" y="14" width="80" height="52" fill="#22c55e" clip-path="url(#clip)"/>"##
	},
	example("clip-rule", "clip-rule", "Clipping, Masking, and Compositing", .modelOnly, "Clip-rule is preserved, but clipping itself is not applied.") {
		##"<defs><clipPath id="clip"><path d="M18 12 H102 V68 H18 Z M40 30 H80 V50 H40 Z" clip-rule="evenodd"/></clipPath></defs><rect x="18" y="12" width="84" height="56" fill="#a855f7" clip-path="url(#clip)"/>"##
	},
	example("clip-path-units", "clipPathUnits", "Clipping, Masking, and Compositing", .modelOnly, "Clip path units are model-only today.") {
		##"<defs><clipPath id="clip" clipPathUnits="objectBoundingBox"><circle cx=".5" cy=".5" r=".35"/></clipPath></defs><rect x="20" y="14" width="80" height="52" fill="#f97316" clip-path="url(#clip)"/>"##
	},
	example("mask-element", "<mask>", "Clipping, Masking, and Compositing", .modelOnly, "Mask definitions are parsed but not applied.") {
		##"<defs><mask id="mask"><rect width="120" height="80" fill="white"/><circle cx="60" cy="40" r="20" fill="black"/></mask></defs><rect x="22" y="14" width="76" height="52" fill="#2563eb" mask="url(#mask)"/>"##
	},
	example("mask-property", "mask", "Clipping, Masking, and Compositing", .modelOnly, "The mask property is parsed but ignored by native drawing.") {
		##"<defs><mask id="mask"><circle cx="60" cy="40" r="28" fill="white"/></mask></defs><rect x="20" y="12" width="80" height="56" fill="#ec4899" mask="url(#mask)"/>"##
	},
	example("mask-units", "maskUnits", "Clipping, Masking, and Compositing", .modelOnly, "Mask units are preserved but not rendered.") {
		##"<defs><mask id="mask" maskUnits="userSpaceOnUse" x="20" y="12" width="80" height="56"><rect x="20" y="12" width="80" height="56" fill="white"/></mask></defs><rect x="20" y="12" width="80" height="56" fill="#14b8a6" mask="url(#mask)"/>"##
	},
	example("mask-content-units", "maskContentUnits", "Clipping, Masking, and Compositing", .modelOnly, "Mask content units are model-only today.") {
		##"<defs><mask id="mask" maskContentUnits="objectBoundingBox"><circle cx=".5" cy=".5" r=".35" fill="white"/></mask></defs><rect x="20" y="12" width="80" height="56" fill="#facc15" mask="url(#mask)"/>"##
	},
	example("opacity", "opacity", "Clipping, Masking, and Compositing", .rendered, "Element and group opacity are applied while rendering.") {
		##"<circle cx="48" cy="40" r="26" fill="#ef4444" opacity="0.68"/><circle cx="72" cy="40" r="26" fill="#2563eb" opacity="0.68"/>"##
	},
]

let filterExamples = [
	filterExample("filter-element", "<filter>", "filter=\"url(...)\" is parsed but no filter graph is applied.", ##"<feGaussianBlur stdDeviation="4"/>"##),
	filterExample("filter-units", "filterUnits", "Filter coordinate units are parsed but not applied.", ##"<feOffset dx="8" dy="8"/>"##),
	filterExample("primitive-units", "primitiveUnits", "Primitive coordinate units are parsed but not applied.", ##"<feOffset dx="8" dy="8"/>"##),
	filterExample("fe-gaussian-blur", "<feGaussianBlur>", "Blur primitives are model-only today.", ##"<feGaussianBlur stdDeviation="5"/>"##),
	filterExample("fe-drop-shadow", "<feDropShadow>", "Drop shadows are parsed but not rendered.", ##"<feDropShadow dx="0" dy="8" stdDeviation="4" flood-color="#0f172a" flood-opacity="0.35"/>"##),
	filterExample("fe-blend", "<feBlend>", "Blend primitives are preserved but skipped.", ##"<feBlend mode="multiply"/>"##),
	filterExample("fe-color-matrix", "<feColorMatrix>", "Color matrix primitives are preserved but skipped.", ##"<feColorMatrix type="saturate" values="0"/>"##),
	filterExample("fe-component-transfer", "<feComponentTransfer>", "Component transfer primitives are preserved but skipped.", ##"<feComponentTransfer><feFuncA type="table" tableValues="0 1"/></feComponentTransfer>"##),
	filterExample("fe-func-r", "<feFuncR>", "Red channel transfer functions are model-only.", ##"<feComponentTransfer><feFuncR type="linear" slope="0.2"/></feComponentTransfer>"##),
	filterExample("fe-func-g", "<feFuncG>", "Green channel transfer functions are model-only.", ##"<feComponentTransfer><feFuncG type="linear" slope="0.2"/></feComponentTransfer>"##),
	filterExample("fe-func-b", "<feFuncB>", "Blue channel transfer functions are model-only.", ##"<feComponentTransfer><feFuncB type="linear" slope="0.2"/></feComponentTransfer>"##),
	filterExample("fe-func-a", "<feFuncA>", "Alpha channel transfer functions are model-only.", ##"<feComponentTransfer><feFuncA type="table" tableValues="0.2 1"/></feComponentTransfer>"##),
	filterExample("fe-composite", "<feComposite>", "Composite primitives are preserved but skipped.", ##"<feComposite operator="xor"/>"##),
	filterExample("fe-convolve-matrix", "<feConvolveMatrix>", "Convolution primitives are model-only.", ##"<feConvolveMatrix order="3" kernelMatrix="0 -1 0 -1 5 -1 0 -1 0"/>"##),
	filterExample("fe-diffuse-lighting", "<feDiffuseLighting>", "Diffuse lighting primitives are model-only.", ##"<feDiffuseLighting surfaceScale="2"><feDistantLight azimuth="45" elevation="60"/></feDiffuseLighting>"##),
	filterExample("fe-displacement-map", "<feDisplacementMap>", "Displacement map primitives are model-only.", ##"<feDisplacementMap scale="12" xChannelSelector="R" yChannelSelector="G"/>"##),
	filterExample("fe-distant-light", "<feDistantLight>", "Distant light data is parsed inside lighting filters only.", ##"<feDiffuseLighting><feDistantLight azimuth="45" elevation="60"/></feDiffuseLighting>"##),
	filterExample("fe-flood", "<feFlood>", "Flood primitives are preserved but not rendered.", ##"<feFlood flood-color="#f97316" flood-opacity="0.5"/>"##),
	filterExample("fe-image", "<feImage>", "Filter image primitives are model-only.", ##"<feImage href="#source"/>"##),
	filterExample("fe-merge", "<feMerge>", "Merge primitives are preserved but skipped.", ##"<feMerge><feMergeNode in="SourceGraphic"/></feMerge>"##),
	filterExample("fe-merge-node", "<feMergeNode>", "Merge node ordering is model-only.", ##"<feMerge><feMergeNode in="SourceGraphic"/></feMerge>"##),
	filterExample("fe-morphology", "<feMorphology>", "Morphology primitives are preserved but skipped.", ##"<feMorphology operator="dilate" radius="3"/>"##),
	filterExample("fe-offset", "<feOffset>", "Offset primitives are preserved but skipped.", ##"<feOffset dx="8" dy="8"/>"##),
	filterExample("fe-point-light", "<fePointLight>", "Point light data is parsed inside lighting filters only.", ##"<feDiffuseLighting><fePointLight x="40" y="20" z="80"/></feDiffuseLighting>"##),
	filterExample("fe-specular-lighting", "<feSpecularLighting>", "Specular lighting primitives are model-only.", ##"<feSpecularLighting surfaceScale="2"><fePointLight x="40" y="20" z="80"/></feSpecularLighting>"##),
	filterExample("fe-spot-light", "<feSpotLight>", "Spot light data is parsed inside lighting filters only.", ##"<feSpecularLighting><feSpotLight x="40" y="20" z="80" pointsAtX="60" pointsAtY="40"/></feSpecularLighting>"##),
	filterExample("fe-tile", "<feTile>", "Tile primitives are model-only.", ##"<feTile/>"##),
	filterExample("fe-turbulence", "<feTurbulence>", "Turbulence primitives are model-only.", ##"<feTurbulence baseFrequency="0.05" numOctaves="2"/>"##),
]

let textExamples = [
	textExample("text-element", "<text>", "Text elements are parsed but native text painting is not implemented.", ##"<text x="60" y="42" text-anchor="middle" font-size="24" fill="#0f172a">SVG</text>"##),
	textExample("text-tspan", "<tspan>", "Text spans are parsed but not painted.", ##"<text x="28" y="42" font-size="20" fill="#0f172a">A<tspan fill="#f97316">B</tspan></text>"##),
	textExample("text-path", "<textPath>", "TextPath references are parsed but text layout along paths is not painted.", ##"<defs><path id="wave" d="M16 50 C40 18 80 62 104 30"/></defs><path d="M16 50 C40 18 80 62 104 30" fill="none" stroke="#cbd5e1" stroke-width="4"/><text font-size="15"><textPath href="#wave">textPath</textPath></text>"##),
	textExample("text-positioning", "text x/y/dx/dy", "Text positioning lists are model-only until text rendering exists.", ##"<text x="20 48" y="36" dx="0 8" dy="0 10" font-size="20">AB</text>"##),
	textExample("text-rotate", "text rotate", "Per-glyph text rotation is parsed but not painted.", ##"<text x="32" y="44" rotate="-12 12" font-size="20">rot</text>"##),
	textExample("text-anchor", "text-anchor", "Text anchoring is parsed but not painted.", ##"<text x="60" y="42" text-anchor="middle" font-size="20">anchor</text>"##),
	textExample("dominant-baseline", "dominant-baseline", "Dominant baseline is parsed but not painted.", ##"<text x="60" y="40" dominant-baseline="middle" text-anchor="middle" font-size="20">base</text>"##),
	textExample("alignment-baseline", "alignment-baseline", "Alignment baseline is parsed but not painted.", ##"<text x="60" y="40" alignment-baseline="middle" text-anchor="middle" font-size="20">base</text>"##),
	textExample("white-space", "white-space", "Text whitespace handling is parsed but not painted.", ##"<text x="24" y="42" white-space="pre" font-size="20">A  B</text>"##),
]

let reuseAndMarkerExamples = [
	example("href-use", "href", "Reuse, Linking, and Markers", .rendered, "Unprefixed href works for simple <use> references.") {
		##"<defs><g id="badge"><circle cx="0" cy="0" r="16" fill="#38bdf8" stroke="#075985" stroke-width="4"/></g></defs><use href="#badge" x="42" y="40"/><use href="#badge" x="78" y="40"/>"##
	},
	example("xlink-href-use", "xlink:href", "Reuse, Linking, and Markers", .rendered, "Deprecated xlink:href is preserved and works for simple <use> references.") {
		##"<defs><g id="badge"><rect x="-14" y="-14" width="28" height="28" rx="7" fill="#f97316" stroke="#7c2d12" stroke-width="4"/></g></defs><use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="#badge" x="42" y="40"/><use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="#badge" x="78" y="40"/>"##
	},
	example("marker-element", "<marker>", "Reuse, Linking, and Markers", .modelOnly, "Marker definitions are parsed but marker painting is skipped.") {
		##"<defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8"><path d="M1 1 L9 5 L1 9 Z" fill="#2563eb"/></marker></defs><path d="M22 40 H98" stroke="#2563eb" stroke-width="8" marker-end="url(#arrow)"/>"##
	},
	example("marker-start", "marker-start", "Reuse, Linking, and Markers", .modelOnly, "Start markers are parsed but not painted.") {
		##"<defs><marker id="dot" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="8" markerHeight="8"><circle cx="5" cy="5" r="4" fill="#ef4444"/></marker></defs><path d="M22 40 H98" stroke="#2563eb" stroke-width="8" marker-start="url(#dot)"/>"##
	},
	example("marker-mid", "marker-mid", "Reuse, Linking, and Markers", .modelOnly, "Mid markers are parsed but not painted.") {
		##"<defs><marker id="dot" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="8" markerHeight="8"><circle cx="5" cy="5" r="4" fill="#ef4444"/></marker></defs><polyline points="20,58 60,22 100,58" fill="none" stroke="#2563eb" stroke-width="8" marker-mid="url(#dot)"/>"##
	},
	example("marker-end", "marker-end", "Reuse, Linking, and Markers", .modelOnly, "End markers are parsed but not painted.") {
		##"<defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8"><path d="M1 1 L9 5 L1 9 Z" fill="#2563eb"/></marker></defs><path d="M22 40 H98" stroke="#2563eb" stroke-width="8" marker-end="url(#arrow)"/>"##
	},
	example("marker-orient", "marker orient", "Reuse, Linking, and Markers", .modelOnly, "Marker orientation is parsed but has no renderer effect.") {
		##"<defs><marker id="arrow" orient="auto" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8"><path d="M1 1 L9 5 L1 9 Z" fill="#2563eb"/></marker></defs><path d="M22 58 C46 20 74 20 98 58" fill="none" stroke="#2563eb" stroke-width="8" marker-end="url(#arrow)"/>"##
	},
	example("marker-units", "markerUnits", "Reuse, Linking, and Markers", .modelOnly, "Marker unit scaling is parsed but not painted.") {
		##"<defs><marker id="arrow" markerUnits="strokeWidth" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8"><path d="M1 1 L9 5 L1 9 Z" fill="#2563eb"/></marker></defs><path d="M22 40 H98" stroke="#2563eb" stroke-width="8" marker-end="url(#arrow)"/>"##
	},
	example("marker-viewbox", "marker viewBox", "Reuse, Linking, and Markers", .modelOnly, "Marker viewBox data is parsed but not rendered.") {
		##"<defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8"><path d="M1 1 L9 5 L1 9 Z" fill="#2563eb"/></marker></defs><path d="M22 40 H98" stroke="#2563eb" stroke-width="8" marker-end="url(#arrow)"/>"##
	},
]

let embeddedAndDynamicExamples = [
	example("foreign-object", "<foreignObject>", "Embedded and Dynamic SVG", .partial, "The container's SVG children can render; embedded HTML is not painted.") {
		"""
		<foreignObject x="18" y="12" width="84" height="56">
			<body xmlns="http://www.w3.org/1999/xhtml">
				<div style="background:#fff;color:#000">HTML</div>
			</body>
			<svg x="24" y="18" width="48" height="30" viewBox="0 0 48 30">
				<rect width="48" height="30" rx="8" fill="#0f172a"/>
				<circle cx="18" cy="15" r="8" fill="#22c55e"/>
			</svg>
		</foreignObject>
		"""
	},
	example("animate", "<animate>", "Embedded and Dynamic SVG", .staticOnly, "Animation records are parsed; the native view paints the initial static geometry only.") {
		##"<circle cx="60" cy="40" r="20" fill="#22c55e"><animate attributeName="r" values="12;28;12" dur="2s" repeatCount="indefinite"/></circle>"##
	},
	example("animate-motion", "<animateMotion>", "Embedded and Dynamic SVG", .staticOnly, "Motion animation is parsed but not executed.") {
		##"<path id="motion" d="M20 56 C42 18 78 62 100 24" fill="none" stroke="#cbd5e1" stroke-width="4"/><circle cx="20" cy="56" r="9" fill="#f97316"><animateMotion dur="2s"><mpath href="#motion"/></animateMotion></circle>"##
	},
	example("animate-transform", "<animateTransform>", "Embedded and Dynamic SVG", .staticOnly, "Transform animation is parsed but not executed.") {
		##"<rect x="42" y="24" width="36" height="32" rx="8" fill="#38bdf8"><animateTransform attributeName="transform" type="rotate" from="-18 60 40" to="18 60 40" dur="2s"/></rect>"##
	},
	example("set-animation", "<set>", "Embedded and Dynamic SVG", .staticOnly, "Set animation elements are parsed but do not mutate rendered output.") {
		##"<rect x="28" y="20" width="64" height="40" rx="12" fill="#a855f7"><set attributeName="fill" to="#22c55e" begin="1s"/></rect>"##
	},
	example("discard-animation", "<discard>", "Embedded and Dynamic SVG", .staticOnly, "Discard elements are parsed but do not remove rendered content.") {
		##"<circle cx="60" cy="40" r="24" fill="#ef4444"><discard begin="1s"/></circle>"##
	},
	example("mpath", "<mpath>", "Embedded and Dynamic SVG", .staticOnly, "Motion path references are parsed but not animated.") {
		##"<path id="motion" d="M20 56 C42 18 78 62 100 24" fill="none" stroke="#cbd5e1" stroke-width="4"/><circle cx="20" cy="56" r="9" fill="#f97316"><animateMotion dur="2s"><mpath href="#motion"/></animateMotion></circle>"##
	},
]

func filterExample(_ slug: String, _ title: String, _ note: String, _ primitive: String) -> FeatureExample {
	example(slug, title, "Filters", .modelOnly, note) {
		"""
		<defs>
			<filter id="f" x="-40%" y="-40%" width="180%" height="180%" filterUnits="objectBoundingBox" primitiveUnits="userSpaceOnUse">
				\(primitive)
			</filter>
		</defs>
		<rect id="source" x="32" y="20" width="56" height="40" rx="12" fill="#2563eb" filter="url(#f)"/>
		"""
	}
}

func textExample(_ slug: String, _ title: String, _ note: String, _ textBody: String) -> FeatureExample {
	example(slug, title, "Text", .modelOnly, note) {
		"""
		<path d="M18 54 H102" stroke="#cbd5e1" stroke-width="3" stroke-linecap="round"/>
		\(textBody)
		"""
	}
}

func example(
	_ slug: String,
	_ title: String,
	_ category: String,
	_ rendererStatus: RendererStatus,
	_ note: String,
	width: Int = 240,
	height: Int = 160,
	body: () -> String
) -> FeatureExample {
	FeatureExample(
		slug: slug,
		title: title,
		category: category,
		rendererStatus: rendererStatus,
		note: note,
		width: width,
		height: height,
		svg: svg(body())
	)
}

func svg(_ body: String) -> String {
	"""
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 80">
		<rect width="120" height="80" fill="#f8fafc"/>
	\(body)
	</svg>
	"""
}

enum FeatureGalleryRenderer {
	@MainActor
	static func renderAll(examples: [FeatureExample], packageRoot: URL, pngDirectory explicitPNGDirectory: URL? = nil) throws {
		let svgDirectory = packageRoot.appendingPathComponent("docs/feature-gallery/svg", isDirectory: true)
		let pngDirectory = explicitPNGDirectory ?? packageRoot.appendingPathComponent("docs/feature-gallery/png", isDirectory: true)
		try FileManager.default.createDirectory(at: svgDirectory, withIntermediateDirectories: true)
		try FileManager.default.createDirectory(at: pngDirectory, withIntermediateDirectories: true)
		try writeIndex(examples: examples, packageRoot: packageRoot)

		for example in examples {
			let svgURL = svgDirectory.appendingPathComponent("\(example.slug).svg")
			let pngURL = pngDirectory.appendingPathComponent("\(example.slug).png")
			try example.svg.write(to: svgURL, atomically: true, encoding: .utf8)
			let document = try parseDocument(svgURL)
			try render(document, pngURL: pngURL, width: example.width, height: example.height)
			print("Rendered \(pngURL.path)")
		}
	}

	private static func writeIndex(examples: [FeatureExample], packageRoot: URL) throws {
		let indexURL = packageRoot.appendingPathComponent("docs/feature-gallery/features.md")
		var markdown = """
		# SVG View Visual Feature Matrix

		Generated by `docs/FeatureGallery.playground/Contents.swift`. Each SVG is parsed by `swg` and rendered through the public `SVG` SwiftUI view.

		| Category | Feature | Renderer | Preview | Notes |
		| --- | --- | --- | --- | --- |

		"""
		for example in examples {
			let title = markdownEscaped(example.title)
			let note = markdownEscaped(example.note)
			let alt = htmlEscaped(example.title)
			markdown += "| \(markdownEscaped(example.category)) | \(title) | \(example.rendererStatus.rawValue) | <img src=\"png/\(example.slug).png\" alt=\"\(alt)\" width=\"96\"> | \(note) |\n"
		}
		try markdown.write(to: indexURL, atomically: true, encoding: .utf8)
	}

	private static func markdownEscaped(_ text: String) -> String {
		text
			.replacingOccurrences(of: "|", with: "\\|")
			.replacingOccurrences(of: "<", with: "&lt;")
			.replacingOccurrences(of: ">", with: "&gt;")
	}

	private static func htmlEscaped(_ text: String) -> String {
		text
			.replacingOccurrences(of: "&", with: "&amp;")
			.replacingOccurrences(of: "\"", with: "&quot;")
			.replacingOccurrences(of: "<", with: "&lt;")
			.replacingOccurrences(of: ">", with: "&gt;")
	}

	private static func parseDocument(_ svgURL: URL) throws -> SVGDocument {
		let svg = try String(contentsOf: svgURL, encoding: .utf8)
		guard let document = SVGParser().parse(svg) else {
			throw FeatureGalleryError.invalidSVG(svgURL.lastPathComponent)
		}
		return document
	}

	@MainActor
	private static func render(_ document: SVGDocument, pngURL: URL, width: Int, height: Int) throws {
		let renderer = ImageRenderer(content: SVG(document).frame(width: CGFloat(width), height: CGFloat(height)))
		renderer.scale = 1
		guard let image = renderer.cgImage else {
			throw FeatureGalleryError.renderingFailed(pngURL.lastPathComponent)
		}
		if FileManager.default.fileExists(atPath: pngURL.path) {
			try FileManager.default.removeItem(at: pngURL)
		}
		guard let destination = CGImageDestinationCreateWithURL(pngURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
			throw FeatureGalleryError.invalidRenderedPNG(pngURL)
		}
		CGImageDestinationAddImage(destination, image, nil)
		guard CGImageDestinationFinalize(destination) else {
			throw FeatureGalleryError.invalidRenderedPNG(pngURL)
		}
	}
}

enum FeatureGalleryError: Error {
	case invalidSVG(String)
	case renderingFailed(String)
	case invalidRenderedPNG(URL)
}

let featureExamples: [FeatureExample] =
	containerExamples +
	shapeExamples +
	pathExamples +
	transformExamples +
	styleExamples +
	paintExamples +
	gradientAndPatternExamples +
	clipMaskExamples +
	filterExamples +
	textExamples +
	reuseAndMarkerExamples +
	embeddedAndDynamicExamples

let arguments = CommandLine.arguments.dropFirst()
let explicitPackageRoot = arguments.first.map { URL(fileURLWithPath: $0) }
let explicitPNGDirectory = arguments.dropFirst().first.map { URL(fileURLWithPath: $0, isDirectory: true) }
let inferredPackageRoot = URL(fileURLWithPath: #filePath)
	.deletingLastPathComponent()
	.deletingLastPathComponent()
	.deletingLastPathComponent()
let packageRoot = explicitPackageRoot ?? inferredPackageRoot

try await FeatureGalleryRenderer.renderAll(examples: featureExamples, packageRoot: packageRoot, pngDirectory: explicitPNGDirectory)
