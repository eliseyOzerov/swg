import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

/// Parses SVG XML data into an `SVGDocument`.
public final class SVGParser: NSObject, XMLParserDelegate {
	fileprivate static let svgNamespaceURI = "http://www.w3.org/2000/svg"
	private static let knownSVGElementNames: Set<String> = [
		"a", "animate", "animateMotion", "animateTransform", "circle", "clipPath", "defs", "desc", "discard", "ellipse",
		"feBlend", "feColorMatrix", "feComponentTransfer", "feComposite", "feConvolveMatrix", "feDiffuseLighting",
		"feDisplacementMap", "feDistantLight", "feDropShadow", "feFlood", "feFuncA", "feFuncB", "feFuncG", "feFuncR",
		"feGaussianBlur", "feImage", "feMerge", "feMergeNode", "feMorphology", "feOffset", "fePointLight",
		"feSpecularLighting", "feSpotLight", "feTile", "feTurbulence", "filter", "foreignObject", "g", "image",
		"line", "linearGradient", "marker", "mask", "metadata", "mpath", "path", "pattern", "polygon", "polyline",
		"radialGradient", "rect", "script", "set", "stop", "style", "svg", "switch", "symbol", "text", "textPath",
		"title", "tspan", "use", "view"
	]
	private static let globalAttributeNames: Set<String> = [
		"class", "clip-path", "clip-rule", "color", "display", "filter", "fill", "fill-opacity", "fill-rule", "id", "mask", "opacity", "paint-order", "stroke",
		"stroke-dasharray", "stroke-dashoffset", "stroke-linecap", "stroke-linejoin", "stroke-miterlimit", "stroke-opacity",
		"stroke-width", "style", "transform", "vector-effect", "visibility", "lang", "xml:lang", "xml:space", "requiredExtensions", "systemLanguage",
		"zoomAndPan"
	]
	private static let basicShapeGeometryPropertyNames: Set<String> = [
		"x", "y", "cx", "cy", "r", "rx", "ry", "width", "height"
	]
	private static let namedColors: [String: Color] = [
		"aliceblue": Color(240 / 255, 248 / 255, 1),
		"antiquewhite": Color(250 / 255, 235 / 255, 215 / 255),
		"aqua": Color(0, 1, 1),
		"aquamarine": Color(127 / 255, 1, 212 / 255),
		"azure": Color(240 / 255, 1, 1),
		"beige": Color(245 / 255, 245 / 255, 220 / 255),
		"bisque": Color(1, 228 / 255, 196 / 255),
		"black": .black,
		"blanchedalmond": Color(1, 235 / 255, 205 / 255),
		"blue": .blue,
		"blueviolet": Color(138 / 255, 43 / 255, 226 / 255),
		"brown": Color(165 / 255, 42 / 255, 42 / 255),
		"burlywood": Color(222 / 255, 184 / 255, 135 / 255),
		"cadetblue": Color(95 / 255, 158 / 255, 160 / 255),
		"chartreuse": Color(127 / 255, 1, 0),
		"chocolate": Color(210 / 255, 105 / 255, 30 / 255),
		"coral": Color(1, 127 / 255, 80 / 255),
		"cornflowerblue": Color(100 / 255, 149 / 255, 237 / 255),
		"cornsilk": Color(1, 248 / 255, 220 / 255),
		"crimson": Color(220 / 255, 20 / 255, 60 / 255),
		"cyan": Color(0, 1, 1),
		"darkblue": Color(0, 0, 139 / 255),
		"darkcyan": Color(0, 139 / 255, 139 / 255),
		"darkgoldenrod": Color(184 / 255, 134 / 255, 11 / 255),
		"darkgray": Color(169 / 255, 169 / 255, 169 / 255),
		"darkgreen": Color(0, 100 / 255, 0),
		"darkgrey": Color(169 / 255, 169 / 255, 169 / 255),
		"darkkhaki": Color(189 / 255, 183 / 255, 107 / 255),
		"darkmagenta": Color(139 / 255, 0, 139 / 255),
		"darkolivegreen": Color(85 / 255, 107 / 255, 47 / 255),
		"darkorange": Color(1, 140 / 255, 0),
		"darkorchid": Color(153 / 255, 50 / 255, 204 / 255),
		"darkred": Color(139 / 255, 0, 0),
		"darksalmon": Color(233 / 255, 150 / 255, 122 / 255),
		"darkseagreen": Color(143 / 255, 188 / 255, 143 / 255),
		"darkslateblue": Color(72 / 255, 61 / 255, 139 / 255),
		"darkslategray": Color(47 / 255, 79 / 255, 79 / 255),
		"darkslategrey": Color(47 / 255, 79 / 255, 79 / 255),
		"darkturquoise": Color(0, 206 / 255, 209 / 255),
		"darkviolet": Color(148 / 255, 0, 211 / 255),
		"deeppink": Color(1, 20 / 255, 147 / 255),
		"deepskyblue": Color(0, 191 / 255, 1),
		"dimgray": Color(105 / 255, 105 / 255, 105 / 255),
		"dimgrey": Color(105 / 255, 105 / 255, 105 / 255),
		"dodgerblue": Color(30 / 255, 144 / 255, 1),
		"firebrick": Color(178 / 255, 34 / 255, 34 / 255),
		"floralwhite": Color(1, 250 / 255, 240 / 255),
		"forestgreen": Color(34 / 255, 139 / 255, 34 / 255),
		"fuchsia": Color(1, 0, 1),
		"gainsboro": Color(220 / 255, 220 / 255, 220 / 255),
		"ghostwhite": Color(248 / 255, 248 / 255, 1),
		"gold": Color(1, 215 / 255, 0),
		"goldenrod": Color(218 / 255, 165 / 255, 32 / 255),
		"gray": .gray,
		"green": Color(0, 128 / 255, 0),
		"greenyellow": Color(173 / 255, 1, 47 / 255),
		"grey": .gray,
		"honeydew": Color(240 / 255, 1, 240 / 255),
		"hotpink": Color(1, 105 / 255, 180 / 255),
		"indianred": Color(205 / 255, 92 / 255, 92 / 255),
		"indigo": Color(75 / 255, 0, 130 / 255),
		"ivory": Color(1, 1, 240 / 255),
		"khaki": Color(240 / 255, 230 / 255, 140 / 255),
		"lavender": Color(230 / 255, 230 / 255, 250 / 255),
		"lavenderblush": Color(1, 240 / 255, 245 / 255),
		"lawngreen": Color(124 / 255, 252 / 255, 0),
		"lemonchiffon": Color(1, 250 / 255, 205 / 255),
		"lightblue": Color(173 / 255, 216 / 255, 230 / 255),
		"lightcoral": Color(240 / 255, 128 / 255, 128 / 255),
		"lightcyan": Color(224 / 255, 1, 1),
		"lightgoldenrodyellow": Color(250 / 255, 250 / 255, 210 / 255),
		"lightgray": Color(211 / 255, 211 / 255, 211 / 255),
		"lightgreen": Color(144 / 255, 238 / 255, 144 / 255),
		"lightgrey": Color(211 / 255, 211 / 255, 211 / 255),
		"lightpink": Color(1, 182 / 255, 193 / 255),
		"lightsalmon": Color(1, 160 / 255, 122 / 255),
		"lightseagreen": Color(32 / 255, 178 / 255, 170 / 255),
		"lightskyblue": Color(135 / 255, 206 / 255, 250 / 255),
		"lightslategray": Color(119 / 255, 136 / 255, 153 / 255),
		"lightslategrey": Color(119 / 255, 136 / 255, 153 / 255),
		"lightsteelblue": Color(176 / 255, 196 / 255, 222 / 255),
		"lightyellow": Color(1, 1, 224 / 255),
		"lime": Color(0, 1, 0),
		"limegreen": Color(50 / 255, 205 / 255, 50 / 255),
		"linen": Color(250 / 255, 240 / 255, 230 / 255),
		"magenta": Color(1, 0, 1),
		"maroon": Color(128 / 255, 0, 0),
		"mediumaquamarine": Color(102 / 255, 205 / 255, 170 / 255),
		"mediumblue": Color(0, 0, 205 / 255),
		"mediumorchid": Color(186 / 255, 85 / 255, 211 / 255),
		"mediumpurple": Color(147 / 255, 112 / 255, 219 / 255),
		"mediumseagreen": Color(60 / 255, 179 / 255, 113 / 255),
		"mediumslateblue": Color(123 / 255, 104 / 255, 238 / 255),
		"mediumspringgreen": Color(0, 250 / 255, 154 / 255),
		"mediumturquoise": Color(72 / 255, 209 / 255, 204 / 255),
		"mediumvioletred": Color(199 / 255, 21 / 255, 133 / 255),
		"midnightblue": Color(25 / 255, 25 / 255, 112 / 255),
		"mintcream": Color(245 / 255, 1, 250 / 255),
		"mistyrose": Color(1, 228 / 255, 225 / 255),
		"moccasin": Color(1, 228 / 255, 181 / 255),
		"navajowhite": Color(1, 222 / 255, 173 / 255),
		"navy": Color(0, 0, 128 / 255),
		"oldlace": Color(253 / 255, 245 / 255, 230 / 255),
		"olive": Color(128 / 255, 128 / 255, 0),
		"olivedrab": Color(107 / 255, 142 / 255, 35 / 255),
		"orange": Color(1, 165 / 255, 0),
		"orangered": Color(1, 69 / 255, 0),
		"orchid": Color(218 / 255, 112 / 255, 214 / 255),
		"palegoldenrod": Color(238 / 255, 232 / 255, 170 / 255),
		"palegreen": Color(152 / 255, 251 / 255, 152 / 255),
		"paleturquoise": Color(175 / 255, 238 / 255, 238 / 255),
		"palevioletred": Color(219 / 255, 112 / 255, 147 / 255),
		"papayawhip": Color(1, 239 / 255, 213 / 255),
		"peachpuff": Color(1, 218 / 255, 185 / 255),
		"peru": Color(205 / 255, 133 / 255, 63 / 255),
		"pink": Color(1, 192 / 255, 203 / 255),
		"plum": Color(221 / 255, 160 / 255, 221 / 255),
		"powderblue": Color(176 / 255, 224 / 255, 230 / 255),
		"purple": Color(128 / 255, 0, 128 / 255),
		"red": .red,
		"rosybrown": Color(188 / 255, 143 / 255, 143 / 255),
		"royalblue": Color(65 / 255, 105 / 255, 225 / 255),
		"saddlebrown": Color(139 / 255, 69 / 255, 19 / 255),
		"salmon": Color(250 / 255, 128 / 255, 114 / 255),
		"sandybrown": Color(244 / 255, 164 / 255, 96 / 255),
		"seagreen": Color(46 / 255, 139 / 255, 87 / 255),
		"seashell": Color(1, 245 / 255, 238 / 255),
		"sienna": Color(160 / 255, 82 / 255, 45 / 255),
		"silver": Color(192 / 255, 192 / 255, 192 / 255),
		"skyblue": Color(135 / 255, 206 / 255, 235 / 255),
		"slateblue": Color(106 / 255, 90 / 255, 205 / 255),
		"slategray": Color(112 / 255, 128 / 255, 144 / 255),
		"slategrey": Color(112 / 255, 128 / 255, 144 / 255),
		"snow": Color(1, 250 / 255, 250 / 255),
		"springgreen": Color(0, 1, 127 / 255),
		"steelblue": Color(70 / 255, 130 / 255, 180 / 255),
		"tan": Color(210 / 255, 180 / 255, 140 / 255),
		"teal": Color(0, 128 / 255, 128 / 255),
		"thistle": Color(216 / 255, 191 / 255, 216 / 255),
		"tomato": Color(1, 99 / 255, 71 / 255),
		"turquoise": Color(64 / 255, 224 / 255, 208 / 255),
		"violet": Color(238 / 255, 130 / 255, 238 / 255),
		"wheat": Color(245 / 255, 222 / 255, 179 / 255),
		"white": .white,
		"whitesmoke": Color(245 / 255, 245 / 255, 245 / 255),
		"yellow": Color(1, 1, 0),
		"yellowgreen": Color(154 / 255, 205 / 255, 50 / 255)
	]

	private let supportedExtensions: Set<String>
	private let languagePreferences: [String]
	private var viewBox: Rect = .zero
	private var rootPreserveAspectRatio: SVGPreserveAspectRatio = .default
	private var rootID: String?
	private var rootWidth: Double?
	private var rootHeight: Double?
	private var rootLanguage: String?
	private var rootPaintAttributes: SVGPaintAttributes = .defaults
	private var rootUnknownAttributes: [String: String] = [:]
	private var elementStack: [SVGElementBuilder] = []
	private var rootElements: [SVGElement] = []
	private var elementCounters: [String: Int] = [:]
	private var defs = SVGDefs()
	private var inDefs = false
	private var defsElementStack: [SVGElementBuilder] = []
	private var symbolElementStack: [SVGElementBuilder] = []
	private var currentLinearGradient: SVGLinearGradientDef?
	private var currentRadialGradient: SVGRadialGradientDef?
	private var currentGradientStops: [SVGGradientStop] = []
	private var patternStack: [SVGPatternDef] = []
	private var patternElementStack: [SVGElementBuilder] = []
	private var currentFilter: SVGFilterDef?
	private var inMask = false
	private var currentMaskID: String?
	private var currentMaskUnits: SVGMaskUnits = .objectBoundingBox
	private var currentMaskContentUnits: SVGMaskUnits = .userSpaceOnUse
	private var maskElements: [SVGElement] = []
	private var inClipPath = false
	private var currentClipPathID: String?
	private var currentClipPathUnits: SVGClipPathUnits = .userSpaceOnUse
	private var clipPathElements: [SVGElement] = []
	private var clipPathAttributeStack: [SVGPaintAttributes] = []
	private var inText = false
	private var textBuilder: SVGTextBuilder?
	private var currentSpanAttrs: SVGPaintAttributes?
	private var xmlSpaceStack: [SVGXMLSpaceMode] = [.default]
	private var inStyleElement = false
	private var styleText = ""
	private var styleSheet: [String: [String: String]] = [:]
	private var styleMediaApplies = true
	private var characterBuffer = ""
	private var currentTitle: SVGTitleBuilder?
	private var rootTitles: [SVGTitleData] = []
	private var elementTitles: [String: [SVGTitleData]] = [:]
	private var currentDescription: SVGDescriptionBuilder?
	private var rootDescriptions: [SVGDescriptionData] = []
	private var elementDescriptions: [String: [SVGDescriptionData]] = [:]
	private var currentMetadata: SVGMetadataBuilder?
	private var rootMetadata: [SVGMetadataData] = []
	private var elementMetadata: [String: [SVGMetadataData]] = [:]
	private var namespaceStack: [SVGNamespaceContext] = [.empty]
	private var languageStack: [String?] = [nil]
	private var viewportContextStack: [SVGLengthContext] = [.default]
	private var parsedElementStack: [SVGParsedElement] = []

	public init(supportedExtensions: Set<String> = [], languagePreferences: [String] = []) {
		self.supportedExtensions = supportedExtensions
		self.languagePreferences = languagePreferences.map { $0.lowercased() }
		super.init()
	}

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
		return SVGDocument(
			id: rootID,
			viewBox: resolvedViewBox,
			preserveAspectRatio: rootPreserveAspectRatio,
			elements: rootElements,
			defs: defs,
			language: rootLanguage,
			unknownAttributes: rootUnknownAttributes,
			rootTitles: rootTitles,
			elementTitles: elementTitles,
			selectedTitle: selectTitle(rootTitles),
			selectedElementTitles: elementTitles.compactMapValues(selectTitle),
			rootDescriptions: rootDescriptions,
			elementDescriptions: elementDescriptions,
			selectedDescription: selectDescription(rootDescriptions),
			selectedElementDescriptions: elementDescriptions.compactMapValues(selectDescription),
			rootMetadata: rootMetadata,
			elementMetadata: elementMetadata
		)
	}

	public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String]) {
		if !inText && currentTitle == nil && currentDescription == nil && currentMetadata == nil {
			characterBuffer = ""
		}

		var namespaceContext = namespaceStack.last ?? .empty
		namespaceContext.applyDeclarations(from: attributes)
		namespaceStack.append(namespaceContext)
		let inheritedLanguage = currentLanguage
		languageStack.append(parseLanguage(attributes, inherited: inheritedLanguage))

		let expandedName = namespaceContext.expandedElementName(for: elementName)
		let parsedElement = SVGParsedElement(localName: expandedName.localName, namespaceURI: expandedName.namespaceURI)
		parsedElementStack.append(parsedElement)
		if currentTitle != nil {
			parsedElementStack[parsedElementStack.count - 1].role = .titleContent
			return
		}
		if currentDescription != nil {
			parsedElementStack[parsedElementStack.count - 1].role = .descriptionContent
			return
		}
		if currentMetadata != nil {
			appendMetadataElement(parsedElement: parsedElement, qualifiedName: elementName, attributes: attributes)
			parsedElementStack[parsedElementStack.count - 1].role = .metadataContent
			return
		}
		guard parsedElement.isSVGElement else { return }
		let elementName = parsedElement.localName
		if parsedElement.hasSkippedAncestor(in: parsedElementStack.dropLast()) {
			parsedElementStack[parsedElementStack.count - 1].role = .skipped
			return
		}
		if let switchBuilder = currentOpenContainerBuilder, switchBuilder.isSwitch {
			if switchBuilder.switchHasSelectedChild || !conditionalAttributesPass(attributes) {
				parsedElementStack[parsedElementStack.count - 1].role = .skipped
				return
			}
			switchBuilder.switchHasSelectedChild = true
		}

		switch elementName {
		case "svg":
			if parsedElement.hasSVGAncestor(in: parsedElementStack.dropLast()) {
				parseNestedSVGStart(attributes)
				parsedElementStack[parsedElementStack.count - 1].role = .svgContainer
			} else {
				parseSVGRoot(attributes)
				parsedElementStack[parsedElementStack.count - 1].role = .svgRoot
			}
		case "defs":
			inDefs = true
		case "symbol":
			parseSymbolStart(attributes)
		case "switch":
			parseSwitchStart(attributes)
			parsedElementStack[parsedElementStack.count - 1].role = .switchContainer
		case "view":
			parseView(attributes)
			parsedElementStack[parsedElementStack.count - 1].role = .skipped
		case "a":
			parseLinkStart(attributes)
			parsedElementStack[parsedElementStack.count - 1].role = .linkContainer
		case "title":
			parseTitleStart(attributes)
			parsedElementStack[parsedElementStack.count - 1].role = .title
		case "desc":
			parseDescriptionStart(attributes)
			parsedElementStack[parsedElementStack.count - 1].role = .description
		case "metadata":
			parseMetadataStart(attributes)
			parsedElementStack[parsedElementStack.count - 1].role = .metadata
		case "style":
			inStyleElement = true
			styleMediaApplies = styleMediaMatches(attributes["media"])
			styleText = ""
		case "linearGradient":
			parseLinearGradientStart(attributes)
		case "radialGradient":
			parseRadialGradientStart(attributes)
		case "pattern":
			parsePatternStart(attributes)
		case "stop":
			parseGradientStop(attributes)
		case "clipPath":
			currentClipPathID = attributes["id"]
			currentClipPathUnits = parseClipPathUnits(attributes["clipPathUnits"])
			clipPathElements = []
			clipPathAttributeStack.append(parsePaintAttributes(attributes))
			inClipPath = true
		case "filter":
			currentFilter = SVGFilterDef(
				id: attributes["id"] ?? "",
				filterUnits: parseFilterUnits(attributes["filterUnits"]),
				primitiveUnits: parseFilterPrimitiveUnits(attributes["primitiveUnits"])
			)
		case "feGaussianBlur":
			if let std = attributes["stdDeviation"].flatMap(parseNumber) {
				currentFilter?.primitives.append(.gaussianBlur(stdDeviation: std))
			}
		case "feDropShadow":
			let dx = attributes["dx"].flatMap(parseNumber) ?? 0
			let dy = attributes["dy"].flatMap(parseNumber) ?? 0
			let std = attributes["stdDeviation"].flatMap(parseNumber) ?? 0
			let color = attributes["flood-color"].flatMap { parseColor($0) } ?? .black
			let opacity = attributes["flood-opacity"].flatMap(parseNumber) ?? 1
			currentFilter?.primitives.append(.dropShadow(dx: dx, dy: dy, stdDeviation: std, color: color.withAlpha(opacity)))
		case "mask":
			inMask = true
			currentMaskID = attributes["id"]
			currentMaskUnits = parseMaskUnits(attributes["maskUnits"])
			currentMaskContentUnits = parseMaskContentUnits(attributes["maskContentUnits"])
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
			setCurrentParsedElementID(id)
			let builder = SVGElementBuilder(kind: .group, id: id, attributes: attrs, language: currentLanguage, unknownAttributes: parseUnknownAttributes(attributes, known: []))
			if !patternStack.isEmpty {
				patternElementStack.append(builder)
			} else if !symbolElementStack.isEmpty {
				symbolElementStack.append(builder)
			} else if inDefs {
				defsElementStack.append(builder)
			} else if !inClipPath && !inMask {
				elementStack.append(builder)
			}
		default:
			if !parseShapeElement(elementName, attributes: attributes), !Self.knownSVGElementNames.contains(elementName) {
				parseUnknownElementStart(elementName, namespaceURI: parsedElement.namespaceURI, attributes: attributes)
				parsedElementStack[parsedElementStack.count - 1].role = .unknownContainer
			}
		}
	}

	public func parser(_ parser: XMLParser, foundCharacters string: String) {
		characterBuffer += string
	}

	public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
		let parsedElement = parsedElementStack.last
		defer {
			if !parsedElementStack.isEmpty { parsedElementStack.removeLast() }
			if !namespaceStack.isEmpty { namespaceStack.removeLast() }
			if !languageStack.isEmpty { languageStack.removeLast() }
		}
		guard let parsedElement, parsedElement.isSVGElement else {
			if currentMetadata != nil, let parsedElement {
				finalizeMetadataElement(parsedElement: parsedElement)
			} else if currentTitle == nil && currentDescription == nil {
				characterBuffer = ""
			}
			return
		}
		if parsedElement.role == .titleContent || parsedElement.role == .descriptionContent {
			return
		}
		if parsedElement.role == .metadataContent {
			finalizeMetadataElement(parsedElement: parsedElement)
			return
		}
		if parsedElement.role == .skipped {
			characterBuffer = ""
			return
		}
		let elementName = parsedElement.localName

		switch elementName {
		case "svg":
			if parsedElement.role == .svgContainer {
				finalizeContainerElement()
			}
			popViewportContext()
		case "defs":
			inDefs = false
		case "symbol":
			finalizeSymbolElement()
			popViewportContext()
		case "switch":
			finalizeContainerElement()
		case "a":
			finalizeContainerElement()
		case "title":
			finalizeTitle()
		case "desc":
			finalizeDescription()
		case "metadata":
			finalizeMetadata()
		case "style":
			styleText += characterBuffer
			characterBuffer = ""
			if styleMediaApplies {
				parseStyleSheet(styleText)
			}
			inStyleElement = false
			styleMediaApplies = true
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
		case "pattern":
			if let pattern = patternStack.popLast() {
				defs.patterns[pattern.id] = pattern
			}
		case "clipPath":
			if let id = currentClipPathID {
				defs.clipPathDefinitions[id] = SVGClipPathDef(id: id, units: currentClipPathUnits, children: clipPathElements)
				defs.clipPaths[id] = clipPathElements
			}
			if !clipPathAttributeStack.isEmpty {
				clipPathAttributeStack.removeLast()
			}
			inClipPath = false
			currentClipPathID = nil
			currentClipPathUnits = .userSpaceOnUse
		case "filter":
			if let filter = currentFilter {
				defs.filters[filter.id] = filter
			}
			currentFilter = nil
		case "mask":
			if let id = currentMaskID {
				defs.masks[id] = SVGMaskDef(id: id, maskUnits: currentMaskUnits, maskContentUnits: currentMaskContentUnits, children: maskElements)
			}
			inMask = false
			currentMaskID = nil
			currentMaskUnits = .objectBoundingBox
			currentMaskContentUnits = .userSpaceOnUse
		case "text":
			finalizeText()
		case "tspan":
			finalizeTSpan()
		case "g":
			finalizeContainerElement()
		default:
			if parsedElement.role == .unknownContainer {
				finalizeContainerElement()
			}
		}

		if inStyleElement {
			styleText += characterBuffer
		}
		characterBuffer = ""
	}

	private func reset() {
		viewBox = .zero
		rootPreserveAspectRatio = .default
		rootID = nil
		rootWidth = nil
		rootHeight = nil
		rootLanguage = nil
		rootPaintAttributes = .defaults
		rootUnknownAttributes = [:]
		elementStack = []
		rootElements = []
		elementCounters = [:]
		defs = SVGDefs()
		inDefs = false
		defsElementStack = []
		symbolElementStack = []
		currentLinearGradient = nil
		currentRadialGradient = nil
		currentGradientStops = []
		patternStack = []
		patternElementStack = []
		currentFilter = nil
		inMask = false
		currentMaskID = nil
		currentMaskUnits = .objectBoundingBox
		currentMaskContentUnits = .userSpaceOnUse
		maskElements = []
		inClipPath = false
		currentClipPathID = nil
		currentClipPathUnits = .userSpaceOnUse
		clipPathElements = []
		clipPathAttributeStack = []
		inText = false
		textBuilder = nil
		currentSpanAttrs = nil
		xmlSpaceStack = [.default]
		inStyleElement = false
		styleText = ""
		styleSheet = [:]
		styleMediaApplies = true
		characterBuffer = ""
		currentTitle = nil
		rootTitles = []
		elementTitles = [:]
		currentDescription = nil
		rootDescriptions = []
		elementDescriptions = [:]
		currentMetadata = nil
		rootMetadata = []
		elementMetadata = [:]
		namespaceStack = [.empty]
		languageStack = [nil]
		viewportContextStack = [.default]
		parsedElementStack = []
	}

	private func parseShapeElement(_ elementName: String, attributes: [String: String]) -> Bool {
		switch elementName {
		case "path":
			if let d = attributes["d"] {
				let attrs = parsePaintAttributes(attributes)
				let id = resolveID(attributes["id"], elementName: "Path")
				setCurrentParsedElementID(id)
				appendElement(.path(SVGPathData(id: id, d: d, attributes: attrs, language: currentLanguage, unknownAttributes: parseUnknownAttributes(attributes, known: ["d"]))))
			}
			return true
		case "rect":
			let attrs = parsePaintAttributes(attributes)
			let id = resolveID(attributes["id"], elementName: "Rect")
			setCurrentParsedElementID(id)
			let geometry = parseBasicShapeGeometryProperties(attributes)
			let parsedRX = nonnegativeOptionalDimension(geometry["rx"], percentageBasis: .horizontal)
			let parsedRY = nonnegativeOptionalDimension(geometry["ry"], percentageBasis: .vertical)
			appendElement(.rect(SVGRectData(id: id, x: dimension(geometry["x"], percentageBasis: .horizontal), y: dimension(geometry["y"], percentageBasis: .vertical), width: nonnegativeDimension(geometry["width"], percentageBasis: .horizontal), height: nonnegativeDimension(geometry["height"], percentageBasis: .vertical), rx: parsedRX ?? 0, ry: parsedRY ?? 0, attributes: attrs, rxIsAuto: parsedRX == nil, ryIsAuto: parsedRY == nil, language: currentLanguage, unknownAttributes: parseUnknownAttributes(attributes, known: ["x", "y", "width", "height", "rx", "ry"]))))
			return true
		case "circle":
			let attrs = parsePaintAttributes(attributes)
			let id = resolveID(attributes["id"], elementName: "Circle")
			setCurrentParsedElementID(id)
			let geometry = parseBasicShapeGeometryProperties(attributes)
			appendElement(.circle(SVGCircleData(id: id, cx: dimension(geometry["cx"], percentageBasis: .horizontal), cy: dimension(geometry["cy"], percentageBasis: .vertical), r: nonnegativeDimension(geometry["r"], percentageBasis: .normalizedDiagonal), attributes: attrs, language: currentLanguage, unknownAttributes: parseUnknownAttributes(attributes, known: ["cx", "cy", "r"]))))
			return true
		case "ellipse":
			let attrs = parsePaintAttributes(attributes)
			let id = resolveID(attributes["id"], elementName: "Ellipse")
			setCurrentParsedElementID(id)
			let geometry = parseBasicShapeGeometryProperties(attributes)
			let parsedRX = nonnegativeOptionalDimension(geometry["rx"], percentageBasis: .horizontal)
			let parsedRY = nonnegativeOptionalDimension(geometry["ry"], percentageBasis: .vertical)
			appendElement(.ellipse(SVGEllipseData(id: id, cx: dimension(geometry["cx"], percentageBasis: .horizontal), cy: dimension(geometry["cy"], percentageBasis: .vertical), rx: parsedRX ?? 0, ry: parsedRY ?? 0, attributes: attrs, rxIsAuto: parsedRX == nil, ryIsAuto: parsedRY == nil, language: currentLanguage, unknownAttributes: parseUnknownAttributes(attributes, known: ["cx", "cy", "rx", "ry"]))))
			return true
		case "line":
			let attrs = parsePaintAttributes(attributes)
			let id = resolveID(attributes["id"], elementName: "Line")
			setCurrentParsedElementID(id)
			appendElement(.line(SVGLineData(id: id, x1: double(attributes["x1"]), y1: double(attributes["y1"]), x2: double(attributes["x2"]), y2: double(attributes["y2"]), attributes: attrs, language: currentLanguage, unknownAttributes: parseUnknownAttributes(attributes, known: ["x1", "y1", "x2", "y2"]))))
			return true
		case "polygon":
			let attrs = parsePaintAttributes(attributes)
			let id = resolveID(attributes["id"], elementName: "Polygon")
			setCurrentParsedElementID(id)
			appendElement(.polygon(SVGPolygonData(id: id, points: parsePoints(attributes["points"] ?? ""), attributes: attrs, language: currentLanguage, unknownAttributes: parseUnknownAttributes(attributes, known: ["points"]))))
			return true
		case "polyline":
			let attrs = parsePaintAttributes(attributes)
			let id = resolveID(attributes["id"], elementName: "Polyline")
			setCurrentParsedElementID(id)
			appendElement(.polyline(SVGPolylineData(id: id, points: parsePoints(attributes["points"] ?? ""), attributes: attrs, language: currentLanguage, unknownAttributes: parseUnknownAttributes(attributes, known: ["points"]))))
			return true
		default:
			return false
		}
	}

	private func parseSymbolStart(_ attributes: [String: String]) {
		let attrs = parsePaintAttributes(attributes)
		let id = resolveID(attributes["id"], elementName: "Symbol")
		setCurrentParsedElementID(id)
		let viewportContext = currentViewportContext
		let width = parseSVGSize(attributes["width"], percentageBasis: .horizontal, context: viewportContext)
		let height = parseSVGSize(attributes["height"], percentageBasis: .vertical, context: viewportContext)
		let builder = SVGElementBuilder(
			kind: .symbol(
				x: parseSVGPosition(attributes["x"], percentageBasis: .horizontal, context: viewportContext),
				y: parseSVGPosition(attributes["y"], percentageBasis: .vertical, context: viewportContext),
				width: width,
				height: height,
				viewBox: attributes["viewBox"].flatMap(parseViewBox),
				preserveAspectRatio: parsePreserveAspectRatio(attributes["preserveAspectRatio"]),
				refX: attributes["refX"],
				refY: attributes["refY"]
			),
			id: id,
			attributes: attrs,
			language: currentLanguage,
			unknownAttributes: parseUnknownAttributes(attributes, known: ["x", "y", "width", "height", "viewBox", "preserveAspectRatio", "refX", "refY"])
		)
		symbolElementStack.append(builder)
		pushViewportContext(width: width, height: height, base: viewportContext)
	}

	private func parseSwitchStart(_ attributes: [String: String]) {
		let attrs = parsePaintAttributes(attributes)
		let id = resolveID(attributes["id"], elementName: "Switch")
		setCurrentParsedElementID(id)
		let builder = SVGElementBuilder(kind: .switch, id: id, attributes: attrs, language: currentLanguage, unknownAttributes: parseUnknownAttributes(attributes, known: []))
		if !patternStack.isEmpty {
			patternElementStack.append(builder)
		} else if !symbolElementStack.isEmpty {
			symbolElementStack.append(builder)
		} else if inDefs {
			defsElementStack.append(builder)
		} else if !inClipPath && !inMask {
			elementStack.append(builder)
		}
	}

	private func parseLinkStart(_ attributes: [String: String]) {
		let attrs = parsePaintAttributes(attributes)
		let id = resolveID(attributes["id"], elementName: "A")
		setCurrentParsedElementID(id)
		let builder = SVGElementBuilder(
			kind: .link(
				href: hasOpenLinkAncestor ? nil : parseRawHref(attributes),
				target: attributes["target"] ?? "_self",
				download: attributes["download"],
				ping: attributes["ping"],
				rel: attributes["rel"],
				hreflang: attributes["hreflang"],
				type: attributes["type"],
				referrerPolicy: attributes["referrerpolicy"],
				xlinkTitle: xlinkAttribute("title", in: attributes)
			),
			id: id,
			attributes: attrs,
			language: currentLanguage,
			unknownAttributes: parseUnknownAttributes(attributes, known: ["href", "xlink:href", "target", "download", "ping", "rel", "hreflang", "type", "referrerpolicy", "xlink:title"])
		)
		if !patternStack.isEmpty {
			patternElementStack.append(builder)
		} else if !symbolElementStack.isEmpty {
			symbolElementStack.append(builder)
		} else if inDefs {
			defsElementStack.append(builder)
		} else if !inClipPath && !inMask {
			elementStack.append(builder)
		}
	}

	private func parseView(_ attributes: [String: String]) {
		let id = resolveID(attributes["id"], elementName: "View")
		setCurrentParsedElementID(id)
		defs.views[id] = SVGViewData(
			id: id,
			viewBox: attributes["viewBox"].flatMap(parseViewBox),
			preserveAspectRatio: parseOptionalPreserveAspectRatio(attributes["preserveAspectRatio"]),
			zoomAndPan: parseZoomAndPan(attributes["zoomAndPan"]),
			language: currentLanguage,
			unknownAttributes: parseUnknownAttributes(attributes, known: ["viewBox", "preserveAspectRatio"])
		)
	}

	private func parseUnknownElementStart(_ elementName: String, namespaceURI: String?, attributes: [String: String]) {
		let attrs = parsePaintAttributes(attributes)
		let id = resolveID(attributes["id"], elementName: elementName)
		setCurrentParsedElementID(id)
		let builder = SVGElementBuilder(kind: .unknown(name: elementName, namespaceURI: namespaceURI), id: id, attributes: attrs, language: currentLanguage, unknownAttributes: parseUnknownAttributes(attributes, known: []))
		if !patternStack.isEmpty {
			patternElementStack.append(builder)
		} else if !symbolElementStack.isEmpty {
			symbolElementStack.append(builder)
		} else if inDefs {
			defsElementStack.append(builder)
		} else if !inClipPath && !inMask {
			elementStack.append(builder)
		}
	}

	private func parseNestedSVGStart(_ attributes: [String: String]) {
		let attrs = parsePaintAttributes(attributes)
		let id = resolveID(attributes["id"], elementName: "SVG")
		setCurrentParsedElementID(id)
		let viewportContext = currentViewportContext
		let width = parseSVGSize(attributes["width"], percentageBasis: .horizontal, context: viewportContext)
		let height = parseSVGSize(attributes["height"], percentageBasis: .vertical, context: viewportContext)
		let builder = SVGElementBuilder(
			kind: .svg(
				x: parseSVGPosition(attributes["x"], percentageBasis: .horizontal, context: viewportContext),
				y: parseSVGPosition(attributes["y"], percentageBasis: .vertical, context: viewportContext),
				width: width,
				height: height,
				viewBox: attributes["viewBox"].flatMap(parseViewBox),
				preserveAspectRatio: parsePreserveAspectRatio(attributes["preserveAspectRatio"])
			),
			id: id,
			attributes: attrs,
			language: currentLanguage,
			unknownAttributes: parseUnknownAttributes(attributes, known: ["x", "y", "width", "height", "viewBox", "preserveAspectRatio"])
		)
		if !patternStack.isEmpty {
			patternElementStack.append(builder)
		} else if !symbolElementStack.isEmpty {
			symbolElementStack.append(builder)
		} else if inDefs {
			defsElementStack.append(builder)
		} else if !inClipPath && !inMask {
			elementStack.append(builder)
		}
		pushViewportContext(width: width, height: height, base: viewportContext)
	}

	private func parseLinearGradientStart(_ attributes: [String: String]) {
		let units = parseGradientUnits(attributes["gradientUnits"])
		var gradient = SVGLinearGradientDef(
			id: attributes["id"] ?? "",
			x2: defaultLinearGradientX2(units: units),
			gradientUnits: units
		)
		if let v = attributes["x1"] { gradient.x1 = parseGradientCoord(v, units: units, percentageBasis: .horizontal) }
		if let v = attributes["y1"] { gradient.y1 = parseGradientCoord(v, units: units, percentageBasis: .vertical) }
		if let v = attributes["x2"] { gradient.x2 = parseGradientCoord(v, units: units, percentageBasis: .horizontal) }
		if let v = attributes["y2"] { gradient.y2 = parseGradientCoord(v, units: units, percentageBasis: .vertical) }
		if let transform = attributes["gradientTransform"] { gradient.gradientTransform = parseTransform(transform) }
		if let spreadMethod = parseGradientSpreadMethod(attributes["spreadMethod"]) { gradient.spreadMethod = spreadMethod }
		gradient.href = parseHref(attributes)
		currentLinearGradient = gradient
		currentGradientStops = []
	}

	private func parseRadialGradientStart(_ attributes: [String: String]) {
		let units = parseGradientUnits(attributes["gradientUnits"])
		var gradient = SVGRadialGradientDef(
			id: attributes["id"] ?? "",
			cx: defaultRadialGradientCX(units: units),
			cy: defaultRadialGradientCY(units: units),
			r: defaultRadialGradientRadius(units: units),
			gradientUnits: units
		)
		if let v = attributes["cx"] { gradient.cx = parseGradientCoord(v, units: units, percentageBasis: .horizontal) }
		if let v = attributes["cy"] { gradient.cy = parseGradientCoord(v, units: units, percentageBasis: .vertical) }
		if let v = attributes["r"], let radius = parseNonnegativeGradientCoord(v, units: units, percentageBasis: .normalizedDiagonal) { gradient.r = radius }
		if let v = attributes["fx"] { gradient.fx = parseGradientCoord(v, units: units, percentageBasis: .horizontal) }
		if let v = attributes["fy"] { gradient.fy = parseGradientCoord(v, units: units, percentageBasis: .vertical) }
		if let v = attributes["fr"], let radius = parseNonnegativeGradientCoord(v, units: units, percentageBasis: .normalizedDiagonal) { gradient.fr = radius }
		if let transform = attributes["gradientTransform"] { gradient.gradientTransform = parseTransform(transform) }
		if let spreadMethod = parseGradientSpreadMethod(attributes["spreadMethod"]) { gradient.spreadMethod = spreadMethod }
		gradient.href = parseHref(attributes)
		currentRadialGradient = gradient
		currentGradientStops = []
	}

	private func parsePatternStart(_ attributes: [String: String]) {
		let units = parsePatternUnits(attributes["patternUnits"])
		var pattern = SVGPatternDef(
			id: attributes["id"] ?? "",
			patternUnits: units,
			patternContentUnits: parsePatternContentUnits(attributes["patternContentUnits"]),
			attributes: parsePaintAttributes(attributes),
			language: currentLanguage,
			unknownAttributes: parseUnknownAttributes(attributes, known: ["x", "y", "width", "height", "patternUnits", "patternContentUnits", "patternTransform", "viewBox", "preserveAspectRatio", "href", "xlink:href"])
		)
		setCurrentParsedElementID(pattern.id)
		if let v = attributes["x"] { pattern.x = parsePatternTileCoord(v, units: units, percentageBasis: .horizontal) }
		if let v = attributes["y"] { pattern.y = parsePatternTileCoord(v, units: units, percentageBasis: .vertical) }
		if let v = attributes["width"], let width = parseNonnegativePatternTileCoord(v, units: units, percentageBasis: .horizontal) { pattern.width = width }
		if let v = attributes["height"], let height = parseNonnegativePatternTileCoord(v, units: units, percentageBasis: .vertical) { pattern.height = height }
		if let transform = attributes["patternTransform"] { pattern.patternTransform = parseTransform(transform) }
		pattern.viewBox = attributes["viewBox"].flatMap(parseViewBox)
		pattern.preserveAspectRatio = parsePreserveAspectRatio(attributes["preserveAspectRatio"])
		pattern.href = parseHref(attributes)
		patternStack.append(pattern)
	}

	private func parseGradientStop(_ attributes: [String: String]) {
		let parsedOffset = attributes["offset"].flatMap(parseGradientStopOffset) ?? 0
		let offset = max(parsedOffset, currentGradientStops.last?.offset ?? 0)
		var style = SVGGradientStopStyle()
		applyGradientStopProperties(attributes, to: &style)
		if let className = attributes["class"] {
			for cls in className.split(separator: " ") {
				if let cssProps = styleSheet[String(cls)] {
					applyGradientStopProperties(cssProps, to: &style)
				}
			}
		}
		if let inlineStyle = attributes["style"] {
			applyGradientStopProperties(parseInlineCSS(inlineStyle), to: &style)
		}
		currentGradientStops.append(SVGGradientStop(offset: offset, color: style.stopColor.resolved(with: style.currentColor), opacity: style.opacity, stopColor: style.stopColor, currentColor: style.currentColor))
	}

	private func applyGradientStopProperties(_ properties: [String: String], to style: inout SVGGradientStopStyle) {
		if let color = properties["color"] {
			if isInheritKeyword(color) || color.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "currentcolor" {
				style.currentColor = .black
			} else if let parsed = parseColor(color) {
				style.currentColor = parsed
			}
		}
		if let opacity = properties["stop-opacity"].flatMap(parseAlphaValue) {
			style.opacity = opacity
		}
		if let stopColor = properties["stop-color"].flatMap({ parseGradientStopColor($0, opacity: &style.opacity) }) {
			style.stopColor = stopColor
		}
	}

	private func parseGradientStopColor(_ value: String, opacity: inout Double) -> SVGGradientStopColor? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		switch trimmed.lowercased() {
		case "currentcolor":
			return .currentColor
		case "transparent":
			opacity = 0
			return .color(.black)
		default:
			return parseColor(trimmed).map(SVGGradientStopColor.color)
		}
	}

	private func parseGradientStopOffset(_ value: String) -> Double? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		let parsed: Double?
		if trimmed.hasSuffix("%") {
			parsed = parseNumber(String(trimmed.dropLast())).map { $0 / 100 }
		} else {
			parsed = parseNumber(trimmed)
		}
		return parsed.map { min(max($0, 0), 1) }
	}

	private func parseGradientCoord(_ value: String, units: SVGGradientUnits, percentageBasis: SVGLengthPercentageBasis) -> Double {
		parseGradientCoordValue(value, units: units, percentageBasis: percentageBasis) ?? 0
	}

	private func parseNonnegativeGradientCoord(_ value: String, units: SVGGradientUnits, percentageBasis: SVGLengthPercentageBasis) -> Double? {
		guard let coordinate = parseGradientCoordValue(value, units: units, percentageBasis: percentageBasis), coordinate >= 0 else { return nil }
		return coordinate
	}

	private func parseGradientCoordValue(_ value: String, units: SVGGradientUnits, percentageBasis: SVGLengthPercentageBasis) -> Double? {
		if units == .userSpaceOnUse {
			return parseDimension(value, context: currentViewportContext, percentageBasis: percentageBasis)
		}
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.hasSuffix("%") {
			return parseNumber(String(trimmed.dropLast())).map { $0 / 100 }
		}
		return parseNumber(trimmed)
	}

	private func parseGradientUnits(_ value: String?) -> SVGGradientUnits {
		value == "userSpaceOnUse" ? .userSpaceOnUse : .objectBoundingBox
	}

	private func parsePatternTileCoord(_ value: String, units: SVGPatternUnits, percentageBasis: SVGLengthPercentageBasis) -> Double {
		parsePatternTileCoordValue(value, units: units, percentageBasis: percentageBasis) ?? 0
	}

	private func parseNonnegativePatternTileCoord(_ value: String, units: SVGPatternUnits, percentageBasis: SVGLengthPercentageBasis) -> Double? {
		guard let coordinate = parsePatternTileCoordValue(value, units: units, percentageBasis: percentageBasis), coordinate >= 0 else { return nil }
		return coordinate
	}

	private func parsePatternTileCoordValue(_ value: String, units: SVGPatternUnits, percentageBasis: SVGLengthPercentageBasis) -> Double? {
		if units == .userSpaceOnUse {
			return parseDimension(value, context: currentViewportContext, percentageBasis: percentageBasis)
		}
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.hasSuffix("%") {
			return parseNumber(String(trimmed.dropLast())).map { $0 / 100 }
		}
		return parseNumber(trimmed)
	}

	private func parsePatternUnits(_ value: String?) -> SVGPatternUnits {
		value == "userSpaceOnUse" ? .userSpaceOnUse : .objectBoundingBox
	}

	private func parsePatternContentUnits(_ value: String?) -> SVGPatternUnits {
		value == "objectBoundingBox" ? .objectBoundingBox : .userSpaceOnUse
	}

	private func parseClipPathUnits(_ value: String?) -> SVGClipPathUnits {
		value == "objectBoundingBox" ? .objectBoundingBox : .userSpaceOnUse
	}

	private func parseFilterUnits(_ value: String?) -> SVGFilterUnits {
		value == "userSpaceOnUse" ? .userSpaceOnUse : .objectBoundingBox
	}

	private func parseFilterPrimitiveUnits(_ value: String?) -> SVGFilterPrimitiveUnits {
		value == "objectBoundingBox" ? .objectBoundingBox : .userSpaceOnUse
	}

	private func parseMaskUnits(_ value: String?) -> SVGMaskUnits {
		value == "userSpaceOnUse" ? .userSpaceOnUse : .objectBoundingBox
	}

	private func parseMaskContentUnits(_ value: String?) -> SVGMaskUnits {
		value == "objectBoundingBox" ? .objectBoundingBox : .userSpaceOnUse
	}

	private func parseGradientSpreadMethod(_ value: String?) -> SVGGradientSpreadMethod? {
		switch value {
		case "pad":
			.pad
		case "reflect":
			.reflect
		case "repeat":
			.repeat
		default:
			nil
		}
	}

	private func defaultLinearGradientX2(units: SVGGradientUnits) -> Double {
		switch units {
		case .objectBoundingBox:
			1
		case .userSpaceOnUse:
			SVGLengthPercentageBasis.horizontal.referenceDistance(in: currentViewportContext)
		}
	}

	private func defaultRadialGradientCX(units: SVGGradientUnits) -> Double {
		switch units {
		case .objectBoundingBox:
			0.5
		case .userSpaceOnUse:
			SVGLengthPercentageBasis.horizontal.referenceDistance(in: currentViewportContext) / 2
		}
	}

	private func defaultRadialGradientCY(units: SVGGradientUnits) -> Double {
		switch units {
		case .objectBoundingBox:
			0.5
		case .userSpaceOnUse:
			SVGLengthPercentageBasis.vertical.referenceDistance(in: currentViewportContext) / 2
		}
	}

	private func defaultRadialGradientRadius(units: SVGGradientUnits) -> Double {
		switch units {
		case .objectBoundingBox:
			0.5
		case .userSpaceOnUse:
			SVGLengthPercentageBasis.normalizedDiagonal.referenceDistance(in: currentViewportContext) / 2
		}
	}

	private func parseHref(_ attributes: [String: String]) -> String? {
		guard let raw = attributes["href"] ?? xlinkAttribute("href", in: attributes), let reference = SVGURLParser.parse(raw) else { return nil }
		return reference.localFragmentID ?? reference.rawValue
	}

	private func parseRawHref(_ attributes: [String: String]) -> String? {
		guard let raw = attributes["href"] ?? xlinkAttribute("href", in: attributes), let reference = SVGURLParser.parse(raw) else { return nil }
		return reference.rawValue
	}

	private func parseUse(_ attributes: [String: String]) {
		let id = resolveID(attributes["id"], elementName: "Use")
		setCurrentParsedElementID(id)
		let href = parseHref(attributes) ?? ""
		let viewportContext = currentViewportContext
		appendElement(.use(SVGUseData(
			id: id,
			href: href,
			x: parseSVGPosition(attributes["x"], percentageBasis: .horizontal, context: viewportContext),
			y: parseSVGPosition(attributes["y"], percentageBasis: .vertical, context: viewportContext),
			width: parseUseSize(attributes["width"], percentageBasis: .horizontal, context: viewportContext),
			height: parseUseSize(attributes["height"], percentageBasis: .vertical, context: viewportContext),
			attributes: parsePaintAttributes(attributes),
			language: currentLanguage,
			unknownAttributes: parseUnknownAttributes(attributes, known: ["href", "xlink:href", "x", "y", "width", "height"])
		)))
	}

	private func parseImage(_ attributes: [String: String]) {
		let id = resolveID(attributes["id"], elementName: "Image")
		setCurrentParsedElementID(id)
		let href = (attributes["href"] ?? xlinkAttribute("href", in: attributes)).flatMap { SVGURLParser.parse($0)?.rawValue } ?? ""
		appendElement(.image(SVGImageData(id: id, x: double(attributes["x"]), y: double(attributes["y"]), width: double(attributes["width"]), height: double(attributes["height"]), href: href, attributes: parsePaintAttributes(attributes), language: currentLanguage, unknownAttributes: parseUnknownAttributes(attributes, known: ["href", "xlink:href", "x", "y", "width", "height"]))))
	}

	private func xlinkAttribute(_ localName: String, in attributes: [String: String]) -> String? {
		attributes["xlink:\(localName)"]
	}

	private func parseTextStart(_ attributes: [String: String]) {
		inText = true
		xmlSpaceStack = [parseXMLSpace(attributes["xml:space"], inherited: .default)]
		let attrs = parsePaintAttributes(attributes)
		let id = resolveID(attributes["id"], elementName: "Text")
		setCurrentParsedElementID(id)
		textBuilder = SVGTextBuilder(
			id: id,
			x: double(attributes["x"]),
			y: double(attributes["y"]),
			fontSize: double(attributes["font-size"]),
			fontFamily: attributes["font-family"] ?? "",
			fontWeight: attributes["font-weight"] ?? "normal",
			textAnchor: parseTextAnchor(attributes["text-anchor"]),
			attributes: attrs,
			language: currentLanguage,
			unknownAttributes: parseUnknownAttributes(attributes, known: ["x", "y", "font-size", "font-family", "font-weight", "text-anchor"])
		)
	}

	private func parseTitleStart(_ attributes: [String: String]) {
		let id = resolveID(attributes["id"], elementName: "Title")
		setCurrentParsedElementID(id)
		let parent = currentDescriptiveParent()
		currentTitle = SVGTitleBuilder(
			id: id,
			parentID: parent.id,
			isRootTitle: parent.isRoot,
			language: parseDescriptiveLanguage(attributes),
			unknownAttributes: parseUnknownAttributes(attributes, known: []),
			xmlSpaceMode: parseXMLSpace(attributes["xml:space"], inherited: .default)
		)
	}

	private func finalizeTitle() {
		guard let currentTitle else { return }
		let text = normalizeTextWhitespace(characterBuffer, mode: currentTitle.xmlSpaceMode)
		let title = SVGTitleData(id: currentTitle.id, text: text, language: currentTitle.language, unknownAttributes: currentTitle.unknownAttributes)
		if currentTitle.isRootTitle {
			rootTitles.append(title)
		} else if let parentID = currentTitle.parentID {
			elementTitles[parentID, default: []].append(title)
		}
		self.currentTitle = nil
		characterBuffer = ""
	}

	private func parseDescriptionStart(_ attributes: [String: String]) {
		let id = resolveID(attributes["id"], elementName: "Desc")
		setCurrentParsedElementID(id)
		let parent = currentDescriptiveParent()
		currentDescription = SVGDescriptionBuilder(
			id: id,
			parentID: parent.id,
			isRootDescription: parent.isRoot,
			language: parseDescriptiveLanguage(attributes),
			unknownAttributes: parseUnknownAttributes(attributes, known: []),
			xmlSpaceMode: parseXMLSpace(attributes["xml:space"], inherited: .default)
		)
	}

	private func finalizeDescription() {
		guard let currentDescription else { return }
		let text = normalizeTextWhitespace(characterBuffer, mode: currentDescription.xmlSpaceMode)
		let description = SVGDescriptionData(id: currentDescription.id, text: text, language: currentDescription.language, unknownAttributes: currentDescription.unknownAttributes)
		if currentDescription.isRootDescription {
			rootDescriptions.append(description)
		} else if let parentID = currentDescription.parentID {
			elementDescriptions[parentID, default: []].append(description)
		}
		self.currentDescription = nil
		characterBuffer = ""
	}

	private func parseMetadataStart(_ attributes: [String: String]) {
		let id = resolveID(attributes["id"], elementName: "Metadata")
		setCurrentParsedElementID(id)
		let parent = currentDescriptiveParent()
		currentMetadata = SVGMetadataBuilder(
			id: id,
			parentID: parent.id,
			isRootMetadata: parent.isRoot,
			language: currentLanguage,
			unknownAttributes: parseUnknownAttributes(attributes, known: [])
		)
	}

	private func appendMetadataElement(parsedElement: SVGParsedElement, qualifiedName: String, attributes: [String: String]) {
		appendMetadataTextFromBuffer()
		let builder = SVGMetadataElementBuilder(
			name: qualifiedName,
			localName: parsedElement.localName,
			namespaceURI: parsedElement.namespaceURI,
			attributes: attributes.filter { name, _ in !name.isNamespaceDeclaration }
		)
		currentMetadata?.elementStack.append(builder)
	}

	private func finalizeMetadataElement(parsedElement: SVGParsedElement) {
		appendMetadataTextFromBuffer()
		guard let currentMetadata, !currentMetadata.elementStack.isEmpty else { return }
		let builder = currentMetadata.elementStack.removeLast()
		let node = SVGMetadataNode.element(builder.build())
		if let parent = currentMetadata.elementStack.last {
			parent.children.append(node)
		} else {
			currentMetadata.children.append(node)
		}
	}

	private func appendMetadataTextFromBuffer() {
		let text = normalizeDefaultTextWhitespace(characterBuffer)
		characterBuffer = ""
		guard !text.isEmpty, let currentMetadata else { return }
		let node = SVGMetadataNode.text(text)
		if let parent = currentMetadata.elementStack.last {
			parent.children.append(node)
		} else {
			currentMetadata.children.append(node)
		}
	}

	private func finalizeMetadata() {
		appendMetadataTextFromBuffer()
		guard let currentMetadata else { return }
		let metadata = SVGMetadataData(id: currentMetadata.id, language: currentMetadata.language, unknownAttributes: currentMetadata.unknownAttributes, children: currentMetadata.children)
		if currentMetadata.isRootMetadata {
			rootMetadata.append(metadata)
		} else if let parentID = currentMetadata.parentID {
			elementMetadata[parentID, default: []].append(metadata)
		}
		self.currentMetadata = nil
		characterBuffer = ""
	}

	private func parseTSpanStart(_ attributes: [String: String]) {
		let buffered = normalizeTextWhitespace(characterBuffer, mode: currentXMLSpaceMode)
		if !buffered.isEmpty, let textBuilder {
			textBuilder.spans.append(SVGTextSpan(text: buffered, x: nil, y: nil, dx: 0, dy: 0, fontSize: nil, fontWeight: nil, attributes: nil, language: parentLanguageForCurrentElement))
		}
		characterBuffer = ""
		xmlSpaceStack.append(parseXMLSpace(attributes["xml:space"], inherited: currentXMLSpaceMode))
		currentSpanAttrs = parsePaintAttributes(attributes)
	}

	private func finalizeTSpan() {
		let text = normalizeTextWhitespace(characterBuffer, mode: currentXMLSpaceMode)
		let attributes = currentSpanAttrs
		characterBuffer = ""
		currentSpanAttrs = nil
		if xmlSpaceStack.count > 1 {
			xmlSpaceStack.removeLast()
		}
		guard !text.isEmpty, let textBuilder else { return }
		textBuilder.spans.append(SVGTextSpan(text: text, x: nil, y: nil, dx: 0, dy: 0, fontSize: nil, fontWeight: nil, attributes: attributes, language: currentLanguage))
	}

	private func finalizeText() {
		let text = normalizeTextWhitespace(characterBuffer, mode: currentXMLSpaceMode)
		if !text.isEmpty, let textBuilder {
			textBuilder.spans.append(SVGTextSpan(text: text, x: nil, y: nil, dx: 0, dy: 0, fontSize: nil, fontWeight: nil, attributes: nil, language: currentLanguage))
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
				spans: textBuilder.spans,
				language: textBuilder.language,
				unknownAttributes: textBuilder.unknownAttributes
			)))
		}
		textBuilder = nil
		inText = false
		xmlSpaceStack = [.default]
	}

	private var currentXMLSpaceMode: SVGXMLSpaceMode {
		xmlSpaceStack.last ?? .default
	}

	private var currentLanguage: String? {
		languageStack.last ?? nil
	}

	private var parentLanguageForCurrentElement: String? {
		guard languageStack.count > 1 else { return nil }
		return languageStack[languageStack.count - 2]
	}

	private func parseLanguage(_ attributes: [String: String], inherited: String?) -> String? {
		guard let rawValue = attributes["xml:lang"] ?? attributes["lang"] else {
			return inherited
		}
		return rawValue.isEmpty ? nil : rawValue
	}

	private func parseDescriptiveLanguage(_ attributes: [String: String]) -> String? {
		if let rawValue = attributes["xml:lang"] ?? attributes["lang"] {
			return rawValue
		}
		return currentLanguage
	}

	private func parseXMLSpace(_ value: String?, inherited: SVGXMLSpaceMode) -> SVGXMLSpaceMode {
		switch value {
		case "default":
			.default
		case "preserve":
			.preserve
		default:
			inherited
		}
	}

	private func normalizeTextWhitespace(_ value: String, mode: SVGXMLSpaceMode) -> String {
		switch mode {
		case .default:
			normalizeDefaultTextWhitespace(value)
		case .preserve:
			normalizePreservedTextWhitespace(value)
		}
	}

	private func normalizeDefaultTextWhitespace(_ value: String) -> String {
		let mapped = value.compactMap { character -> Character? in
			switch character {
			case "\n", "\r":
				nil
			case "\t", "\u{000C}":
				" "
			default:
				character
			}
		}
		var result = ""
		var previousWasSpace = true
		for character in mapped {
			if character == " " {
				if !previousWasSpace {
					result.append(character)
					previousWasSpace = true
				}
			} else {
				result.append(character)
				previousWasSpace = false
			}
		}
		if result.last == " " {
			result.removeLast()
		}
		return result
	}

	private func normalizePreservedTextWhitespace(_ value: String) -> String {
		String(value.map { character -> Character in
			switch character {
			case "\n", "\r", "\t", "\u{000C}":
				" "
			default:
				character
			}
		})
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

	private func styleMediaMatches(_ media: String?) -> Bool {
		guard let media else { return true }
		let queries = media.split(separator: ",")
		guard !queries.isEmpty else { return false }
		return queries.contains { query in
			switch String(query).trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
			case "all", "screen": true
			default: false
			}
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
		if !patternStack.isEmpty {
			if let last = patternElementStack.last {
				last.children.append(element)
			} else {
				patternStack[patternStack.count - 1].children.append(element)
			}
			return
		}
		if inClipPath {
			clipPathElements.append(element)
			return
		}
		if inMask {
			maskElements.append(element)
			return
		}
		if let symbolBuilder = symbolElementStack.last {
			symbolBuilder.children.append(element)
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

	private func finalizeContainerElement() {
		if let builder = patternElementStack.last {
			_ = patternElementStack.popLast()
			appendElement(builder.buildElement())
		} else if let builder = symbolElementStack.last, !builder.isSymbol {
			_ = symbolElementStack.popLast()
			appendElement(builder.buildElement())
		} else if inDefs {
			guard let builder = defsElementStack.popLast() else { return }
			let element = builder.buildElement()
			if let parent = defsElementStack.last {
				parent.children.append(element)
			} else {
				defs.reusableElements[element.id] = [element]
			}
		} else if let builder = elementStack.popLast() {
			appendElement(builder.buildElement())
		}
	}

	private func finalizeSymbolElement() {
		guard let builder = symbolElementStack.popLast() else { return }
		defs.symbols[builder.id] = builder.buildSymbolData()
	}

	private var currentOpenContainerBuilder: SVGElementBuilder? {
		patternElementStack.last ?? symbolElementStack.last ?? defsElementStack.last ?? elementStack.last
	}

	private func currentDescriptiveParent() -> (isRoot: Bool, id: String?) {
		guard parsedElementStack.count > 1 else { return (false, nil) }
		let parent = parsedElementStack[parsedElementStack.count - 2]
		return (parent.role == .svgRoot, parent.id)
	}

	private func setCurrentParsedElementID(_ id: String?) {
		guard !parsedElementStack.isEmpty else { return }
		parsedElementStack[parsedElementStack.count - 1].id = id
	}

	private var hasOpenLinkAncestor: Bool {
		patternElementStack.contains { $0.isLink } || symbolElementStack.contains { $0.isLink } || defsElementStack.contains { $0.isLink } || elementStack.contains { $0.isLink }
	}

	private func conditionalAttributesPass(_ attributes: [String: String]) -> Bool {
		requiredExtensionsPass(attributes["requiredExtensions"]) && systemLanguagePass(attributes["systemLanguage"])
	}

	private func requiredExtensionsPass(_ value: String?) -> Bool {
		guard let value else { return true }
		let tokens = value.split(whereSeparator: { $0.isWhitespace }).map(String.init)
		guard !tokens.isEmpty else { return false }
		return tokens.allSatisfy { supportedExtensions.contains($0) }
	}

	private func systemLanguagePass(_ value: String?) -> Bool {
		guard let value else { return true }
		let tags = value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
		guard !tags.isEmpty, !languagePreferences.isEmpty, !tags.contains("") else { return false }
		for preference in languagePreferences {
			for tag in tags where tag == preference || tag.hasPrefix("\(preference)-") {
				return true
			}
		}
		return false
	}

	private func parsePaintAttributes(_ attributes: [String: String]) -> SVGPaintAttributes {
		let parent = patternElementStack.last?.attributes ?? patternStack.last?.attributes ?? clipPathAttributeStack.last ?? symbolElementStack.last?.attributes ?? (inDefs ? defsElementStack.last?.attributes : elementStack.last?.attributes) ?? rootPaintAttributes
		var result = inheritedPaintAttributes(from: parent)

		applyPresentationAttributes(attributes, to: &result, inherited: parent)
		if let className = attributes["class"] {
			for cls in className.split(separator: " ") {
				if let cssProps = styleSheet[String(cls)] {
					applyCSS(cssProps, to: &result, inherited: parent)
				}
			}
		}
		if let style = attributes["style"] {
			applyCSS(parseInlineCSS(style), to: &result, inherited: parent)
		}
		return result
	}

	private func inheritedPaintAttributes(from parent: SVGPaintAttributes) -> SVGPaintAttributes {
		var result = SVGPaintAttributes.defaults
		result.color = parent.color
		result.fill = parent.fill
		result.fillOpacity = parent.fillOpacity
		result.fillRule = parent.fillRule
		result.clipRule = parent.clipRule
		result.stroke = parent.stroke
		result.strokeWidth = parent.strokeWidth
		result.strokeLineCap = parent.strokeLineCap
		result.strokeLineJoin = parent.strokeLineJoin
		result.strokeMiterLimit = parent.strokeMiterLimit
		result.strokeDashArray = parent.strokeDashArray
		result.strokeDashOffset = parent.strokeDashOffset
		result.strokeOpacity = parent.strokeOpacity
		result.paintOrder = parent.paintOrder
		result.colorInterpolation = parent.colorInterpolation
		result.colorRendering = parent.colorRendering
		result.shapeRendering = parent.shapeRendering
		result.textRendering = parent.textRendering
		result.imageRendering = parent.imageRendering
		result.visibility = parent.visibility
		return result
	}

	private func parseUnknownAttributes(_ attributes: [String: String], known: Set<String>) -> [String: String] {
		let interpreted = Self.globalAttributeNames.union(known)
		return attributes.filter { name, _ in
			!name.isNamespaceDeclaration && !interpreted.contains(name)
		}
	}

	private func parseBasicShapeGeometryProperties(_ attributes: [String: String]) -> [String: String] {
		var result: [String: String] = [:]
		applyGeometryProperties(attributes, to: &result)

		if let className = attributes["class"] {
			for cls in className.split(separator: " ") {
				if let cssProps = styleSheet[String(cls)] {
					applyGeometryProperties(cssProps, to: &result)
				}
			}
		}

		if let style = attributes["style"] {
			applyGeometryProperties(parseInlineCSS(style), to: &result)
		}
		return result
	}

	private func applyGeometryProperties(_ properties: [String: String], to result: inout [String: String]) {
		for (name, value) in properties where Self.basicShapeGeometryPropertyNames.contains(name) {
			result[name] = value
		}
	}

	private func applyPresentationAttributes(_ attributes: [String: String], to result: inout SVGPaintAttributes, inherited: SVGPaintAttributes) {
		if let color = attributes["color"] {
			if isInheritKeyword(color) || isCurrentColorKeyword(color) {
				result.color = inherited.color
			} else if let parsed = parseColor(color) {
				result.color = parsed
			}
		}
		if let fill = attributes["fill"] {
			if isInheritKeyword(fill) {
				result.fill = inherited.fill
			} else if let paint = parsePaint(fill) {
				result.fill = paint
			}
		}
		if let stroke = attributes["stroke"] {
			if isInheritKeyword(stroke) {
				result.stroke = inherited.stroke
			} else if let paint = parsePaint(stroke) {
				result.stroke = paint
			}
		}
		if let value = attributes["stroke-width"] {
			if isInheritKeyword(value) {
				result.strokeWidth = inherited.strokeWidth
			} else if let number = parseNumber(value) {
				result.strokeWidth = number
			}
		}
		if let cap = attributes["stroke-linecap"] {
			if isInheritKeyword(cap) {
				result.strokeLineCap = inherited.strokeLineCap
			} else if let lineCap = parseLineCap(cap) {
				result.strokeLineCap = lineCap
			}
		}
		if let join = attributes["stroke-linejoin"] {
			if isInheritKeyword(join) {
				result.strokeLineJoin = inherited.strokeLineJoin
			} else if let lineJoin = parseLineJoin(join) {
				result.strokeLineJoin = lineJoin
			}
		}
		if let value = attributes["stroke-miterlimit"] {
			if isInheritKeyword(value) {
				result.strokeMiterLimit = inherited.strokeMiterLimit
			} else if let number = parseNumber(value), number >= 0 {
				result.strokeMiterLimit = number
			}
		}
		if let value = attributes["stroke-dasharray"] {
			if isInheritKeyword(value) {
				result.strokeDashArray = inherited.strokeDashArray
			} else if let dashArray = parseDashArray(value) {
				result.strokeDashArray = dashArray
			}
		}
		if let value = attributes["stroke-dashoffset"] {
			if isInheritKeyword(value) {
				result.strokeDashOffset = inherited.strokeDashOffset
			} else if let length = parseDimension(value, context: currentViewportContext, percentageBasis: .normalizedDiagonal) {
				result.strokeDashOffset = length
			}
		}
		if let value = attributes["stroke-opacity"] {
			if isInheritKeyword(value) {
				result.strokeOpacity = inherited.strokeOpacity
			} else if let alpha = parseAlphaValue(value) {
				result.strokeOpacity = alpha
			}
		}
		if let value = attributes["paint-order"] {
			if isInheritKeyword(value) {
				result.paintOrder = inherited.paintOrder
			} else if let paintOrder = parsePaintOrder(value) {
				result.paintOrder = paintOrder
			}
		}
		if let value = attributes["color-interpolation"] {
			if isInheritKeyword(value) {
				result.colorInterpolation = inherited.colorInterpolation
			} else if let colorInterpolation = parseColorInterpolation(value) {
				result.colorInterpolation = colorInterpolation
			}
		}
		if let value = attributes["color-rendering"] {
			if isInheritKeyword(value) {
				result.colorRendering = inherited.colorRendering
			} else if let colorRendering = parseColorRendering(value) {
				result.colorRendering = colorRendering
			}
		}
		if let value = attributes["shape-rendering"] {
			if isInheritKeyword(value) {
				result.shapeRendering = inherited.shapeRendering
			} else if let shapeRendering = parseShapeRendering(value) {
				result.shapeRendering = shapeRendering
			}
		}
		if let value = attributes["text-rendering"] {
			if isInheritKeyword(value) {
				result.textRendering = inherited.textRendering
			} else if let textRendering = parseTextRendering(value) {
				result.textRendering = textRendering
			}
		}
		if let value = attributes["image-rendering"] {
			if isInheritKeyword(value) {
				result.imageRendering = inherited.imageRendering
			} else if let imageRendering = parseImageRendering(value) {
				result.imageRendering = imageRendering
			}
		}
		if let value = attributes["opacity"] {
			if isInheritKeyword(value) {
				result.opacity = inherited.opacity
			} else if let number = parseNumber(value) {
				result.opacity = min(max(number, 0), 1)
			}
		}
		if let value = attributes["fill-opacity"] {
			if isInheritKeyword(value) {
				result.fillOpacity = inherited.fillOpacity
			} else if let alpha = parseAlphaValue(value) {
				result.fillOpacity = alpha
			}
		}
		if let value = attributes["fill-rule"] {
			if isInheritKeyword(value) {
				result.fillRule = inherited.fillRule
			} else if let fillRule = parseFillRule(value) {
				result.fillRule = fillRule
			}
		}
		if let value = attributes["clip-rule"] {
			if isInheritKeyword(value) {
				result.clipRule = inherited.clipRule
			} else if let clipRule = parseFillRule(value) {
				result.clipRule = clipRule
			}
		}
		if let value = attributes["visibility"] {
			result.visibility = isInheritKeyword(value) ? inherited.visibility : value == "hidden" ? .hidden : value == "collapse" ? .collapse : .visible
		}
		if let value = attributes["display"] {
			result.display = isInheritKeyword(value) ? inherited.display : value == "none" ? .none : .inline
		}
		if let value = attributes["clip-path"] {
			if isInheritKeyword(value) {
				result.clipPath = inherited.clipPath
				result.clipPathID = inherited.clipPathID
			} else if let clipPath = parseClipPath(value) {
				result.clipPath = clipPath
				result.clipPathID = clipPath.localClipPathID
			}
		}
		if let value = attributes["filter"] { result.filterID = isInheritKeyword(value) ? inherited.filterID : parseURLID(value) }
		if let value = attributes["mask"] { result.maskID = isInheritKeyword(value) ? inherited.maskID : parseURLID(value) }
		if let value = attributes["vector-effect"] {
			if isInheritKeyword(value) {
				result.vectorEffect = inherited.vectorEffect
			} else if let vectorEffect = parseVectorEffect(value) {
				result.vectorEffect = vectorEffect
			}
		}
		if let transform = attributes["transform"] {
			result.transform = isInheritKeyword(transform) ? inherited.transform : parseTransform(transform)
		}
	}

	private func applyCSS(_ props: [String: String], to result: inout SVGPaintAttributes, inherited: SVGPaintAttributes) {
		applyPresentationAttributes(props, to: &result, inherited: inherited)
	}

	private func isInheritKeyword(_ value: String) -> Bool {
		value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "inherit"
	}

	private func isCurrentColorKeyword(_ value: String) -> Bool {
		value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "currentcolor"
	}

	private func parseDashArray(_ value: String) -> [Double]? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.lowercased() == "none" { return [] }
		let context = currentViewportContext
		guard let values = SVGListParser.parse(trimmed, itemParser: { parseDimension($0, context: context, percentageBasis: .normalizedDiagonal) }), !values.isEmpty else {
			return nil
		}
		return values.allSatisfy { $0 >= 0 } ? values : nil
	}

	private func parsePaintOrder(_ value: String) -> SVGPaintOrder? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
		if trimmed == "normal" { return .normal }
		let tokens = trimmed.split { $0.isWhitespace }.map(String.init)
		guard !tokens.isEmpty else { return nil }
		var operations: [SVGPaintOperation] = []
		for token in tokens {
			let operation: SVGPaintOperation
			switch token {
			case "fill":
				operation = .fill
			case "stroke":
				operation = .stroke
			case "markers":
				operation = .markers
			default:
				return nil
			}
			guard !operations.contains(operation) else { return nil }
			operations.append(operation)
		}
		return .specified(operations)
	}

	private func parseColorInterpolation(_ value: String) -> SVGColorInterpolation? {
		switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
		case "auto":
			return .auto
		case "srgb":
			return .sRGB
		case "linearrgb":
			return .linearRGB
		default:
			return nil
		}
	}

	private func parseColorRendering(_ value: String) -> SVGColorRendering? {
		switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
		case "auto":
			return .auto
		case "optimizespeed":
			return .optimizeSpeed
		case "optimizequality":
			return .optimizeQuality
		default:
			return nil
		}
	}

	private func parseShapeRendering(_ value: String) -> SVGShapeRendering? {
		switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
		case "auto":
			return .auto
		case "optimizespeed":
			return .optimizeSpeed
		case "crispedges":
			return .crispEdges
		case "geometricprecision":
			return .geometricPrecision
		default:
			return nil
		}
	}

	private func parseTextRendering(_ value: String) -> SVGTextRendering? {
		switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
		case "auto":
			return .auto
		case "optimizespeed":
			return .optimizeSpeed
		case "optimizelegibility":
			return .optimizeLegibility
		case "geometricprecision":
			return .geometricPrecision
		default:
			return nil
		}
	}

	private func parseImageRendering(_ value: String) -> SVGImageRendering? {
		switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
		case "auto":
			return .auto
		case "optimizequality":
			return .optimizeQuality
		case "optimizespeed":
			return .optimizeSpeed
		default:
			return nil
		}
	}

	private func parseAlphaValue(_ value: String) -> Double? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		let parsed: Double?
		if trimmed.hasSuffix("%") {
			parsed = parseNumber(String(trimmed.dropLast())).map { $0 / 100 }
		} else {
			parsed = parseNumber(trimmed)
		}
		guard let parsed else { return nil }
		return min(max(parsed, 0), 1)
	}

	private func parseFillRule(_ value: String) -> FillRule? {
		switch value.trimmingCharacters(in: .whitespacesAndNewlines) {
		case "nonzero":
			return .winding
		case "evenodd":
			return .evenOdd
		default:
			return nil
		}
	}

	private func parseVectorEffect(_ value: String) -> SVGVectorEffect? {
		let tokens = value.split(whereSeparator: { $0.isWhitespace }).map(String.init)
		guard !tokens.isEmpty else { return nil }
		if tokens == ["none"] { return SVGVectorEffect.none }

		var components: [SVGVectorEffectComponent] = []
		var coordinateSpace: SVGVectorEffectCoordinateSpace = .viewport
		var didReadCoordinateSpace = false

		for (index, token) in tokens.enumerated() {
			switch token {
			case "non-scaling-stroke":
				guard !didReadCoordinateSpace else { return nil }
				components.append(.nonScalingStroke)
			case "non-scaling-size":
				guard !didReadCoordinateSpace else { return nil }
				components.append(.nonScalingSize)
			case "non-rotation":
				guard !didReadCoordinateSpace else { return nil }
				components.append(.nonRotation)
			case "fixed-position":
				guard !didReadCoordinateSpace else { return nil }
				components.append(.fixedPosition)
			case "viewport":
				guard index == tokens.count - 1, !didReadCoordinateSpace else { return nil }
				coordinateSpace = .viewport
				didReadCoordinateSpace = true
			case "screen":
				guard index == tokens.count - 1, !didReadCoordinateSpace else { return nil }
				coordinateSpace = .screen
				didReadCoordinateSpace = true
			default:
				return nil
			}
		}

		guard !components.isEmpty else { return nil }
		return .effects(components, coordinateSpace: coordinateSpace)
	}

	private func parseURLID(_ value: String) -> String? {
		SVGURLParser.parseFunctional(value)?.localFragmentID
	}

	private func parseClipPath(_ value: String) -> SVGClipPathValue? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.lowercased() == "none" { return SVGClipPathValue.none }
		if let reference = SVGURLParser.parseFunctional(trimmed), let id = reference.localFragmentID {
			return .url(id)
		}

		let parts = splitClipPathValue(trimmed)
		if parts.count == 1, let box = parseGeometryBox(parts[0]) {
			return .geometryBox(box)
		}
		if parts.count == 1, isBasicShape(parts[0]) {
			return .basicShape(parts[0], geometryBox: nil)
		}
		if parts.count == 2, isBasicShape(parts[0]), let box = parseGeometryBox(parts[1]) {
			return .basicShape(parts[0], geometryBox: box)
		}
		return nil
	}

	private func splitClipPathValue(_ value: String) -> [String] {
		var parts: [String] = []
		var current = ""
		var depth = 0

		for character in value {
			if character == "(" {
				depth += 1
				current.append(character)
			} else if character == ")" {
				depth = max(0, depth - 1)
				current.append(character)
			} else if isWhitespace(character), depth == 0 {
				if !current.isEmpty {
					parts.append(current)
					current = ""
				}
			} else {
				current.append(character)
			}
		}

		if !current.isEmpty {
			parts.append(current)
		}
		return parts
	}

	private func parseGeometryBox(_ value: String) -> SVGGeometryBox? {
		SVGGeometryBox(rawValue: value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
	}

	private func isBasicShape(_ value: String) -> Bool {
		let lowercased = value.lowercased()
		let supportedPrefixes = ["inset(", "circle(", "ellipse(", "polygon(", "path(", "rect(", "xywh("]
		guard supportedPrefixes.contains(where: { lowercased.hasPrefix($0) }), value.hasSuffix(")") else {
			return false
		}
		return parenthesesAreBalanced(value)
	}

	private func parenthesesAreBalanced(_ value: String) -> Bool {
		var depth = 0
		for character in value {
			if character == "(" {
				depth += 1
			} else if character == ")" {
				depth -= 1
				if depth < 0 { return false }
			}
		}
		return depth == 0
	}

	private func isWhitespace(_ character: Character) -> Bool {
		character.unicodeScalars.allSatisfy { CharacterSet.whitespacesAndNewlines.contains($0) }
	}

	private func parseSVGRoot(_ attributes: [String: String]) {
		rootID = attributes["id"]
		setCurrentParsedElementID(rootID)
		if let vb = attributes["viewBox"], let parsedViewBox = parseViewBox(vb) {
			viewBox = parsedViewBox
		}
		rootPreserveAspectRatio = parsePreserveAspectRatio(attributes["preserveAspectRatio"])
		let viewportContext = currentViewportContext
		rootWidth = parseSVGSize(attributes["width"], percentageBasis: .horizontal, context: viewportContext)
		rootHeight = parseSVGSize(attributes["height"], percentageBasis: .vertical, context: viewportContext)
		rootLanguage = currentLanguage
		rootPaintAttributes = parsePaintAttributes(attributes)
		rootUnknownAttributes = parseUnknownAttributes(attributes, known: ["x", "y", "viewBox", "preserveAspectRatio", "width", "height"])
		pushViewportContext(width: rootWidth ?? viewportContext.viewportWidth, height: rootHeight ?? viewportContext.viewportHeight, base: viewportContext)
	}

	private func parsePreserveAspectRatio(_ value: String?) -> SVGPreserveAspectRatio {
		parseOptionalPreserveAspectRatio(value) ?? .default
	}

	private func parseOptionalPreserveAspectRatio(_ value: String?) -> SVGPreserveAspectRatio? {
		guard let value else { return nil }
		let tokens = value.split(whereSeparator: { $0.isWhitespace }).map(String.init)
		guard tokens.count == 1 || tokens.count == 2 else { return nil }
		guard let align = parsePreserveAspectRatioAlign(tokens[0]) else { return nil }
		if align == .none {
			return SVGPreserveAspectRatio(align: .none, meetOrSlice: nil)
		}
		if tokens.count == 2 {
			guard let meetOrSlice = parseMeetOrSlice(tokens[1]) else { return nil }
			return SVGPreserveAspectRatio(align: align, meetOrSlice: meetOrSlice)
		}
		return SVGPreserveAspectRatio(align: align, meetOrSlice: .meet)
	}

	private func parsePreserveAspectRatioAlign(_ value: String) -> SVGPreserveAspectRatioAlign? {
		switch value {
		case "none": SVGPreserveAspectRatioAlign.none
		case "xMinYMin": .xMinYMin
		case "xMidYMin": .xMidYMin
		case "xMaxYMin": .xMaxYMin
		case "xMinYMid": .xMinYMid
		case "xMidYMid": .xMidYMid
		case "xMaxYMid": .xMaxYMid
		case "xMinYMax": .xMinYMax
		case "xMidYMax": .xMidYMax
		case "xMaxYMax": .xMaxYMax
		default: nil
		}
	}

	private func parseMeetOrSlice(_ value: String) -> SVGMeetOrSlice? {
		switch value {
		case "meet": .meet
		case "slice": .slice
		default: nil
		}
	}

	private func parseZoomAndPan(_ value: String?) -> SVGZoomAndPan? {
		switch value {
		case "disable": .disable
		case "magnify": .magnify
		default: nil
		}
	}

	private func parseViewBox(_ value: String) -> Rect? {
		let parts = SVGListParser.parse(value, itemParser: parseNumber) ?? []
		guard parts.count == 4 else { return nil }
		return Rect(x: parts[0], y: parts[1], width: parts[2], height: parts[3])
	}

	private var currentViewportContext: SVGLengthContext {
		viewportContextStack.last ?? .default
	}

	private func parseSVGPosition(_ value: String?, percentageBasis: SVGLengthPercentageBasis, context: SVGLengthContext) -> Double {
		guard let value, let length = parseDimension(value, context: context, percentageBasis: percentageBasis) else { return 0 }
		return length
	}

	private func parseSVGSize(_ value: String?, percentageBasis: SVGLengthPercentageBasis, context: SVGLengthContext) -> Double {
		guard let value else {
			return percentageBasis.referenceDistance(in: context)
		}
		if value.trimmingCharacters(in: .whitespacesAndNewlines) == "auto" {
			return percentageBasis.referenceDistance(in: context)
		}
		return parseDimension(value, context: context, percentageBasis: percentageBasis) ?? percentageBasis.referenceDistance(in: context)
	}

	private func parseUseSize(_ value: String?, percentageBasis: SVGLengthPercentageBasis, context: SVGLengthContext) -> Double? {
		guard let value else { return nil }
		if value.trimmingCharacters(in: .whitespacesAndNewlines) == "auto" {
			return nil
		}
		guard let size = parseDimension(value, context: context, percentageBasis: percentageBasis), size >= 0 else {
			return nil
		}
		return size
	}

	private func parseDimension(_ value: String, context: SVGLengthContext = .default, percentageBasis: SVGLengthPercentageBasis = .normalizedDiagonal) -> Double? {
		SVGLengthParser.parse(value, context: context, percentageBasis: percentageBasis)
	}

	private func pushViewportContext(width: Double, height: Double, base: SVGLengthContext) {
		viewportContextStack.append(SVGLengthContext(fontSize: base.fontSize, rootFontSize: base.rootFontSize, viewportWidth: width, viewportHeight: height, xHeight: base.xHeight, zeroAdvance: base.zeroAdvance, isUprightText: base.isUprightText))
	}

	private func popViewportContext() {
		if viewportContextStack.count > 1 {
			viewportContextStack.removeLast()
		}
	}

	private func resolveID(_ explicit: String?, elementName: String) -> String {
		if let explicit { return explicit }
		let count = (elementCounters[elementName] ?? 0) + 1
		elementCounters[elementName] = count
		return "\(elementName) \(count)"
	}

	private func parsePaint(_ value: String) -> SVGPaint? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed == "none" { return SVGPaint.none }
		if trimmed == "currentColor" { return .currentColor }
		if trimmed == "context-fill" { return .contextFill }
		if trimmed == "context-stroke" { return .contextStroke }
		if let paint = parsePaintServerReference(trimmed) { return paint }
		if let color = parseColor(trimmed) { return .color(color) }
		return nil
	}

	private func parsePaintServerReference(_ value: String) -> SVGPaint? {
		guard let parsed = SVGURLParser.parseFunctionalPrefix(value), let id = parsed.reference.localFragmentID else { return nil }
		let fallbackText = parsed.remainder
		guard !fallbackText.isEmpty else { return .url(id) }
		guard let fallback = parsePaintFallback(fallbackText) else { return nil }
		return .urlWithFallback(id, fallback)
	}

	private func parsePaintFallback(_ value: String) -> SVGPaint? {
		if value == "none" { return SVGPaint.none }
		if value == "currentColor" { return .currentColor }
		if let color = parseColor(value) { return .color(color) }
		return nil
	}

	private func parseColor(_ value: String) -> Color? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		let lower = trimmed.lowercased()
		if trimmed.hasPrefix("#") { return hexColor(trimmed) }
		if lower.hasPrefix("rgba(") { return rgbColor(trimmed, allowsAlpha: true) }
		if lower.hasPrefix("rgb(") { return rgbColor(trimmed, allowsAlpha: false) }
		if lower.hasPrefix("hsla(") { return hslColor(trimmed, allowsAlpha: true) }
		if lower.hasPrefix("hsl(") { return hslColor(trimmed, allowsAlpha: false) }
		if lower == "transparent" { return .clear }
		return namedColor(lower)
	}

	private func hexColor(_ hex: String) -> Color? {
		var str = hex.trimmingCharacters(in: .whitespaces)
		if str.hasPrefix("#") { str.removeFirst() }
		if str.count == 3 { str = str.map { "\($0)\($0)" }.joined() }
		guard str.count == 6, let value = UInt64(str, radix: 16) else { return nil }
		return Color(Double((value >> 16) & 0xFF) / 255, Double((value >> 8) & 0xFF) / 255, Double(value & 0xFF) / 255)
	}

	private func rgbColor(_ value: String, allowsAlpha: Bool) -> Color? {
		guard let parts = functionalColorParts(value) else { return nil }
		guard parts.count == (allowsAlpha ? 4 : 3) else { return nil }
		let components = parts.prefix(3)
		let usesPercentages = components.map { $0.hasSuffix("%") }
		guard usesPercentages.allSatisfy({ $0 == usesPercentages[0] }) else { return nil }
		guard let red = rgbComponent(String(parts[0])),
			let green = rgbComponent(String(parts[1])),
			let blue = rgbComponent(String(parts[2]))
		else { return nil }
		let alpha = allowsAlpha ? alphaComponent(String(parts[3])) : 1
		guard let alpha else { return nil }
		return Color(red, green, blue, alpha)
	}

	private func hslColor(_ value: String, allowsAlpha: Bool) -> Color? {
		guard let parts = functionalColorParts(value) else { return nil }
		guard parts.count == (allowsAlpha ? 4 : 3) else { return nil }
		guard let hue = parseNumber(String(parts[0])),
			let saturation = percentComponent(String(parts[1])),
			let lightness = percentComponent(String(parts[2]))
		else { return nil }
		let alpha = allowsAlpha ? alphaComponent(String(parts[3])) : 1
		guard let alpha else { return nil }
		return hslToRGB(hue: hue, saturation: saturation, lightness: lightness, alpha: alpha)
	}

	private func functionalColorParts(_ value: String) -> [String]? {
		guard let open = value.firstIndex(of: "("), value.hasSuffix(")") else { return nil }
		let inner = value[value.index(after: open)..<value.index(before: value.endIndex)]
		let parts = inner.split(separator: ",", omittingEmptySubsequences: false).map {
			String($0).trimmingCharacters(in: .whitespacesAndNewlines)
		}
		return parts.contains("") ? nil : parts
	}

	private func rgbComponent(_ value: String) -> Double? {
		if value.hasSuffix("%") {
			return percentComponent(value)
		}
		guard let number = parseNumber(value) else { return nil }
		return min(max(number, 0), 255) / 255
	}

	private func percentComponent(_ value: String) -> Double? {
		guard value.hasSuffix("%") else { return nil }
		let numberText = String(value.dropLast())
		guard let number = parseNumber(numberText) else { return nil }
		return min(max(number / 100, 0), 1)
	}

	private func alphaComponent(_ value: String) -> Double? {
		guard let number = parseNumber(value) else { return nil }
		return min(max(number, 0), 1)
	}

	private func hslToRGB(hue: Double, saturation: Double, lightness: Double, alpha: Double) -> Color {
		let normalizedHue = ((hue.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
		let chroma = (1 - abs((2 * lightness) - 1)) * saturation
		let huePrime = normalizedHue / 60
		let x = chroma * (1 - abs(huePrime.truncatingRemainder(dividingBy: 2) - 1))
		let red: Double
		let green: Double
		let blue: Double
		switch huePrime {
		case 0..<1:
			(red, green, blue) = (chroma, x, 0)
		case 1..<2:
			(red, green, blue) = (x, chroma, 0)
		case 2..<3:
			(red, green, blue) = (0, chroma, x)
		case 3..<4:
			(red, green, blue) = (0, x, chroma)
		case 4..<5:
			(red, green, blue) = (x, 0, chroma)
		default:
			(red, green, blue) = (chroma, 0, x)
		}
		let match = lightness - chroma / 2
		return Color(red + match, green + match, blue + match, alpha)
	}

	private func namedColor(_ value: String) -> Color? {
		Self.namedColors[value]
	}

	private func parseLineCap(_ value: String) -> LineCap? {
		switch value.trimmingCharacters(in: .whitespacesAndNewlines) {
		case "butt":
			return .butt
		case "round":
			return .round
		case "square":
			return .square
		default:
			return nil
		}
	}

	private func parseLineJoin(_ value: String) -> LineJoin? {
		switch value.trimmingCharacters(in: .whitespacesAndNewlines) {
		case "miter":
			return .miter
		case "round":
			return .round
		case "bevel":
			return .bevel
		default:
			return nil
		}
	}

	private func parseTransform(_ value: String) -> Transform {
		var transform = Transform.identity
		guard let regex = try? NSRegularExpression(pattern: #"(\w+)\(([^)]+)\)"#) else { return transform }
		let nsValue = value as NSString
		for match in regex.matches(in: value, range: NSRange(location: 0, length: nsValue.length)) {
			let function = nsValue.substring(with: match.range(at: 1))
			guard let argTexts = SVGListParser.parse(nsValue.substring(with: match.range(at: 2))) else { continue }
			let args = argTexts.compactMap { parseNumber($0) }
			switch function {
			case "translate" where args.count >= 1:
				transform = transform.translatedBy(x: args[0], y: args.count >= 2 ? args[1] : 0)
			case "scale" where args.count >= 1:
				transform = transform.scaledBy(x: args[0], y: args.count >= 2 ? args[1] : args[0])
			case "rotate" where !argTexts.isEmpty:
				guard let angle = SVGAngleParser.parse(argTexts[0]) else { break }
				if args.count >= 3 {
					transform = transform.rotated(by: angle, center: Point(args[1], args[2]))
				} else {
					transform = transform.rotated(by: angle)
				}
			case "skewX" where !argTexts.isEmpty:
				guard let angle = SVGAngleParser.parse(argTexts[0]) else { break }
				transform = transform.skewedX(by: angle)
			case "skewY" where !argTexts.isEmpty:
				guard let angle = SVGAngleParser.parse(argTexts[0]) else { break }
				transform = transform.skewedY(by: angle)
			case "matrix" where args.count == 6:
				transform = transform.concatenating(Transform(a: args[0], b: args[1], c: args[2], d: args[3], tx: args[4], ty: args[5]))
			default:
				break
			}
		}
		return transform
	}

	private func parsePoints(_ value: String) -> [Point] {
		let numbers = SVGListParser.parse(value, itemParser: parseNumber) ?? []
		var points: [Point] = []
		var index = 0
		while index + 1 < numbers.count {
			points.append(Point(numbers[index], numbers[index + 1]))
			index += 2
		}
		return points
	}

	private func double(_ value: String?) -> Double {
		guard let value, let number = parseNumber(value) else { return 0 }
		return number
	}

	private func dimension(_ value: String?, percentageBasis: SVGLengthPercentageBasis) -> Double {
		guard let value, let length = parseDimension(value, context: currentViewportContext, percentageBasis: percentageBasis) else { return 0 }
		return length
	}

	private func nonnegativeDimension(_ value: String?, percentageBasis: SVGLengthPercentageBasis) -> Double {
		let length = dimension(value, percentageBasis: percentageBasis)
		return length < 0 ? 0 : length
	}

	private func nonnegativeOptionalDimension(_ value: String?, percentageBasis: SVGLengthPercentageBasis) -> Double? {
		guard let value else { return nil }
		if value.trimmingCharacters(in: .whitespacesAndNewlines) == "auto" {
			return nil
		}
		guard let length = parseDimension(value, context: currentViewportContext, percentageBasis: percentageBasis), length >= 0 else { return nil }
		return length
	}

	private func parseNumber(_ value: String) -> Double? {
		SVGNumberParser.parse(value)
	}

	private func selectTitle(_ titles: [SVGTitleData]) -> SVGTitleData? {
		guard !titles.isEmpty else { return nil }
		for preference in languagePreferences {
			if let exactMatch = titles.first(where: { $0.language?.lowercased() == preference }) {
				return exactMatch
			}
			if let prefixMatch = titles.first(where: { descriptiveLanguageMatches($0.language, preference: preference) }) {
				return prefixMatch
			}
		}
		if let emptyLanguageMatch = titles.first(where: { $0.language == "" }) {
			return emptyLanguageMatch
		}
		return titles.first
	}

	private func selectDescription(_ descriptions: [SVGDescriptionData]) -> SVGDescriptionData? {
		guard !descriptions.isEmpty else { return nil }
		for preference in languagePreferences {
			if let exactMatch = descriptions.first(where: { $0.language?.lowercased() == preference }) {
				return exactMatch
			}
			if let prefixMatch = descriptions.first(where: { descriptiveLanguageMatches($0.language, preference: preference) }) {
				return prefixMatch
			}
		}
		if let emptyLanguageMatch = descriptions.first(where: { $0.language == "" }) {
			return emptyLanguageMatch
		}
		return descriptions.first
	}

	private func descriptiveLanguageMatches(_ language: String?, preference: String) -> Bool {
		guard let language = language?.lowercased(), !language.isEmpty else { return false }
		return language.hasPrefix("\(preference)-") || preference.hasPrefix("\(language)-")
	}
}

private struct SVGNamespaceContext {
	var bindings: [String: String]

	static let empty = SVGNamespaceContext(bindings: [:])

	mutating func applyDeclarations(from attributes: [String: String]) {
		for (name, value) in attributes {
			if name == "xmlns" {
				setNamespace(value, for: "")
			} else if name.hasPrefix("xmlns:") {
				let prefix = String(name.dropFirst("xmlns:".count))
				setNamespace(value, for: prefix)
			}
		}
	}

	func expandedElementName(for qualifiedName: String) -> SVGExpandedName {
		let name = splitQualifiedName(qualifiedName)
		return SVGExpandedName(localName: name.localName, namespaceURI: bindings[name.prefix ?? ""])
	}

	private mutating func setNamespace(_ namespaceURI: String, for prefix: String) {
		if namespaceURI.isEmpty {
			bindings.removeValue(forKey: prefix)
		} else {
			bindings[prefix] = namespaceURI
		}
	}
}

private struct SVGExpandedName {
	var localName: String
	var namespaceURI: String?
}

private struct SVGParsedElement {
	var localName: String
	var namespaceURI: String?
	var role: SVGParsedElementRole = .normal
	var id: String?

	var isSVGElement: Bool {
		guard let namespaceURI else { return true }
		return namespaceURI == SVGParser.svgNamespaceURI
	}

	func hasSVGAncestor<S: Sequence>(in ancestors: S) -> Bool where S.Element == SVGParsedElement {
		ancestors.contains { $0.isSVGElement }
	}

	func hasSkippedAncestor<S: Sequence>(in ancestors: S) -> Bool where S.Element == SVGParsedElement {
		ancestors.contains { $0.role == .skipped }
	}
}

private enum SVGParsedElementRole {
	case normal
	case svgRoot
	case svgContainer
	case switchContainer
	case linkContainer
	case title
	case titleContent
	case description
	case descriptionContent
	case metadata
	case metadataContent
	case unknownContainer
	case skipped
}

private enum SVGXMLSpaceMode {
	case `default`
	case preserve
}

private func splitQualifiedName(_ qualifiedName: String) -> (prefix: String?, localName: String) {
	guard let separator = qualifiedName.firstIndex(of: ":") else {
		return (nil, qualifiedName)
	}
	return (String(qualifiedName[..<separator]), String(qualifiedName[qualifiedName.index(after: separator)...]))
}

private extension String {
	var isNamespaceDeclaration: Bool {
		self == "xmlns" || hasPrefix("xmlns:")
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
		case .switch(let data): data.id
		case .link(let data): data.id
		case .svg(let data): data.id
		case .unknown(let data): data.id
		case .use(let data): data.id
		case .image(let data): data.id
		case .text(let data): data.id
		}
	}
}

/// Mutable builder used during SVG parsing to accumulate container children.
private final class SVGElementBuilder {
	enum Kind {
		case group
		case `switch`
		case link(href: String?, target: String, download: String?, ping: String?, rel: String?, hreflang: String?, type: String?, referrerPolicy: String?, xlinkTitle: String?)
		case svg(x: Double, y: Double, width: Double, height: Double, viewBox: Rect?, preserveAspectRatio: SVGPreserveAspectRatio)
		case symbol(x: Double, y: Double, width: Double, height: Double, viewBox: Rect?, preserveAspectRatio: SVGPreserveAspectRatio, refX: String?, refY: String?)
		case unknown(name: String, namespaceURI: String?)
	}

	let kind: Kind
	let id: String
	let attributes: SVGPaintAttributes
	let language: String?
	let unknownAttributes: [String: String]
	var children: [SVGElement] = []
	var switchHasSelectedChild = false

	var isSymbol: Bool {
		if case .symbol = kind {
			return true
		}
		return false
	}

	var isSwitch: Bool {
		if case .switch = kind {
			return true
		}
		return false
	}

	var isLink: Bool {
		if case .link = kind {
			return true
		}
		return false
	}

	init(kind: Kind, id: String, attributes: SVGPaintAttributes, language: String?, unknownAttributes: [String: String]) {
		self.kind = kind
		self.id = id
		self.attributes = attributes
		self.language = language
		self.unknownAttributes = unknownAttributes
	}

	func buildElement() -> SVGElement {
		switch kind {
		case .group:
			.group(SVGGroupData(id: id, attributes: attributes, children: children, language: language, unknownAttributes: unknownAttributes))
		case .switch:
			.switch(SVGSwitchData(id: id, attributes: attributes, children: children, language: language, unknownAttributes: unknownAttributes))
		case .link(let href, let target, let download, let ping, let rel, let hreflang, let type, let referrerPolicy, let xlinkTitle):
			.link(SVGLinkData(id: id, href: href, target: target, download: download, ping: ping, rel: rel, hreflang: hreflang, type: type, referrerPolicy: referrerPolicy, xlinkTitle: xlinkTitle, attributes: attributes, children: children, language: language, unknownAttributes: unknownAttributes))
		case .svg(let x, let y, let width, let height, let viewBox, let preserveAspectRatio):
			.svg(SVGViewportData(id: id, x: x, y: y, width: width, height: height, viewBox: viewBox, preserveAspectRatio: preserveAspectRatio, attributes: attributes, children: children, language: language, unknownAttributes: unknownAttributes))
		case .symbol:
			.unknown(SVGUnknownElementData(id: id, name: "symbol", namespaceURI: SVGParser.svgNamespaceURI, attributes: attributes, children: children, language: language, unknownAttributes: unknownAttributes))
		case .unknown(let name, let namespaceURI):
			.unknown(SVGUnknownElementData(id: id, name: name, namespaceURI: namespaceURI, attributes: attributes, children: children, language: language, unknownAttributes: unknownAttributes))
		}
	}

	func buildSymbolData() -> SVGSymbolData {
		switch kind {
		case .symbol(let x, let y, let width, let height, let viewBox, let preserveAspectRatio, let refX, let refY):
			SVGSymbolData(id: id, x: x, y: y, width: width, height: height, viewBox: viewBox, preserveAspectRatio: preserveAspectRatio, refX: refX, refY: refY, attributes: attributes, children: children, language: language, unknownAttributes: unknownAttributes)
		case .group, .switch, .link, .svg, .unknown:
			SVGSymbolData(id: id, x: 0, y: 0, width: 0, height: 0, viewBox: nil, attributes: attributes, children: children, language: language, unknownAttributes: unknownAttributes)
		}
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
	let language: String?
	let unknownAttributes: [String: String]
	var spans: [SVGTextSpan] = []

	init(id: String, x: Double, y: Double, fontSize: Double, fontFamily: String, fontWeight: String, textAnchor: SVGTextAnchor, attributes: SVGPaintAttributes, language: String?, unknownAttributes: [String: String]) {
		self.id = id
		self.x = x
		self.y = y
		self.fontSize = fontSize
		self.fontFamily = fontFamily
		self.fontWeight = fontWeight
		self.textAnchor = textAnchor
		self.attributes = attributes
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Mutable builder used during SVG title parsing.
private final class SVGTitleBuilder {
	let id: String
	let parentID: String?
	let isRootTitle: Bool
	let language: String?
	let unknownAttributes: [String: String]
	let xmlSpaceMode: SVGXMLSpaceMode

	init(id: String, parentID: String?, isRootTitle: Bool, language: String?, unknownAttributes: [String: String], xmlSpaceMode: SVGXMLSpaceMode) {
		self.id = id
		self.parentID = parentID
		self.isRootTitle = isRootTitle
		self.language = language
		self.unknownAttributes = unknownAttributes
		self.xmlSpaceMode = xmlSpaceMode
	}
}

/// Mutable builder used during SVG desc parsing.
private final class SVGDescriptionBuilder {
	let id: String
	let parentID: String?
	let isRootDescription: Bool
	let language: String?
	let unknownAttributes: [String: String]
	let xmlSpaceMode: SVGXMLSpaceMode

	init(id: String, parentID: String?, isRootDescription: Bool, language: String?, unknownAttributes: [String: String], xmlSpaceMode: SVGXMLSpaceMode) {
		self.id = id
		self.parentID = parentID
		self.isRootDescription = isRootDescription
		self.language = language
		self.unknownAttributes = unknownAttributes
		self.xmlSpaceMode = xmlSpaceMode
	}
}

/// Mutable builder used during SVG metadata parsing.
private final class SVGMetadataBuilder {
	let id: String
	let parentID: String?
	let isRootMetadata: Bool
	let language: String?
	let unknownAttributes: [String: String]
	var children: [SVGMetadataNode] = []
	var elementStack: [SVGMetadataElementBuilder] = []

	init(id: String, parentID: String?, isRootMetadata: Bool, language: String?, unknownAttributes: [String: String]) {
		self.id = id
		self.parentID = parentID
		self.isRootMetadata = isRootMetadata
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Mutable builder used during metadata XML subtree parsing.
private final class SVGMetadataElementBuilder {
	let name: String
	let localName: String
	let namespaceURI: String?
	let attributes: [String: String]
	var children: [SVGMetadataNode] = []

	init(name: String, localName: String, namespaceURI: String?, attributes: [String: String]) {
		self.name = name
		self.localName = localName
		self.namespaceURI = namespaceURI
		self.attributes = attributes
	}

	func build() -> SVGMetadataElementData {
		SVGMetadataElementData(name: name, localName: localName, namespaceURI: namespaceURI, attributes: attributes, children: children)
	}
}

private struct SVGGradientStopStyle {
	var stopColor: SVGGradientStopColor = .color(.black)
	var currentColor: Color = .black
	var opacity: Double = 1
}
