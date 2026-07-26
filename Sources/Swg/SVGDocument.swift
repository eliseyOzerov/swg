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
	public var rootMetadata: [SVGMetadataData]
	public var elementMetadata: [String: [SVGMetadataData]]
	public var animations: [SVGAnimationElement]
	public var scripts: [SVGScriptData]

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
		selectedElementDescriptions: [String: SVGDescriptionData] = [:],
		rootMetadata: [SVGMetadataData] = [],
		elementMetadata: [String: [SVGMetadataData]] = [:],
		animations: [SVGAnimationElement] = [],
		scripts: [SVGScriptData] = []
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
		self.rootMetadata = rootMetadata
		self.elementMetadata = elementMetadata
		self.animations = animations
		self.scripts = scripts
	}

	public var elementIDs: [String] {
		elements.flatMap { $0.collectIDs() }
	}
}

/// An SVG animation element preserved for later target-time evaluation.
public enum SVGAnimationElement: Equatable, Sendable {
	case animate(SVGAnimateData)
	case animateMotion(SVGAnimateMotionData)
	case animateTransform(SVGAnimateTransformData)
	case set(SVGSetData)
	case discard(SVGDiscardData)
}

/// The target relationship for an SVG animation element.
public enum SVGAnimationTarget: Equatable, Sendable {
	case parent(id: String?)
	case href(String)
}

/// A parsed SVG animation timing value used by `SVGAnimationTimingData`.
public enum SVGAnimationTimeValue: Equatable, Sendable {
	case clock(rawValue: String, seconds: Double)
	case indefinite
	case media
	case unresolved(String)
}

/// The SVG `restart` timing policy for an animation element.
public enum SVGAnimationRestart: Equatable, Sendable {
	case always
	case whenNotActive
	case never
	case unresolved(String)
}

/// The SVG `repeatCount` timing value for an animation element.
public enum SVGAnimationRepeatCount: Equatable, Sendable {
	case number(rawValue: String, value: Double)
	case indefinite
	case unresolved(String)
}

/// The SVG `calcMode` value for interpolation between animation values.
public enum SVGAnimationCalcMode: Equatable, Sendable {
	case discrete
	case linear
	case paced
	case spline
	case unresolved(String)
}

/// Parsed SVG `keyTimes` values for an animation element.
public enum SVGAnimationKeyTimes: Equatable, Sendable {
	case values([Double])
	case unresolved([String])
}

/// One SVG `keySplines` cubic Bezier control point quadruple.
public struct SVGAnimationKeySpline: Equatable, Sendable {
	public let x1: Double
	public let y1: Double
	public let x2: Double
	public let y2: Double

	public init(x1: Double, y1: Double, x2: Double, y2: Double) {
		self.x1 = x1
		self.y1 = y1
		self.x2 = x2
		self.y2 = y2
	}
}

/// Parsed SVG `keySplines` values for an animation element.
public enum SVGAnimationKeySplines: Equatable, Sendable {
	case values([SVGAnimationKeySpline])
	case unresolved([String])
}

/// The SVG `additive` mode for value animation elements.
public enum SVGAnimationAdditive: Equatable, Sendable {
	case replace
	case sum
	case unresolved(String)
}

/// The SVG `accumulate` mode for repeated value animation elements.
public enum SVGAnimationAccumulate: Equatable, Sendable {
	case none
	case sum
	case unresolved(String)
}

/// Addition attributes common to SVG value animation elements.
public struct SVGAnimationAdditionData: Equatable, Sendable {
	public let additive: SVGAnimationAdditive
	public let accumulate: SVGAnimationAccumulate

	public init(additive: SVGAnimationAdditive = .replace, accumulate: SVGAnimationAccumulate = .none) {
		self.additive = additive
		self.accumulate = accumulate
	}
}

/// Value-control attributes common to SVG value animation elements.
public struct SVGAnimationValueControlData: Equatable, Sendable {
	public let calcMode: SVGAnimationCalcMode?
	public let values: [String]?
	public let keyTimes: SVGAnimationKeyTimes?
	public let keySplines: SVGAnimationKeySplines?

	public init(calcMode: SVGAnimationCalcMode? = nil, values: [String]? = nil, keyTimes: SVGAnimationKeyTimes? = nil, keySplines: SVGAnimationKeySplines? = nil) {
		self.calcMode = calcMode
		self.values = values
		self.keyTimes = keyTimes
		self.keySplines = keySplines
	}
}

/// Timing attributes common to SVG animation elements such as `SVGAnimateData`.
public struct SVGAnimationTimingData: Equatable, Sendable {
	public let begin: [SVGAnimationTimeValue]
	public let dur: SVGAnimationTimeValue
	public let end: [SVGAnimationTimeValue]
	public let min: SVGAnimationTimeValue
	public let max: SVGAnimationTimeValue?
	public let restart: SVGAnimationRestart
	public let repeatCount: SVGAnimationRepeatCount?
	public let repeatDur: SVGAnimationTimeValue?

	public init(
		begin: [SVGAnimationTimeValue] = [.clock(rawValue: "0s", seconds: 0)],
		dur: SVGAnimationTimeValue = .indefinite,
		end: [SVGAnimationTimeValue] = [],
		min: SVGAnimationTimeValue = .clock(rawValue: "0s", seconds: 0),
		max: SVGAnimationTimeValue? = nil,
		restart: SVGAnimationRestart = .always,
		repeatCount: SVGAnimationRepeatCount? = nil,
		repeatDur: SVGAnimationTimeValue? = nil
	) {
		self.begin = begin
		self.dur = dur
		self.end = end
		self.min = min
		self.max = max
		self.restart = restart
		self.repeatCount = repeatCount
		self.repeatDur = repeatDur
	}
}

/// Data for an SVG `<animate>` element that changes one attribute or property over time.
public struct SVGAnimateData: Equatable, Sendable {
	public let id: String
	public let target: SVGAnimationTarget?
	public let attributeName: String?
	public let fromValue: String?
	public let toValue: String?
	public let byValue: String?
	public let timing: SVGAnimationTimingData
	public let valueControl: SVGAnimationValueControlData
	public let addition: SVGAnimationAdditionData
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, target: SVGAnimationTarget? = nil, attributeName: String? = nil, fromValue: String? = nil, toValue: String? = nil, byValue: String? = nil, timing: SVGAnimationTimingData = SVGAnimationTimingData(), valueControl: SVGAnimationValueControlData = SVGAnimationValueControlData(), addition: SVGAnimationAdditionData = SVGAnimationAdditionData(), language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.target = target
		self.attributeName = attributeName
		self.fromValue = fromValue
		self.toValue = toValue
		self.byValue = byValue
		self.timing = timing
		self.valueControl = valueControl
		self.addition = addition
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data for an SVG `<animateMotion>` element that moves a target along a path over time.
public struct SVGAnimateMotionData: Equatable, Sendable {
	public let id: String
	public let target: SVGAnimationTarget?
	public let path: String?
	public let keyPoints: String?
	public let rotate: String?
	public let origin: String?
	public let mpath: SVGMPathData?
	public let fromValue: String?
	public let toValue: String?
	public let byValue: String?
	public let timing: SVGAnimationTimingData
	public let valueControl: SVGAnimationValueControlData
	public let addition: SVGAnimationAdditionData
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, target: SVGAnimationTarget? = nil, path: String? = nil, keyPoints: String? = nil, rotate: String? = nil, origin: String? = nil, mpath: SVGMPathData? = nil, fromValue: String? = nil, toValue: String? = nil, byValue: String? = nil, timing: SVGAnimationTimingData = SVGAnimationTimingData(), valueControl: SVGAnimationValueControlData = SVGAnimationValueControlData(), addition: SVGAnimationAdditionData = SVGAnimationAdditionData(), language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.target = target
		self.path = path
		self.keyPoints = keyPoints
		self.rotate = rotate
		self.origin = origin
		self.mpath = mpath
		self.fromValue = fromValue
		self.toValue = toValue
		self.byValue = byValue
		self.timing = timing
		self.valueControl = valueControl
		self.addition = addition
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data for an SVG `<mpath>` child that references motion path geometry.
public struct SVGMPathData: Equatable, Sendable {
	public let id: String
	public let href: String?
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, href: String? = nil, language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.href = href
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data for an SVG `<animateTransform>` element that changes a transform value over time.
public struct SVGAnimateTransformData: Equatable, Sendable {
	public let id: String
	public let target: SVGAnimationTarget?
	public let attributeName: String?
	public let type: String
	public let fromValue: String?
	public let toValue: String?
	public let byValue: String?
	public let timing: SVGAnimationTimingData
	public let valueControl: SVGAnimationValueControlData
	public let addition: SVGAnimationAdditionData
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, target: SVGAnimationTarget? = nil, attributeName: String? = nil, type: String = "translate", fromValue: String? = nil, toValue: String? = nil, byValue: String? = nil, timing: SVGAnimationTimingData = SVGAnimationTimingData(), valueControl: SVGAnimationValueControlData = SVGAnimationValueControlData(), addition: SVGAnimationAdditionData = SVGAnimationAdditionData(), language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.target = target
		self.attributeName = attributeName
		self.type = type
		self.fromValue = fromValue
		self.toValue = toValue
		self.byValue = byValue
		self.timing = timing
		self.valueControl = valueControl
		self.addition = addition
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data for an SVG `<set>` element that assigns one attribute or property value over time.
public struct SVGSetData: Equatable, Sendable {
	public let id: String
	public let target: SVGAnimationTarget?
	public let attributeName: String?
	public let toValue: String?
	public let timing: SVGAnimationTimingData
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, target: SVGAnimationTarget? = nil, attributeName: String? = nil, toValue: String? = nil, timing: SVGAnimationTimingData = SVGAnimationTimingData(), language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.target = target
		self.attributeName = attributeName
		self.toValue = toValue
		self.timing = timing
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data for an SVG `<discard>` element that removes a target after activation.
public struct SVGDiscardData: Equatable, Sendable {
	public let id: String
	public let target: SVGAnimationTarget?
	public let begin: String
	public let timing: SVGAnimationTimingData
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, target: SVGAnimationTarget? = nil, begin: String = "0s", timing: SVGAnimationTimingData = SVGAnimationTimingData(), language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.target = target
		self.begin = begin
		self.timing = timing
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Non-rendered data preserved from an SVG `<script>` element.
public struct SVGScriptData: Equatable, Sendable {
	public let id: String
	public let href: String?
	public let type: String
	public let crossOrigin: String?
	public let content: String
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, href: String? = nil, type: String = "application/ecmascript", crossOrigin: String? = nil, content: String = "", language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.href = href
		self.type = type
		self.crossOrigin = crossOrigin
		self.content = content
		self.language = language
		self.unknownAttributes = unknownAttributes
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

/// Metadata payload from an SVG `<metadata>` descriptive element.
public struct SVGMetadataData: Equatable, Sendable {
	public let id: String
	public let language: String?
	public let unknownAttributes: [String: String]
	public let children: [SVGMetadataNode]

	public init(id: String, language: String? = nil, unknownAttributes: [String: String] = [:], children: [SVGMetadataNode] = []) {
		self.id = id
		self.language = language
		self.unknownAttributes = unknownAttributes
		self.children = children
	}
}

/// A text or element node preserved from an SVG `<metadata>` subtree.
public indirect enum SVGMetadataNode: Equatable, Sendable {
	case text(String)
	case element(SVGMetadataElementData)

	public var text: String? {
		if case .text(let value) = self {
			return value
		}
		return nil
	}

	public var element: SVGMetadataElementData? {
		if case .element(let value) = self {
			return value
		}
		return nil
	}
}

/// An XML element preserved inside SVG metadata.
public struct SVGMetadataElementData: Equatable, Sendable {
	public let name: String
	public let localName: String
	public let namespaceURI: String?
	public let attributes: [String: String]
	public let children: [SVGMetadataNode]

	public init(name: String, localName: String, namespaceURI: String? = nil, attributes: [String: String] = [:], children: [SVGMetadataNode] = []) {
		self.name = name
		self.localName = localName
		self.namespaceURI = namespaceURI
		self.attributes = attributes
		self.children = children
	}
}

/// A registry of reusable SVG definitions such as gradients, patterns, markers, clip paths, filters, and masks.
public struct SVGDefs: Equatable, Sendable {
	public var linearGradients: [String: SVGLinearGradientDef]
	public var radialGradients: [String: SVGRadialGradientDef]
	public var patterns: [String: SVGPatternDef]
	public var markers: [String: SVGMarkerDef]
	public var symbols: [String: SVGSymbolData]
	public var views: [String: SVGViewData]
	public var clipPathDefinitions: [String: SVGClipPathDef]
	public var clipPaths: [String: [SVGElement]]
	public var filters: [String: SVGFilterDef]
	public var masks: [String: SVGMaskDef]
	public var reusableElements: [String: [SVGElement]]

	public init(
		linearGradients: [String: SVGLinearGradientDef] = [:],
		radialGradients: [String: SVGRadialGradientDef] = [:],
		patterns: [String: SVGPatternDef] = [:],
		markers: [String: SVGMarkerDef] = [:],
		symbols: [String: SVGSymbolData] = [:],
		views: [String: SVGViewData] = [:],
		clipPathDefinitions: [String: SVGClipPathDef] = [:],
		clipPaths: [String: [SVGElement]] = [:],
		filters: [String: SVGFilterDef] = [:],
		masks: [String: SVGMaskDef] = [:],
		reusableElements: [String: [SVGElement]] = [:]
	) {
		self.linearGradients = linearGradients
		self.radialGradients = radialGradients
		self.patterns = patterns
		self.markers = markers
		self.symbols = symbols
		self.views = views
		self.clipPathDefinitions = clipPathDefinitions
		self.clipPaths = clipPaths
		self.filters = filters
		self.masks = masks
		self.reusableElements = reusableElements
	}
}

/// A reusable SVG `<marker>` definition with viewport geometry and marker graphics.
public struct SVGMarkerDef: Equatable, Sendable {
	public var id: String
	public var refX: String
	public var refY: String
	public var markerWidth: Double
	public var markerHeight: Double
	public var markerUnits: SVGMarkerUnits
	public var orient: SVGMarkerOrient
	public var viewBox: Rect?
	public var preserveAspectRatio: SVGPreserveAspectRatio
	public var attributes: SVGPaintAttributes
	public var children: [SVGElement]
	public var language: String?
	public var unknownAttributes: [String: String]

	public init(id: String, refX: String = "0", refY: String = "0", markerWidth: Double = 3, markerHeight: Double = 3, markerUnits: SVGMarkerUnits = .strokeWidth, orient: SVGMarkerOrient = .angle(0), viewBox: Rect? = nil, preserveAspectRatio: SVGPreserveAspectRatio = .default, attributes: SVGPaintAttributes = .defaults, children: [SVGElement] = [], language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.refX = refX
		self.refY = refY
		self.markerWidth = markerWidth
		self.markerHeight = markerHeight
		self.markerUnits = markerUnits
		self.orient = orient
		self.viewBox = viewBox
		self.preserveAspectRatio = preserveAspectRatio
		self.attributes = attributes
		self.children = children
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Coordinate system used for an SVG `<marker>` definition.
public enum SVGMarkerUnits: Equatable, Sendable, Hashable {
	case strokeWidth
	case userSpaceOnUse
}

/// Orientation mode requested by an SVG `<marker>` definition.
public enum SVGMarkerOrient: Equatable, Sendable, Hashable {
	case auto
	case autoStartReverse
	case angle(Double)
}

/// A reusable SVG `<clipPath>` definition with coordinate units and clipping geometry.
public struct SVGClipPathDef: Equatable, Sendable {
	public var id: String
	public var units: SVGClipPathUnits
	public var children: [SVGElement]

	public init(id: String, units: SVGClipPathUnits = .userSpaceOnUse, children: [SVGElement] = []) {
		self.id = id
		self.units = units
		self.children = children
	}
}

/// Coordinate system used for SVG `<clipPath>` child content.
public enum SVGClipPathUnits: Equatable, Sendable, Hashable {
	case objectBoundingBox
	case userSpaceOnUse
}

/// A single SVG shape, group, foreign object, unknown container, text, image, or use element.
public indirect enum SVGElement: Equatable, Sendable {
	case path(SVGPathData)
	case rect(SVGRectData)
	case circle(SVGCircleData)
	case ellipse(SVGEllipseData)
	case line(SVGLineData)
	case polygon(SVGPolygonData)
	case polyline(SVGPolylineData)
	case group(SVGGroupData)
	case `switch`(SVGSwitchData)
	case link(SVGLinkData)
	case svg(SVGViewportData)
	case unknown(SVGUnknownElementData)
	case use(SVGUseData)
	case image(SVGImageData)
	case foreignObject(SVGForeignObjectData)
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
		case .foreignObject(let data): [data.id] + data.children.flatMap { $0.collectIDs() }
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
	public let rxIsAuto: Bool
	public let ryIsAuto: Bool
	public let attributes: SVGPaintAttributes
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, x: Double, y: Double, width: Double, height: Double, rx: Double, ry: Double, attributes: SVGPaintAttributes, rxIsAuto: Bool = false, ryIsAuto: Bool = false, language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.x = x
		self.y = y
		self.width = width
		self.height = height
		self.rx = rx
		self.ry = ry
		self.rxIsAuto = rxIsAuto
		self.ryIsAuto = ryIsAuto
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
	public let rxIsAuto: Bool
	public let ryIsAuto: Bool
	public let attributes: SVGPaintAttributes
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, cx: Double, cy: Double, rx: Double, ry: Double, attributes: SVGPaintAttributes, rxIsAuto: Bool = false, ryIsAuto: Bool = false, language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.cx = cx
		self.cy = cy
		self.rx = rx
		self.ry = ry
		self.rxIsAuto = rxIsAuto
		self.ryIsAuto = ryIsAuto
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

/// Data for an SVG `<polygon>` element.
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

/// Data for an SVG `<polyline>` element.
public struct SVGPolylineData: Equatable, Sendable {
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

/// Data for an SVG `<pattern>` paint server.
public struct SVGPatternDef: Equatable, Sendable {
	public var id: String
	public var x: Double
	public var y: Double
	public var width: Double
	public var height: Double
	public var patternUnits: SVGPatternUnits
	public var patternContentUnits: SVGPatternUnits
	public var patternTransform: Transform
	public var viewBox: Rect?
	public var preserveAspectRatio: SVGPreserveAspectRatio
	public var href: String?
	public var attributes: SVGPaintAttributes
	public var children: [SVGElement]
	public var language: String?
	public var unknownAttributes: [String: String]

	public init(
		id: String,
		x: Double = 0,
		y: Double = 0,
		width: Double = 0,
		height: Double = 0,
		patternUnits: SVGPatternUnits = .objectBoundingBox,
		patternContentUnits: SVGPatternUnits = .userSpaceOnUse,
		patternTransform: Transform = .identity,
		viewBox: Rect? = nil,
		preserveAspectRatio: SVGPreserveAspectRatio = .default,
		href: String? = nil,
		attributes: SVGPaintAttributes = .defaults,
		children: [SVGElement] = [],
		language: String? = nil,
		unknownAttributes: [String: String] = [:]
	) {
		self.id = id
		self.x = x
		self.y = y
		self.width = width
		self.height = height
		self.patternUnits = patternUnits
		self.patternContentUnits = patternContentUnits
		self.patternTransform = patternTransform
		self.viewBox = viewBox
		self.preserveAspectRatio = preserveAspectRatio
		self.href = href
		self.attributes = attributes
		self.children = children
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Coordinate space for SVG pattern tile geometry.
public enum SVGPatternUnits: Sendable, Equatable, Hashable {
	case objectBoundingBox
	case userSpaceOnUse
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

	/// Computes the SVG `viewBox` transform that maps user coordinates into a viewport rectangle.
	public func viewBoxTransform(from viewBox: Rect, to viewport: Rect) -> Transform? {
		guard viewBox.width > 0, viewBox.height > 0, viewport.width >= 0, viewport.height >= 0 else { return nil }

		var scaleX = viewport.width / viewBox.width
		var scaleY = viewport.height / viewBox.height
		if align != .none {
			switch meetOrSlice ?? .meet {
			case .meet:
				let scale = min(scaleX, scaleY)
				scaleX = scale
				scaleY = scale
			case .slice:
				let scale = max(scaleX, scaleY)
				scaleX = scale
				scaleY = scale
			}
		}

		var translateX = viewport.x - viewBox.x * scaleX
		var translateY = viewport.y - viewBox.y * scaleY
		if align.usesMidX {
			translateX += (viewport.width - viewBox.width * scaleX) / 2
		} else if align.usesMaxX {
			translateX += viewport.width - viewBox.width * scaleX
		}
		if align.usesMidY {
			translateY += (viewport.height - viewBox.height * scaleY) / 2
		} else if align.usesMaxY {
			translateY += viewport.height - viewBox.height * scaleY
		}

		return Transform(a: scaleX, b: 0, c: 0, d: scaleY, tx: translateX, ty: translateY)
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

private extension SVGPreserveAspectRatioAlign {
	var usesMidX: Bool {
		switch self {
		case .xMidYMin, .xMidYMid, .xMidYMax:
			true
		default:
			false
		}
	}

	var usesMaxX: Bool {
		switch self {
		case .xMaxYMin, .xMaxYMid, .xMaxYMax:
			true
		default:
			false
		}
	}

	var usesMidY: Bool {
		switch self {
		case .xMinYMid, .xMidYMid, .xMaxYMid:
			true
		default:
			false
		}
	}

	var usesMaxY: Bool {
		switch self {
		case .xMinYMax, .xMidYMax, .xMaxYMax:
			true
		default:
			false
		}
	}
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

/// Data for an SVG `<foreignObject>` element that embeds non-SVG content in a rectangular SVG region.
public struct SVGForeignObjectData: Equatable, Sendable {
	public let id: String
	public let x: Double
	public let y: Double
	public let width: Double
	public let height: Double
	public let attributes: SVGPaintAttributes
	public let children: [SVGElement]
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, x: Double, y: Double, width: Double, height: Double, attributes: SVGPaintAttributes, children: [SVGElement] = [], language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.x = x
		self.y = y
		self.width = width
		self.height = height
		self.attributes = attributes
		self.children = children
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data for an SVG `<text>` element.
public struct SVGTextData: Equatable, Sendable {
	public let id: String
	public let x: Double
	public let y: Double
	public let xValues: [Double]
	public let yValues: [Double]
	public let dxValues: [Double]
	public let dyValues: [Double]
	public let rotateValues: [Double]
	public let fontSize: Double
	public let fontFamily: String
	public let fontWeight: String
	public let textAnchor: SVGTextAnchor
	public let dominantBaseline: SVGTextDominantBaseline
	public let whiteSpace: SVGTextWhiteSpace
	public let attributes: SVGPaintAttributes
	public let spans: [SVGTextSpan]
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(id: String, x: Double, y: Double, xValues: [Double] = [], yValues: [Double] = [], dxValues: [Double] = [], dyValues: [Double] = [], rotateValues: [Double] = [], fontSize: Double, fontFamily: String, fontWeight: String, textAnchor: SVGTextAnchor, dominantBaseline: SVGTextDominantBaseline = .auto, whiteSpace: SVGTextWhiteSpace = .normal, attributes: SVGPaintAttributes, spans: [SVGTextSpan], language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.id = id
		self.x = x
		self.y = y
		self.xValues = xValues
		self.yValues = yValues
		self.dxValues = dxValues
		self.dyValues = dyValues
		self.rotateValues = rotateValues
		self.fontSize = fontSize
		self.fontFamily = fontFamily
		self.fontWeight = fontWeight
		self.textAnchor = textAnchor
		self.dominantBaseline = dominantBaseline
		self.whiteSpace = whiteSpace
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
	public let xValues: [Double]
	public let yValues: [Double]
	public let dxValues: [Double]
	public let dyValues: [Double]
	public let rotateValues: [Double]
	public let fontSize: Double?
	public let fontWeight: String?
	public let textAnchor: SVGTextAnchor?
	public let dominantBaseline: SVGTextDominantBaseline?
	public let alignmentBaseline: SVGTextAlignmentBaseline?
	public let whiteSpace: SVGTextWhiteSpace?
	public let attributes: SVGPaintAttributes?
	public let textPath: SVGTextPathData?
	public let language: String?
	public let unknownAttributes: [String: String]

	public init(text: String, x: Double?, y: Double?, dx: Double, dy: Double, xValues: [Double] = [], yValues: [Double] = [], dxValues: [Double] = [], dyValues: [Double] = [], rotateValues: [Double] = [], fontSize: Double?, fontWeight: String?, textAnchor: SVGTextAnchor? = nil, dominantBaseline: SVGTextDominantBaseline? = nil, alignmentBaseline: SVGTextAlignmentBaseline? = nil, whiteSpace: SVGTextWhiteSpace? = nil, attributes: SVGPaintAttributes?, textPath: SVGTextPathData? = nil, language: String? = nil, unknownAttributes: [String: String] = [:]) {
		self.text = text
		self.x = x
		self.y = y
		self.dx = dx
		self.dy = dy
		self.xValues = xValues
		self.yValues = yValues
		self.dxValues = dxValues
		self.dyValues = dyValues
		self.rotateValues = rotateValues
		self.fontSize = fontSize
		self.fontWeight = fontWeight
		self.textAnchor = textAnchor
		self.dominantBaseline = dominantBaseline
		self.alignmentBaseline = alignmentBaseline
		self.whiteSpace = whiteSpace
		self.attributes = attributes
		self.textPath = textPath
		self.language = language
		self.unknownAttributes = unknownAttributes
	}
}

/// Data from an SVG `<textPath>` element that positions text along path geometry.
public struct SVGTextPathData: Equatable, Sendable {
	public let path: String?
	public let href: String?
	public let startOffset: String
	public let method: SVGTextPathMethod
	public let spacing: SVGTextPathSpacing
	public let side: SVGTextPathSide
	public let textAnchor: SVGTextAnchor?
	public let dominantBaseline: SVGTextDominantBaseline?
	public let alignmentBaseline: SVGTextAlignmentBaseline?
	public let whiteSpace: SVGTextWhiteSpace?
	public let attributes: SVGPaintAttributes
	public let unknownAttributes: [String: String]

	public init(path: String? = nil, href: String? = nil, startOffset: String = "0", method: SVGTextPathMethod = .align, spacing: SVGTextPathSpacing = .exact, side: SVGTextPathSide = .left, textAnchor: SVGTextAnchor? = nil, dominantBaseline: SVGTextDominantBaseline? = nil, alignmentBaseline: SVGTextAlignmentBaseline? = nil, whiteSpace: SVGTextWhiteSpace? = nil, attributes: SVGPaintAttributes, unknownAttributes: [String: String] = [:]) {
		self.path = path
		self.href = href
		self.startOffset = startOffset
		self.method = method
		self.spacing = spacing
		self.side = side
		self.textAnchor = textAnchor
		self.dominantBaseline = dominantBaseline
		self.alignmentBaseline = alignmentBaseline
		self.whiteSpace = whiteSpace
		self.attributes = attributes
		self.unknownAttributes = unknownAttributes
	}
}

/// Rendering method requested by an SVG `<textPath>` element.
public enum SVGTextPathMethod: Sendable, Equatable, Hashable {
	case align
	case stretch
}

/// Glyph spacing mode requested by an SVG `<textPath>` element.
public enum SVGTextPathSpacing: Sendable, Equatable, Hashable {
	case auto
	case exact
}

/// Side of the referenced path used by an SVG `<textPath>` element.
public enum SVGTextPathSide: Sendable, Equatable, Hashable {
	case left
	case right
}

/// Text alignment anchor for SVG text layout.
public enum SVGTextAnchor: Sendable, Equatable, Hashable {
	case start
	case middle
	case end
}

/// Dominant baseline requested by an SVG text content element.
public enum SVGTextDominantBaseline: Sendable, Equatable, Hashable {
	case auto
	case useScript
	case noChange
	case resetSize
	case ideographic
	case alphabetic
	case hanging
	case mathematical
	case central
	case middle
	case textAfterEdge
	case textBeforeEdge
	case textTop
	case textBottom
}

/// Alignment baseline requested by an SVG text content child element.
public enum SVGTextAlignmentBaseline: Sendable, Equatable, Hashable {
	case auto
	case baseline
	case beforeEdge
	case textBeforeEdge
	case middle
	case central
	case afterEdge
	case textAfterEdge
	case ideographic
	case alphabetic
	case hanging
	case mathematical
}

/// White-space handling requested by an SVG text content element.
public enum SVGTextWhiteSpace: Sendable, Equatable, Hashable {
	case normal
	case pre
	case nowrap
	case preWrap
	case preLine
	case breakSpaces
}

/// A parsed gradient stop.
public struct SVGGradientStop: Equatable, Sendable {
	public let offset: Double
	public let stopColor: SVGGradientStopColor
	public let currentColor: Color
	public let opacity: Double

	public var color: Color {
		stopColor.resolved(with: currentColor)
	}

	public init(offset: Double, color: Color, opacity: Double, stopColor: SVGGradientStopColor? = nil, currentColor: Color = .black) {
		self.offset = offset
		self.stopColor = stopColor ?? .color(color)
		self.currentColor = currentColor
		self.opacity = opacity
	}
}

/// A parsed SVG `stop-color` value.
public enum SVGGradientStopColor: Equatable, Sendable, Hashable {
	case color(Color)
	case currentColor

	public func resolved(with currentColor: Color) -> Color {
		switch self {
		case .color(let color):
			color
		case .currentColor:
			currentColor
		}
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
	public var spreadMethod: SVGGradientSpreadMethod
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
		spreadMethod: SVGGradientSpreadMethod = .pad,
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
		self.spreadMethod = spreadMethod
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
	public var fr: Double
	public var gradientUnits: SVGGradientUnits
	public var gradientTransform: Transform
	public var spreadMethod: SVGGradientSpreadMethod
	public var stops: [SVGGradientStop]
	public var href: String?

	public init(
		id: String,
		cx: Double = 0.5,
		cy: Double = 0.5,
		r: Double = 0.5,
		fx: Double? = nil,
		fy: Double? = nil,
		fr: Double = 0,
		gradientUnits: SVGGradientUnits = .objectBoundingBox,
		gradientTransform: Transform = .identity,
		spreadMethod: SVGGradientSpreadMethod = .pad,
		stops: [SVGGradientStop] = [],
		href: String? = nil
	) {
		self.id = id
		self.cx = cx
		self.cy = cy
		self.r = r
		self.fx = fx
		self.fy = fy
		self.fr = fr
		self.gradientUnits = gradientUnits
		self.gradientTransform = gradientTransform
		self.spreadMethod = spreadMethod
		self.stops = stops
		self.href = href
	}
}

/// Coordinate space for SVG gradient units.
public enum SVGGradientUnits: Sendable, Equatable, Hashable {
	case objectBoundingBox
	case userSpaceOnUse
}

/// Behavior for extending a gradient outside its defined vector or circles.
public enum SVGGradientSpreadMethod: Sendable, Equatable, Hashable {
	case pad
	case reflect
	case `repeat`
}

/// A parsed SVG `<filter>` definition.
public struct SVGFilterDef: Equatable, Sendable {
	public var id: String
	public var filterUnits: SVGFilterUnits
	public var primitiveUnits: SVGFilterPrimitiveUnits
	public var primitives: [SVGFilterPrimitive]

	public init(
		id: String,
		filterUnits: SVGFilterUnits = .objectBoundingBox,
		primitiveUnits: SVGFilterPrimitiveUnits = .userSpaceOnUse,
		primitives: [SVGFilterPrimitive] = []
	) {
		self.id = id
		self.filterUnits = filterUnits
		self.primitiveUnits = primitiveUnits
		self.primitives = primitives
	}
}

/// Coordinate system used for an SVG `<filter>` element's region attributes.
public enum SVGFilterUnits: Equatable, Sendable, Hashable {
	case objectBoundingBox
	case userSpaceOnUse
}

/// Coordinate system used for lengths inside SVG filter primitives.
public enum SVGFilterPrimitiveUnits: Equatable, Sendable, Hashable {
	case objectBoundingBox
	case userSpaceOnUse
}

/// A supported SVG filter primitive.
public enum SVGFilterPrimitive: Equatable, Sendable {
	case blend(input: String?, input2: String?, mode: SVGBlendMode = .normal, noComposite: Bool = false)
	case colorMatrix(input: String?, type: SVGColorMatrixType = .matrix, values: [Double], isPassThrough: Bool = false)
	case componentTransfer(input: String?, functions: [SVGComponentTransferChannel: SVGComponentTransferFunction] = [:])
	case composite(input: String?, input2: String?, operator: SVGCompositeOperator = .over, k1: Double = 0, k2: Double = 0, k3: Double = 0, k4: Double = 0)
	case convolveMatrix(input: String?, orderX: Int = 3, orderY: Int = 3, kernelMatrix: [Double], divisor: Double, bias: Double = 0, targetX: Int = 1, targetY: Int = 1, edgeMode: SVGFilterEdgeMode = .duplicate, kernelUnitLengthX: Double? = nil, kernelUnitLengthY: Double? = nil, preserveAlpha: Bool = false, isPassThrough: Bool = false)
	case diffuseLighting(input: String?, surfaceScale: Double = 1, diffuseConstant: Double = 1, kernelUnitLengthX: Double? = nil, kernelUnitLengthY: Double? = nil, lightSource: SVGFilterLightSource? = nil)
	case displacementMap(input: String?, input2: String?, scale: Double = 0, xChannelSelector: SVGFilterChannelSelector = .alpha, yChannelSelector: SVGFilterChannelSelector = .alpha)
	case flood(color: Color = .black)
	case image(href: String?, preserveAspectRatio: SVGPreserveAspectRatio = .default, crossOrigin: SVGCrossOriginMode? = nil)
	case merge(inputs: [String?] = [])
	case morphology(input: String?, operator: SVGMorphologyOperator = .erode, radiusX: Double = 0, radiusY: Double = 0, isPassThrough: Bool = true)
	case offset(input: String?, dx: Double = 0, dy: Double = 0)
	case specularLighting(input: String?, surfaceScale: Double = 1, specularConstant: Double = 1, specularExponent: Double = 1, kernelUnitLengthX: Double? = nil, kernelUnitLengthY: Double? = nil, lightSource: SVGFilterLightSource? = nil)
	case tile(input: String?)
	case turbulence(baseFrequencyX: Double = 0, baseFrequencyY: Double = 0, numOctaves: Int = 1, seed: Double = 0, stitchTiles: SVGTurbulenceStitchTiles = .noStitch, type: SVGTurbulenceType = .turbulence)
	case gaussianBlur(stdDeviationX: Double, stdDeviationY: Double, edgeMode: SVGFilterEdgeMode = .none)
	case dropShadow(dx: Double, dy: Double, stdDeviationX: Double, stdDeviationY: Double, color: Color)
}

/// Cross-origin mode for SVG image-fetching elements.
public enum SVGCrossOriginMode: Equatable, Sendable, Hashable {
	case anonymous
	case useCredentials
}

/// Light source used by an SVG lighting filter primitive.
public enum SVGFilterLightSource: Equatable, Sendable, Hashable {
	case distantLight(azimuth: Double = 0, elevation: Double = 0)
	case pointLight(x: Double = 0, y: Double = 0, z: Double = 0)
	case spotLight(x: Double = 0, y: Double = 0, z: Double = 0, pointsAtX: Double = 0, pointsAtY: Double = 0, pointsAtZ: Double = 0, specularExponent: Double = 1, limitingConeAngle: Double? = nil)
}

/// Color channel selected by an SVG filter primitive.
public enum SVGFilterChannelSelector: Equatable, Sendable, Hashable {
	case red
	case green
	case blue
	case alpha
}

/// Stitching behavior used by an SVG `<feTurbulence>` primitive.
public enum SVGTurbulenceStitchTiles: Equatable, Sendable, Hashable {
	case stitch
	case noStitch
}

/// Noise function used by an SVG `<feTurbulence>` primitive.
public enum SVGTurbulenceType: Equatable, Sendable, Hashable {
	case fractalNoise
	case turbulence
}

/// Morphology operation used by an SVG `<feMorphology>` primitive.
public enum SVGMorphologyOperator: Equatable, Sendable, Hashable {
	case erode
	case dilate
}

/// Blend mode used by an SVG `<feBlend>` primitive.
public enum SVGBlendMode: Equatable, Sendable, Hashable {
	case normal
	case darken
	case multiply
	case colorBurn
	case lighten
	case screen
	case colorDodge
	case overlay
	case softLight
	case hardLight
	case difference
	case exclusion
	case hue
	case saturation
	case color
	case luminosity
}

/// Color transformation operation used by an SVG `<feColorMatrix>` primitive.
public enum SVGColorMatrixType: Equatable, Sendable, Hashable {
	case matrix
	case saturate
	case hueRotate
	case luminanceToAlpha
}

/// Color or alpha channel addressed by an SVG component transfer function element.
public enum SVGComponentTransferChannel: Equatable, Sendable, Hashable {
	case red
	case green
	case blue
	case alpha
}

/// Transfer function data for an SVG component transfer channel.
public struct SVGComponentTransferFunction: Equatable, Sendable, Hashable {
	public var type: SVGComponentTransferFunctionType
	public var tableValues: [Double]
	public var slope: Double
	public var intercept: Double
	public var amplitude: Double
	public var exponent: Double
	public var offset: Double

	public init(
		type: SVGComponentTransferFunctionType = .identity,
		tableValues: [Double] = [],
		slope: Double = 1,
		intercept: Double = 0,
		amplitude: Double = 1,
		exponent: Double = 1,
		offset: Double = 0
	) {
		self.type = type
		self.tableValues = tableValues
		self.slope = slope
		self.intercept = intercept
		self.amplitude = amplitude
		self.exponent = exponent
		self.offset = offset
	}
}

/// Operation type used by an SVG component transfer function element.
public enum SVGComponentTransferFunctionType: Equatable, Sendable, Hashable {
	case identity
	case table
	case discrete
	case linear
	case gamma
}

/// Compositing operator used by an SVG `<feComposite>` primitive.
public enum SVGCompositeOperator: Equatable, Sendable, Hashable {
	case over
	case `in`
	case out
	case atop
	case xor
	case lighter
	case arithmetic
}

/// Edge handling behavior for an SVG `<feGaussianBlur>` primitive.
public enum SVGFilterEdgeMode: Equatable, Sendable, Hashable {
	case duplicate
	case wrap
	case none
}

/// A parsed SVG `<mask>` definition.
public struct SVGMaskDef: Equatable, Sendable {
	public let id: String
	public var maskUnits: SVGMaskUnits
	public var maskContentUnits: SVGMaskUnits
	public let children: [SVGElement]

	public init(
		id: String,
		maskUnits: SVGMaskUnits = .objectBoundingBox,
		maskContentUnits: SVGMaskUnits = .userSpaceOnUse,
		children: [SVGElement]
	) {
		self.id = id
		self.maskUnits = maskUnits
		self.maskContentUnits = maskContentUnits
		self.children = children
	}
}

/// Coordinate system used for an SVG `<mask>` element's region attributes or child contents.
public enum SVGMaskUnits: Equatable, Sendable, Hashable {
	case objectBoundingBox
	case userSpaceOnUse
}
