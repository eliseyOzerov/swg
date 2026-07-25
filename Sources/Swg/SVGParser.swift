import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

/// Parses SVG XML data into an `SVGDocument`.
public final class SVGParser: NSObject, XMLParserDelegate {
	private var viewBox: Rect = .zero
	private var rootWidth: Double?
	private var rootHeight: Double?
	private var rootPaintAttributes: SVGPaintAttributes = .defaults
	private var elementStack: [SVGGroupBuilder] = []
	private var rootElements: [SVGElement] = []
	private var elementCounters: [String: Int] = [:]
	private var defs = SVGDefs()
	private var inDefs = false
	private var defsElementStack: [SVGGroupBuilder] = []
	private var currentLinearGradient: SVGLinearGradientDef?
	private var currentRadialGradient: SVGRadialGradientDef?
	private var currentGradientStops: [SVGGradientStop] = []
	private var currentFilter: SVGFilterDef?
	private var inMask = false
	private var currentMaskID: String?
	private var maskElements: [SVGElement] = []
	private var inClipPath = false
	private var currentClipPathID: String?
	private var clipPathElements: [SVGElement] = []
	private var inText = false
	private var textBuilder: SVGTextBuilder?
	private var currentSpanAttrs: SVGPaintAttributes?
	private var inStyleElement = false
	private var styleText = ""
	private var styleSheet: [String: [String: String]] = [:]
	private var characterBuffer = ""

	public func parse(_ string: String) -> SVGDocument? {
		guard let data = string.data(using: .utf8) else { return nil }
		return parse(data)
	}

	public func parse(_ data: Data) -> SVGDocument? {
		reset()
		let parser = XMLParser(data: data)
		parser.delegate = self
		guard parser.parse() else { return nil }

		let resolvedViewBox: Rect
		if !viewBox.isZero {
			resolvedViewBox = viewBox
		} else if let rootWidth, let rootHeight {
			resolvedViewBox = Rect(x: 0, y: 0, width: rootWidth, height: rootHeight)
		} else {
			resolvedViewBox = Rect(x: 0, y: 0, width: 100, height: 100)
		}
		return SVGDocument(viewBox: resolvedViewBox, elements: rootElements, defs: defs)
	}

	public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String]) {
		characterBuffer = ""

		switch elementName {
		case "svg":
			parseSVGRoot(attributes)
		case "defs":
			inDefs = true
		case "style":
			inStyleElement = true
			styleText = ""
		case "linearGradient":
			parseLinearGradientStart(attributes)
		case "radialGradient":
			parseRadialGradientStart(attributes)
		case "stop":
			parseGradientStop(attributes)
		case "clipPath":
			inClipPath = true
			currentClipPathID = attributes["id"]
			clipPathElements = []
		case "filter":
			currentFilter = SVGFilterDef(id: attributes["id"] ?? "")
		case "feGaussianBlur":
			if let std = attributes["stdDeviation"].flatMap(Double.init) {
				currentFilter?.primitives.append(.gaussianBlur(stdDeviation: std))
			}
		case "feDropShadow":
			let dx = attributes["dx"].flatMap(Double.init) ?? 0
			let dy = attributes["dy"].flatMap(Double.init) ?? 0
			let std = attributes["stdDeviation"].flatMap(Double.init) ?? 0
			let color = attributes["flood-color"].flatMap { parseColor($0) } ?? .black
			let opacity = attributes["flood-opacity"].flatMap(Double.init) ?? 1
			currentFilter?.primitives.append(.dropShadow(dx: dx, dy: dy, stdDeviation: std, color: color.withAlpha(opacity)))
		case "mask":
			inMask = true
			currentMaskID = attributes["id"]
			maskElements = []
		case "use":
			parseUse(attributes)
		case "image":
			parseImage(attributes)
		case "text":
			parseTextStart(attributes)
		case "tspan":
			parseTSpanStart(attributes)
		case "g":
			let attrs = parsePaintAttributes(attributes)
			let id = resolveID(attributes["id"], elementName: "Group")
			let builder = SVGGroupBuilder(id: id, attributes: attrs)
			if inDefs {
				defsElementStack.append(builder)
			} else if !inClipPath && !inMask {
				elementStack.append(builder)
			}
		default:
			parseShapeElement(elementName, attributes: attributes)
		}
	}

	public func parser(_ parser: XMLParser, foundCharacters string: String) {
		characterBuffer += string
	}

	public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
		switch elementName {
		case "defs":
			inDefs = false
		case "style":
			styleText += characterBuffer
			characterBuffer = ""
			parseStyleSheet(styleText)
			inStyleElement = false
		case "linearGradient":
			if var gradient = currentLinearGradient {
				gradient.stops = currentGradientStops
				defs.linearGradients[gradient.id] = gradient
			}
			currentLinearGradient = nil
			currentGradientStops = []
		case "radialGradient":
			if var gradient = currentRadialGradient {
				gradient.stops = currentGradientStops
				defs.radialGradients[gradient.id] = gradient
			}
			currentRadialGradient = nil
			currentGradientStops = []
		case "clipPath":
			if let id = currentClipPathID {
				defs.clipPaths[id] = clipPathElements
			}
			inClipPath = false
			currentClipPathID = nil
		case "filter":
			if let filter = currentFilter {
				defs.filters[filter.id] = filter
			}
			currentFilter = nil
		case "mask":
			if let id = currentMaskID {
				defs.masks[id] = SVGMaskDef(id: id, children: maskElements)
			}
			inMask = false
			currentMaskID = nil
		case "text":
			finalizeText()
		case "tspan":
			finalizeTSpan()
		case "g":
			if inDefs {
				if let builder = defsElementStack.popLast() {
					let group = SVGGroupData(id: builder.id, attributes: builder.attributes, children: builder.children)
					defs.reusableElements[builder.id] = [.group(group)]
				}
			} else if let builder = elementStack.popLast() {
				appendElement(.group(SVGGroupData(id: builder.id, attributes: builder.attributes, children: builder.children)))
			}
		default:
			break
		}

		if inStyleElement {
			styleText += characterBuffer
		}
		characterBuffer = ""
	}

	private func reset() {
		viewBox = .zero
		rootWidth = nil
		rootHeight = nil
		rootPaintAttributes = .defaults
		elementStack = []
		rootElements = []
		elementCounters = [:]
		defs = SVGDefs()
		inDefs = false
		defsElementStack = []
		currentLinearGradient = nil
		currentRadialGradient = nil
		currentGradientStops = []
		currentFilter = nil
		inMask = false
		currentMaskID = nil
		maskElements = []
		inClipPath = false
		currentClipPathID = nil
		clipPathElements = []
		inText = false
		textBuilder = nil
		currentSpanAttrs = nil
		inStyleElement = false
		styleText = ""
		styleSheet = [:]
		characterBuffer = ""
	}

	private func parseShapeElement(_ elementName: String, attributes: [String: String]) {
		switch elementName {
		case "path":
			if let d = attributes["d"] {
				let attrs = parsePaintAttributes(attributes)
				let id = resolveID(attributes["id"], elementName: "Path")
				appendElement(.path(SVGPathData(id: id, d: d, attributes: attrs)))
			}
		case "rect":
			let attrs = parsePaintAttributes(attributes)
			let id = resolveID(attributes["id"], elementName: "Rect")
			appendElement(.rect(SVGRectData(id: id, x: double(attributes["x"]), y: double(attributes["y"]), width: double(attributes["width"]), height: double(attributes["height"]), rx: double(attributes["rx"]), ry: double(attributes["ry"]), attributes: attrs)))
		case "circle":
			let attrs = parsePaintAttributes(attributes)
			let id = resolveID(attributes["id"], elementName: "Circle")
			appendElement(.circle(SVGCircleData(id: id, cx: double(attributes["cx"]), cy: double(attributes["cy"]), r: double(attributes["r"]), attributes: attrs)))
		case "ellipse":
			let attrs = parsePaintAttributes(attributes)
			let id = resolveID(attributes["id"], elementName: "Ellipse")
			appendElement(.ellipse(SVGEllipseData(id: id, cx: double(attributes["cx"]), cy: double(attributes["cy"]), rx: double(attributes["rx"]), ry: double(attributes["ry"]), attributes: attrs)))
		case "line":
			let attrs = parsePaintAttributes(attributes)
			let id = resolveID(attributes["id"], elementName: "Line")
			appendElement(.line(SVGLineData(id: id, x1: double(attributes["x1"]), y1: double(attributes["y1"]), x2: double(attributes["x2"]), y2: double(attributes["y2"]), attributes: attrs)))
		case "polygon":
			let attrs = parsePaintAttributes(attributes)
			let id = resolveID(attributes["id"], elementName: "Polygon")
			appendElement(.polygon(SVGPolygonData(id: id, points: parsePoints(attributes["points"] ?? ""), attributes: attrs)))
		case "polyline":
			let attrs = parsePaintAttributes(attributes)
			let id = resolveID(attributes["id"], elementName: "Polyline")
			appendElement(.polyline(SVGPolygonData(id: id, points: parsePoints(attributes["points"] ?? ""), attributes: attrs)))
		default:
			break
		}
	}

	private func parseLinearGradientStart(_ attributes: [String: String]) {
		var gradient = SVGLinearGradientDef(id: attributes["id"] ?? "")
		if let v = attributes["x1"] { gradient.x1 = parseGradientCoord(v) }
		if let v = attributes["y1"] { gradient.y1 = parseGradientCoord(v) }
		if let v = attributes["x2"] { gradient.x2 = parseGradientCoord(v) }
		if let v = attributes["y2"] { gradient.y2 = parseGradientCoord(v) }
		if attributes["gradientUnits"] == "userSpaceOnUse" { gradient.gradientUnits = .userSpaceOnUse }
		if let transform = attributes["gradientTransform"] { gradient.gradientTransform = parseTransform(transform) }
		gradient.href = parseHref(attributes)
		currentLinearGradient = gradient
		currentGradientStops = []
	}

	private func parseRadialGradientStart(_ attributes: [String: String]) {
		var gradient = SVGRadialGradientDef(id: attributes["id"] ?? "")
		if let v = attributes["cx"] { gradient.cx = parseGradientCoord(v) }
		if let v = attributes["cy"] { gradient.cy = parseGradientCoord(v) }
		if let v = attributes["r"] { gradient.r = parseGradientCoord(v) }
		if let v = attributes["fx"] { gradient.fx = parseGradientCoord(v) }
		if let v = attributes["fy"] { gradient.fy = parseGradientCoord(v) }
		if attributes["gradientUnits"] == "userSpaceOnUse" { gradient.gradientUnits = .userSpaceOnUse }
		if let transform = attributes["gradientTransform"] { gradient.gradientTransform = parseTransform(transform) }
		gradient.href = parseHref(attributes)
		currentRadialGradient = gradient
		currentGradientStops = []
	}

	private func parseGradientStop(_ attributes: [String: String]) {
		var offset: Double = 0
		if let value = attributes["offset"] {
			if value.hasSuffix("%") {
				offset = (Double(value.dropLast()) ?? 0) / 100
			} else {
				offset = Double(value) ?? 0
			}
		}
		let color = attributes["stop-color"].flatMap { parseColor($0) } ?? .black
		let opacity = attributes["stop-opacity"].flatMap(Double.init) ?? 1
		currentGradientStops.append(SVGGradientStop(offset: offset, color: color, opacity: opacity))
	}

	private func parseGradientCoord(_ value: String) -> Double {
		if value.hasSuffix("%") {
			return (Double(value.dropLast()) ?? 0) / 100
		}
		return Double(value) ?? 0
	}

	private func parseHref(_ attributes: [String: String]) -> String? {
		let raw = attributes["href"] ?? attributes["xlink:href"]
		return raw?.hasPrefix("#") == true ? String(raw!.dropFirst()) : raw
	}

	private func parseUse(_ attributes: [String: String]) {
		let id = resolveID(attributes["id"], elementName: "Use")
		let href = parseHref(attributes) ?? ""
		appendElement(.use(SVGUseData(id: id, href: href, x: double(attributes["x"]), y: double(attributes["y"]), attributes: parsePaintAttributes(attributes))))
	}

	private func parseImage(_ attributes: [String: String]) {
		let id = resolveID(attributes["id"], elementName: "Image")
		let href = attributes["href"] ?? attributes["xlink:href"] ?? ""
		appendElement(.image(SVGImageData(id: id, x: double(attributes["x"]), y: double(attributes["y"]), width: double(attributes["width"]), height: double(attributes["height"]), href: href, attributes: parsePaintAttributes(attributes))))
	}

	private func parseTextStart(_ attributes: [String: String]) {
		inText = true
		let attrs = parsePaintAttributes(attributes)
		textBuilder = SVGTextBuilder(
			id: resolveID(attributes["id"], elementName: "Text"),
			x: double(attributes["x"]),
			y: double(attributes["y"]),
			fontSize: double(attributes["font-size"]),
			fontFamily: attributes["font-family"] ?? "",
			fontWeight: attributes["font-weight"] ?? "normal",
			textAnchor: parseTextAnchor(attributes["text-anchor"]),
			attributes: attrs
		)
	}

	private func parseTSpanStart(_ attributes: [String: String]) {
		let buffered = characterBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
		if !buffered.isEmpty, let textBuilder {
			textBuilder.spans.append(SVGTextSpan(text: buffered, x: nil, y: nil, dx: 0, dy: 0, fontSize: nil, fontWeight: nil, attributes: nil))
		}
		characterBuffer = ""
		currentSpanAttrs = parsePaintAttributes(attributes)
	}

	private func finalizeTSpan() {
		let text = characterBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
		characterBuffer = ""
		guard !text.isEmpty, let textBuilder else { return }
		textBuilder.spans.append(SVGTextSpan(text: text, x: nil, y: nil, dx: 0, dy: 0, fontSize: nil, fontWeight: nil, attributes: currentSpanAttrs))
		currentSpanAttrs = nil
	}

	private func finalizeText() {
		let text = characterBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
		if !text.isEmpty, let textBuilder {
			textBuilder.spans.append(SVGTextSpan(text: text, x: nil, y: nil, dx: 0, dy: 0, fontSize: nil, fontWeight: nil, attributes: nil))
		}
		characterBuffer = ""

		if let textBuilder {
			let fontSize = textBuilder.fontSize > 0 ? textBuilder.fontSize : 16
			appendElement(.text(SVGTextData(
				id: textBuilder.id,
				x: textBuilder.x,
				y: textBuilder.y,
				fontSize: fontSize,
				fontFamily: textBuilder.fontFamily,
				fontWeight: textBuilder.fontWeight,
				textAnchor: textBuilder.textAnchor,
				attributes: textBuilder.attributes,
				spans: textBuilder.spans
			)))
		}
		textBuilder = nil
		inText = false
	}

	private func parseTextAnchor(_ value: String?) -> SVGTextAnchor {
		switch value {
		case "middle": .middle
		case "end": .end
		default: .start
		}
	}

	private func parseStyleSheet(_ css: String) {
		let cleaned = css.replacingOccurrences(of: "\n", with: " ")
		guard let regex = try? NSRegularExpression(pattern: #"\.([a-zA-Z0-9_-]+)\s*\{([^}]+)\}"#) else { return }
		let nsCSS = cleaned as NSString
		for match in regex.matches(in: cleaned, range: NSRange(location: 0, length: nsCSS.length)) {
			let className = nsCSS.substring(with: match.range(at: 1))
			let body = nsCSS.substring(with: match.range(at: 2))
			styleSheet[className] = parseInlineCSS(body)
		}
	}

	private func parseInlineCSS(_ style: String) -> [String: String] {
		var result: [String: String] = [:]
		for pair in style.split(separator: ";") {
			let kv = pair.split(separator: ":", maxSplits: 1)
			guard kv.count == 2 else { continue }
			result[kv[0].trimmingCharacters(in: .whitespaces)] = kv[1].trimmingCharacters(in: .whitespaces)
		}
		return result
	}

	private func appendElement(_ element: SVGElement) {
		if inClipPath {
			clipPathElements.append(element)
			return
		}
		if inMask {
			maskElements.append(element)
			return
		}
		if inDefs {
			if let last = defsElementStack.last {
				last.children.append(element)
			} else {
				defs.reusableElements[element.id] = [element]
			}
			return
		}
		if elementStack.isEmpty {
			rootElements.append(element)
		} else {
			elementStack[elementStack.count - 1].children.append(element)
		}
	}

	private func parsePaintAttributes(_ attributes: [String: String]) -> SVGPaintAttributes {
		let inherited = elementStack.last?.attributes ?? rootPaintAttributes
		var result = inherited
		result.transform = .identity

		if let className = attributes["class"] {
			for cls in className.split(separator: " ") {
				if let cssProps = styleSheet[String(cls)] {
					applyCSS(cssProps, to: &result)
				}
			}
		}
		applyPresentationAttributes(attributes, to: &result)
		if let style = attributes["style"] {
			applyCSS(parseInlineCSS(style), to: &result)
		}
		return result
	}

	private func applyPresentationAttributes(_ attributes: [String: String], to result: inout SVGPaintAttributes) {
		if let fill = attributes["fill"] { result.fill = parsePaint(fill) }
		if let stroke = attributes["stroke"] { result.stroke = parsePaint(stroke) }
		if let value = attributes["stroke-width"], let number = Double(value) { result.strokeWidth = number }
		if let cap = attributes["stroke-linecap"] { result.strokeLineCap = parseLineCap(cap) }
		if let join = attributes["stroke-linejoin"] { result.strokeLineJoin = parseLineJoin(join) }
		if let value = attributes["stroke-miterlimit"], let number = Double(value) { result.strokeMiterLimit = number }
		if let value = attributes["stroke-dasharray"] { result.strokeDashArray = parseDashArray(value) }
		if let value = attributes["stroke-dashoffset"], let number = Double(value) { result.strokeDashOffset = number }
		if let value = attributes["stroke-opacity"], let number = Double(value) { result.strokeOpacity = number }
		if let value = attributes["opacity"], let number = Double(value) { result.opacity = number }
		if let value = attributes["fill-opacity"], let number = Double(value) { result.fillOpacity = number }
		if let value = attributes["fill-rule"] { result.fillRule = value == "evenodd" ? .evenOdd : .winding }
		if let value = attributes["visibility"] {
			result.visibility = value == "hidden" ? .hidden : value == "collapse" ? .collapse : .visible
		}
		if let value = attributes["display"] { result.display = value == "none" ? .none : .inline }
		if let value = attributes["clip-path"] { result.clipPathID = parseURLID(value) }
		if let value = attributes["filter"] { result.filterID = parseURLID(value) }
		if let value = attributes["mask"] { result.maskID = parseURLID(value) }
		if let transform = attributes["transform"] { result.transform = parseTransform(transform) }
	}

	private func applyCSS(_ props: [String: String], to result: inout SVGPaintAttributes) {
		applyPresentationAttributes(props, to: &result)
	}

	private func parseDashArray(_ value: String) -> [Double] {
		let trimmed = value.trimmingCharacters(in: .whitespaces)
		if trimmed == "none" { return [] }
		return trimmed.split(whereSeparator: { $0 == "," || $0 == " " })
			.compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
	}

	private func parseURLID(_ value: String) -> String? {
		let trimmed = value.trimmingCharacters(in: .whitespaces)
		if trimmed.hasPrefix("url(#") && trimmed.hasSuffix(")") {
			return String(trimmed.dropFirst(5).dropLast())
		}
		return nil
	}

	private func parseSVGRoot(_ attributes: [String: String]) {
		if let vb = attributes["viewBox"] {
			let parts = vb.split(whereSeparator: { $0 == " " || $0 == "," }).compactMap { Double($0) }
			if parts.count == 4 {
				viewBox = Rect(x: parts[0], y: parts[1], width: parts[2], height: parts[3])
			}
		}
		rootWidth = attributes["width"].flatMap { parseDimension($0) }
		rootHeight = attributes["height"].flatMap { parseDimension($0) }
		rootPaintAttributes = parsePaintAttributes(attributes)
	}

	private func parseDimension(_ value: String) -> Double? {
		Double(value.replacingOccurrences(of: "px", with: "").replacingOccurrences(of: "pt", with: "").trimmingCharacters(in: .whitespaces))
	}

	private func resolveID(_ explicit: String?, elementName: String) -> String {
		if let explicit { return explicit }
		let count = (elementCounters[elementName] ?? 0) + 1
		elementCounters[elementName] = count
		return "\(elementName) \(count)"
	}

	private func parsePaint(_ value: String) -> SVGPaint {
		let trimmed = value.trimmingCharacters(in: .whitespaces)
		if trimmed == "none" { return .none }
		if trimmed == "currentColor" { return .currentColor }
		if trimmed.hasPrefix("url(#"), let id = parseURLID(trimmed) { return .url(id) }
		if let color = parseColor(trimmed) { return .color(color) }
		return .color(.black)
	}

	private func parseColor(_ value: String) -> Color? {
		if value.hasPrefix("#") { return hexColor(value) }
		if value.hasPrefix("rgb") { return rgbColor(value) }
		return namedColor(value)
	}

	private func hexColor(_ hex: String) -> Color? {
		var str = hex.trimmingCharacters(in: .whitespaces)
		if str.hasPrefix("#") { str.removeFirst() }
		if str.count == 3 { str = str.map { "\($0)\($0)" }.joined() }
		guard str.count == 6, let value = UInt64(str, radix: 16) else { return nil }
		return Color(Double((value >> 16) & 0xFF) / 255, Double((value >> 8) & 0xFF) / 255, Double(value & 0xFF) / 255)
	}

	private func rgbColor(_ value: String) -> Color? {
		let inner = value.drop { $0 != "(" }.dropFirst().prefix { $0 != ")" }
		let parts = inner.split(whereSeparator: { $0 == "," || $0 == " " }).compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
		guard parts.count >= 3 else { return nil }
		return Color(parts[0] / 255, parts[1] / 255, parts[2] / 255)
	}

	private func namedColor(_ value: String) -> Color? {
		switch value.lowercased() {
		case "black": .black
		case "white": .white
		case "red": .red
		case "green": .green
		case "blue": .blue
		case "yellow": Color(1, 1, 0)
		case "cyan", "aqua": Color(0, 1, 1)
		case "magenta", "fuchsia": Color(1, 0, 1)
		case "orange": Color(1, 0.647, 0)
		case "gray", "grey": Color(0.5, 0.5, 0.5)
		case "silver": Color(0.753, 0.753, 0.753)
		case "maroon": Color(0.5, 0, 0)
		case "purple": Color(0.5, 0, 0.5)
		case "navy": Color(0, 0, 0.5)
		case "teal": Color(0, 0.5, 0.5)
		case "olive": Color(0.5, 0.5, 0)
		case "lime": Color(0, 1, 0)
		default: nil
		}
	}

	private func parseLineCap(_ value: String) -> LineCap {
		switch value {
		case "round": .round
		case "square": .square
		default: .butt
		}
	}

	private func parseLineJoin(_ value: String) -> LineJoin {
		switch value {
		case "round": .round
		case "bevel": .bevel
		default: .miter
		}
	}

	private func parseTransform(_ value: String) -> Transform {
		var transform = Transform.identity
		guard let regex = try? NSRegularExpression(pattern: #"(\w+)\(([^)]+)\)"#) else { return transform }
		let nsValue = value as NSString
		for match in regex.matches(in: value, range: NSRange(location: 0, length: nsValue.length)) {
			let function = nsValue.substring(with: match.range(at: 1))
			let args = nsValue.substring(with: match.range(at: 2))
				.split(whereSeparator: { $0 == "," || $0 == " " })
				.compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
			switch function {
			case "translate" where args.count >= 1:
				transform = transform.translatedBy(x: args[0], y: args.count >= 2 ? args[1] : 0)
			case "scale" where args.count >= 1:
				transform = transform.scaledBy(x: args[0], y: args.count >= 2 ? args[1] : args[0])
			case "rotate" where args.count >= 1:
				transform = transform.rotated(by: args[0] * .pi / 180)
			case "matrix" where args.count == 6:
				transform = transform.concatenating(Transform(a: args[0], b: args[1], c: args[2], d: args[3], tx: args[4], ty: args[5]))
			default:
				break
			}
		}
		return transform
	}

	private func parsePoints(_ value: String) -> [Point] {
		let numbers = value.split(whereSeparator: { $0 == " " || $0 == "," }).compactMap { Double($0) }
		var points: [Point] = []
		var index = 0
		while index + 1 < numbers.count {
			points.append(Point(numbers[index], numbers[index + 1]))
			index += 2
		}
		return points
	}

	private func double(_ value: String?) -> Double {
		guard let value, let number = Double(value) else { return 0 }
		return number
	}
}

private extension SVGElement {
	var id: String {
		switch self {
		case .path(let data): data.id
		case .rect(let data): data.id
		case .circle(let data): data.id
		case .ellipse(let data): data.id
		case .line(let data): data.id
		case .polygon(let data): data.id
		case .polyline(let data): data.id
		case .group(let data): data.id
		case .use(let data): data.id
		case .image(let data): data.id
		case .text(let data): data.id
		}
	}
}

/// Mutable builder used during SVG parsing to accumulate group children.
private final class SVGGroupBuilder {
	let id: String
	let attributes: SVGPaintAttributes
	var children: [SVGElement] = []

	init(id: String, attributes: SVGPaintAttributes) {
		self.id = id
		self.attributes = attributes
	}
}

/// Mutable builder used during SVG text parsing.
private final class SVGTextBuilder {
	let id: String
	let x: Double
	let y: Double
	let fontSize: Double
	let fontFamily: String
	let fontWeight: String
	let textAnchor: SVGTextAnchor
	let attributes: SVGPaintAttributes
	var spans: [SVGTextSpan] = []

	init(id: String, x: Double, y: Double, fontSize: Double, fontFamily: String, fontWeight: String, textAnchor: SVGTextAnchor, attributes: SVGPaintAttributes) {
		self.id = id
		self.x = x
		self.y = y
		self.fontSize = fontSize
		self.fontFamily = fontFamily
		self.fontWeight = fontWeight
		self.textAnchor = textAnchor
		self.attributes = attributes
	}
}
