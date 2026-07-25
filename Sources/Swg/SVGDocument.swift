import Foundation

/// A parsed SVG document with a view box, element tree, and definitions registry.
public struct SVGDocument: Equatable, Sendable {
	public var id: String?
	public var viewBox: Rect
	public var preserveAspectRatio: SVGPreserveAspectRatio
	public var elements: [SVGElement]
	public var defs: SVGDefs
	public var language: String?
	public var unknownAttributes: [String: String]
	public var rootTitles: [SVGTitleData]
	public var elementTitles: [String: [SVGTitleData]]
	public var selectedTitle: SVGTitleData?
	public var selectedElementTitles: [String: SVGTitleData]
	public var rootDescriptions: [SVGDescriptionData]
	public var elementDescriptions: [String: [SVGDescriptionData]]
	public var selectedDescription: SVGDescriptionData?
	public var selectedElementDescriptions: [String: SVGDescriptionData]

	public init(
		id: String? = nil,
		viewBox: Rect,
		preserveAspectRatio: SVGPreserveAspectRatio = .default,
		elements: [SVGElement],
		defs: SVGDefs = SVGDefs(),
		language: String? = nil,
		unknownAttributes: [String: String] = [:],
		rootTitles: [SVGTitleData] = [],
		elementTitles: [String: [SVGTitleData]] = [:],
		selectedTitle: SVGTitleData? = nil,
		selectedElementTitles: [String: SVGTitleData] = [:],
		rootDescriptions: [SVGDescriptionData] = [],
		elementDescriptions: [String: [SVGDescriptionData]] = [:],
		selectedDescription: SVGDescriptionData? = nil,
		selectedElementDescriptions: [String: SVGDescriptionData] = [:]
	) {
		self.id = id
		self.viewBox = viewBox
		self.preserveAspectRatio = preserveAspectRatio
		self.elements = elements
		self.defs = defs
		self.language = language
		self.unknownAttributes = unknownAttributes
		self.rootTitles = rootTitles
		self.elementTitles = elementTitles
		self.selectedTitle = selectedTitle
		self.selectedElementTitles = selectedElementTitles
		self.rootDescriptions = rootDescriptions
		self.elementDescriptions = elementDescriptions
		self.selectedDescription = selectedDescription
		self.selectedElementDescriptions = selectedElementDescriptions
	}

	public var elementIDs: [String] {
		elements.flatMap { $0.collectIDs() }
	}
}

/// Plain text metadata from an SVG `<title>` descriptive element.
public struct SVGTitleData: Equatable, Sendable {
	public let id: String
	public let text: String
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, text: String, language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.text = text
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Plain text metadata from an SVG `<desc>` descriptive element.
public struct SVGDescriptionData: Equatable, Sendable {
	public let id: String
	public let text: String
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, text: String, language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.text = text
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// A registry of reusable SVG definitions such as gradients, clip paths, filters, and masks.
public struct SVGDefs: Equatable, Sendable {
	public var linearGradients: [String: SVGLinearGradientDef]
	public var radialGradients: [String: SVGRadialGradientDef]
	public var symbols: [String: SVGSymbolData]
	public var views: [String: SVGViewData]
	public var clipPaths: [String: [SVGElement]]
	public var filters: [String: SVGFilterDef]
	public var masks: [String: SVGMaskDef]
	public var reusableElements: [String: [SVGElement]]

	public init(
		linearGradients: [String: SVGLinearGradientDef] = [:],
		radialGradients: [String: SVGRadialGradientDef] = [:],
		symbols: [String: SVGSymbolData] = [:],
		views: [String: SVGViewData] = [:],
		clipPaths: [String: [SVGElement]] = [:],
		filters: [String: SVGFilterDef] = [:],
		masks: [String: SVGMaskDef] = [:],
		reusableElements: [String: [SVGElement]] = [:]
	) {
		self.linearGradients = linearGradients
		self.radialGradients = radialGradients
		self.symbols = symbols
		self.views = views
		self.clipPaths = clipPaths
		self.filters = filters
		self.masks = masks
		self.reusableElements = reusableElements
	}
}

/// A single SVG shape, group, unknown container, text, image, or use element.
public indirect enum SVGElement: Equatable, Sendable {
	case path(SVGPathData)
	case rect(SVGRectData)
	case circle(SVGCircleData)
	case ellipse(SVGEllipseData)
	case line(SVGLineData)
	case polygon(SVGPolygonData)
	case polyline(SVGPolygonData)
	case group(SVGGroupData)
	case `switch`(SVGSwitchData)
	case link(SVGLinkData)
	case svg(SVGViewportData)
	case unknown(SVGUnknownElementData)
	case use(SVGUseData)
	case image(SVGImageData)
	case text(SVGTextData)

	func collectIDs() -> [String] {
		switch self {
		case .path(let data): [data.id]
		case .rect(let data): [data.id]
		case .circle(let data): [data.id]
		case .ellipse(let data): [data.id]
		case .line(let data): [data.id]
		case .polygon(let data): [data.id]
		case .polyline(let data): [data.id]
		case .group(let data): [data.id] + data.children.flatMap { $0.collectIDs() }
		case .switch(let data): [data.id] + data.children.flatMap { $0.collectIDs() }
		case .link(let data): [data.id] + data.children.flatMap { $0.collectIDs() }
		case .svg(let data): [data.id] + data.children.flatMap { $0.collectIDs() }
		case .unknown(let data): [data.id] + data.children.flatMap { $0.collectIDs() }
		case .use(let data): [data.id]
		case .image(let data): [data.id]
		case .text(let data): [data.id]
		}
	}
}

/// Data for an SVG `<path>` element.
public struct SVGPathData: Equatable, Sendable {
	public let id: String
	public let d: String
	public let attributes: SVGPaintAttributes
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, d: String, attributes: SVGPaintAttributes, language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.d = d
		self.attributes = attributes
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data for an SVG `<rect>` element.
public struct SVGRectData: Equatable, Sendable {
	public let id: String
	public let x: Double
	public let y: Double
	public let width: Double
	public let height: Double
	public let rx: Double
	public let ry: Double
	public let attributes: SVGPaintAttributes
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, x: Double, y: Double, width: Double, height: Double, rx: Double, ry: Double, attributes: SVGPaintAttributes, language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.x = x
		self.y = y
		self.width = width
		self.height = height
		self.rx = rx
		self.ry = ry
		self.attributes = attributes
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data for an SVG `<circle>` element.
public struct SVGCircleData: Equatable, Sendable {
	public let id: String
	public let cx: Double
	public let cy: Double
	public let r: Double
	public let attributes: SVGPaintAttributes
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, cx: Double, cy: Double, r: Double, attributes: SVGPaintAttributes, language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.cx = cx
		self.cy = cy
		self.r = r
		self.attributes = attributes
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data for an SVG `<ellipse>` element.
public struct SVGEllipseData: Equatable, Sendable {
	public let id: String
	public let cx: Double
	public let cy: Double
	public let rx: Double
	public let ry: Double
	public let attributes: SVGPaintAttributes
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, cx: Double, cy: Double, rx: Double, ry: Double, attributes: SVGPaintAttributes, language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.cx = cx
		self.cy = cy
		self.rx = rx
		self.ry = ry
		self.attributes = attributes
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data for an SVG `<line>` element.
public struct SVGLineData: Equatable, Sendable {
	public let id: String
	public let x1: Double
	public let y1: Double
	public let x2: Double
	public let y2: Double
	public let attributes: SVGPaintAttributes
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, x1: Double, y1: Double, x2: Double, y2: Double, attributes: SVGPaintAttributes, language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.x1 = x1
		self.y1 = y1
		self.x2 = x2
		self.y2 = y2
		self.attributes = attributes
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data for an SVG `<polygon>` or `<polyline>` element.
public struct SVGPolygonData: Equatable, Sendable {
	public let id: String
	public let points: [Point]
	public let attributes: SVGPaintAttributes
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, points: [Point], attributes: SVGPaintAttributes, language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.points = points
		self.attributes = attributes
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data for an SVG `<g>` group element with child elements.
public struct SVGGroupData: Equatable, Sendable {
	public let id: String
	public let attributes: SVGPaintAttributes
	public let children: [SVGElement]
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, attributes: SVGPaintAttributes, children: [SVGElement], language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.attributes = attributes
		self.children = children
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data for an SVG `<switch>` element after conditional child selection.
public struct SVGSwitchData: Equatable, Sendable {
	public let id: String
	public let attributes: SVGPaintAttributes
	public let children: [SVGElement]
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, attributes: SVGPaintAttributes, children: [SVGElement], language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.attributes = attributes
		self.children = children
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data for an SVG `<a>` hyperlink container element.
public struct SVGLinkData: Equatable, Sendable {
	public let id: String
	public let href: String?
	public let target: String
	public let download: String?
	public let ping: String?
	public let rel: String?
	public let hreflang: String?
	public let type: String?
	public let referrerPolicy: String?
	public let xlinkTitle: String?
	public let attributes: SVGPaintAttributes
	public let children: [SVGElement]
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, href: String? = nil, target: String = "_self", download: String? = nil, ping: String? = nil, rel: String? = nil, hreflang: String? = nil, type: String? = nil, referrerPolicy: String? = nil, xlinkTitle: String? = nil, attributes: SVGPaintAttributes, children: [SVGElement], language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.href = href
		self.target = target
		self.download = download
		self.ping = ping
		self.rel = rel
		self.hreflang = hreflang
		self.type = type
		self.referrerPolicy = referrerPolicy
		self.xlinkTitle = xlinkTitle
		self.attributes = attributes
		self.children = children
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data for an embedded SVG `<svg>` element that establishes a nested viewport.
public struct SVGViewportData: Equatable, Sendable {
	public let id: String
	public let x: Double
	public let y: Double
	public let width: Double
	public let height: Double
	public let viewBox: Rect?
	public let preserveAspectRatio: SVGPreserveAspectRatio
	public let attributes: SVGPaintAttributes
	public let children: [SVGElement]
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, x: Double, y: Double, width: Double, height: Double, viewBox: Rect?, preserveAspectRatio: SVGPreserveAspectRatio = .default, attributes: SVGPaintAttributes, children: [SVGElement], language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.x = x
		self.y = y
		self.width = width
		self.height = height
		self.viewBox = viewBox
		self.preserveAspectRatio = preserveAspectRatio
		self.attributes = attributes
		self.children = children
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data for an SVG `<symbol>` template that can be instantiated by `<use>`.
public struct SVGSymbolData: Equatable, Sendable {
	public let id: String
	public let x: Double
	public let y: Double
	public let width: Double
	public let height: Double
	public let viewBox: Rect?
	public let preserveAspectRatio: SVGPreserveAspectRatio
	public let refX: String?
	public let refY: String?
	public let attributes: SVGPaintAttributes
	public let children: [SVGElement]
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, x: Double, y: Double, width: Double, height: Double, viewBox: Rect?, preserveAspectRatio: SVGPreserveAspectRatio = .default, refX: String? = nil, refY: String? = nil, attributes: SVGPaintAttributes, children: [SVGElement], language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.x = x
		self.y = y
		self.width = width
		self.height = height
		self.viewBox = viewBox
		self.preserveAspectRatio = preserveAspectRatio
		self.refX = refX
		self.refY = refY
		self.attributes = attributes
		self.children = children
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data for an SVG `<view>` element that defines a predefined view.
public struct SVGViewData: Equatable, Sendable {
	public let id: String
	public let viewBox: Rect?
	public let preserveAspectRatio: SVGPreserveAspectRatio?
	public let zoomAndPan: SVGZoomAndPan?
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, viewBox: Rect? = nil, preserveAspectRatio: SVGPreserveAspectRatio? = nil, zoomAndPan: SVGZoomAndPan? = nil, language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.viewBox = viewBox
		self.preserveAspectRatio = preserveAspectRatio
		self.zoomAndPan = zoomAndPan
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// How an SVG `viewBox` is aligned within its viewport.
public struct SVGPreserveAspectRatio: Equatable, Sendable {
	public var align: SVGPreserveAspectRatioAlign
	public var meetOrSlice: SVGMeetOrSlice?

	public static let `default` = SVGPreserveAspectRatio(align: .xMidYMid, meetOrSlice: .meet)

	public init(align: SVGPreserveAspectRatioAlign = .xMidYMid, meetOrSlice: SVGMeetOrSlice? = .meet) {
		self.align = align
		self.meetOrSlice = align == .none ? nil : meetOrSlice ?? .meet
	}
}

/// Alignment keywords supported by SVG `preserveAspectRatio`.
public enum SVGPreserveAspectRatioAlign: Equatable, Hashable, Sendable {
	case none
	case xMinYMin
	case xMidYMin
	case xMaxYMin
	case xMinYMid
	case xMidYMid
	case xMaxYMid
	case xMinYMax
	case xMidYMax
	case xMaxYMax
}

/// Uniform scaling mode used by SVG `preserveAspectRatio`.
public enum SVGMeetOrSlice: Equatable, Hashable, Sendable {
	case meet
	case slice
}

/// Magnification and panning policy values for SVG `zoomAndPan`.
public enum SVGZoomAndPan: Equatable, Hashable, Sendable {
	case disable
	case magnify
}

/// Data for an unknown SVG element preserved as a renderable container.
public struct SVGUnknownElementData: Equatable, Sendable {
	public let id: String
	public let name: String
	public let namespaceURI: String?
	public let attributes: SVGPaintAttributes
	public let children: [SVGElement]
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, name: String, namespaceURI: String?, attributes: SVGPaintAttributes, children: [SVGElement], language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.name = name
		self.namespaceURI = namespaceURI
		self.attributes = attributes
		self.children = children
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data for an SVG `<use>` element that references a definition.
public struct SVGUseData: Equatable, Sendable {
	public let id: String
	public let href: String
	public let x: Double
	public let y: Double
	public let width: Double?
	public let height: Double?
	public let attributes: SVGPaintAttributes
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, href: String, x: Double, y: Double, width: Double? = nil, height: Double? = nil, attributes: SVGPaintAttributes, language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.href = href
		self.x = x
		self.y = y
		self.width = width
		self.height = height
		self.attributes = attributes
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data for an SVG `<image>` element.
public struct SVGImageData: Equatable, Sendable {
	public let id: String
	public let x: Double
	public let y: Double
	public let width: Double
	public let height: Double
	public let href: String
	public let attributes: SVGPaintAttributes
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, x: Double, y: Double, width: Double, height: Double, href: String, attributes: SVGPaintAttributes, language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.x = x
		self.y = y
		self.width = width
		self.height = height
		self.href = href
		self.attributes = attributes
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data for an SVG `<text>` element.
public struct SVGTextData: Equatable, Sendable {
	public let id: String
	public let x: Double
	public let y: Double
	public let fontSize: Double
	public let fontFamily: String
	public let fontWeight: String
	public let textAnchor: SVGTextAnchor
	public let attributes: SVGPaintAttributes
	public let spans: [SVGTextSpan]
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, x: Double, y: Double, fontSize: Double, fontFamily: String, fontWeight: String, textAnchor: SVGTextAnchor, attributes: SVGPaintAttributes, spans: [SVGTextSpan], language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.x = x
		self.y = y
		self.fontSize = fontSize
		self.fontFamily = fontFamily
		self.fontWeight = fontWeight
		self.textAnchor = textAnchor
		self.attributes = attributes
		self.spans = spans
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// A positioned text span within an SVG `<text>` element.
public struct SVGTextSpan: Equatable, Sendable {
	public let text: String
	public let x: Double?
	public let y: Double?
	public let dx: Double
	public let dy: Double
	public let fontSize: Double?
	public let fontWeight: String?
	public let attributes: SVGPaintAttributes?
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(text: String, x: Double?, y: Double?, dx: Double, dy: Double, fontSize: Double?, fontWeight: String?, attributes: SVGPaintAttributes?, language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.text = text
		self.x = x
		self.y = y
		self.dx = dx
		self.dy = dy
		self.fontSize = fontSize
		self.fontWeight = fontWeight
		self.attributes = attributes
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Text alignment anchor for SVG text layout.
public enum SVGTextAnchor: Sendable, Equatable, Hashable {
	case start
	case middle
	case end
}

/// A parsed gradient stop.
public struct SVGGradientStop: Equatable, Sendable {
	public let offset: Double
	public let color: Color
	public let opacity: Double

	public init(offset: Double, color: Color, opacity: Double) {
		self.offset = offset
		self.color = color
		self.opacity = opacity
	}
}

/// A parsed SVG `<linearGradient>` definition.
public struct SVGLinearGradientDef: Equatable, Sendable {
	public var id: String
	public var x1: Double
	public var y1: Double
	public var x2: Double
	public var y2: Double
	public var gradientUnits: SVGGradientUnits
	public var gradientTransform: Transform
	public var stops: [SVGGradientStop]
	public var href: String?

	public init(
		id: String,
		x1: Double = 0,
		y1: Double = 0,
		x2: Double = 1,
		y2: Double = 0,
		gradientUnits: SVGGradientUnits = .objectBoundingBox,
		gradientTransform: Transform = .identity,
		stops: [SVGGradientStop] = [],
		href: String? = nil
	) {
		self.id = id
		self.x1 = x1
		self.y1 = y1
		self.x2 = x2
		self.y2 = y2
		self.gradientUnits = gradientUnits
		self.gradientTransform = gradientTransform
		self.stops = stops
		self.href = href
	}
}

/// A parsed SVG `<radialGradient>` definition.
public struct SVGRadialGradientDef: Equatable, Sendable {
	public var id: String
	public var cx: Double
	public var cy: Double
	public var r: Double
	public var fx: Double?
	public var fy: Double?
	public var gradientUnits: SVGGradientUnits
	public var gradientTransform: Transform
	public var stops: [SVGGradientStop]
	public var href: String?

	public init(
		id: String,
		cx: Double = 0.5,
		cy: Double = 0.5,
		r: Double = 0.5,
		fx: Double? = nil,
		fy: Double? = nil,
		gradientUnits: SVGGradientUnits = .objectBoundingBox,
		gradientTransform: Transform = .identity,
		stops: [SVGGradientStop] = [],
		href: String? = nil
	) {
		self.id = id
		self.cx = cx
		self.cy = cy
		self.r = r
		self.fx = fx
		self.fy = fy
		self.gradientUnits = gradientUnits
		self.gradientTransform = gradientTransform
		self.stops = stops
		self.href = href
	}
}

/// Coordinate space for SVG gradient units.
public enum SVGGradientUnits: Sendable, Equatable, Hashable {
	case objectBoundingBox
	case userSpaceOnUse
}

/// A parsed SVG `<filter>` definition.
public struct SVGFilterDef: Equatable, Sendable {
	public var id: String
	public var primitives: [SVGFilterPrimitive]

	public init(id: String, primitives: [SVGFilterPrimitive] = []) {
		self.id = id
		self.primitives = primitives
	}
}

/// A supported SVG filter primitive.
public enum SVGFilterPrimitive: Equatable, Sendable {
	case gaussianBlur(stdDeviation: Double)
	case dropShadow(dx: Double, dy: Double, stdDeviation: Double, color: Color)
}

/// A parsed SVG `<mask>` definition.
public struct SVGMaskDef: Equatable, Sendable {
	public let id: String
	public let children: [SVGElement]

	public init(id: String, children: [SVGElement]) {
		self.id = id
		self.children = children
	}
}
