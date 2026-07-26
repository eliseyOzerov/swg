import Foundation

/// Common SVG presentation attributes for fill, stroke, opacity, and transform.
public struct SVGPaintAttributes: Equatable, Sendable {
	public var color: Color
	public var fill: SVGPaint
	public var fillOpacity: Double
	public var fillRule: FillRule
	public var stroke: SVGPaint
	public var strokeWidth: Double
	public var strokeLineCap: LineCap
	public var strokeLineJoin: LineJoin
	public var strokeMiterLimit: Double
	public var strokeDashArray: [Double]
	public var strokeDashOffset: Double
	public var strokeOpacity: Double
	public var paintOrder: SVGPaintOrder
	public var opacity: Double
	public var transform: Transform
	public var visibility: SVGVisibility
	public var display: SVGDisplay
	public var clipPathID: String?
	public var filterID: String?
	public var maskID: String?
	public var vectorEffect: SVGVectorEffect

	public init(
		color: Color = .black,
		fill: SVGPaint = .color(.black),
		fillOpacity: Double = 1,
		fillRule: FillRule = .winding,
		stroke: SVGPaint = .none,
		strokeWidth: Double = 1,
		strokeLineCap: LineCap = .butt,
		strokeLineJoin: LineJoin = .miter,
		strokeMiterLimit: Double = 4,
		strokeDashArray: [Double] = [],
		strokeDashOffset: Double = 0,
		strokeOpacity: Double = 1,
		paintOrder: SVGPaintOrder = .normal,
		opacity: Double = 1,
		transform: Transform = .identity,
		visibility: SVGVisibility = .visible,
		display: SVGDisplay = .inline,
		clipPathID: String? = nil,
		filterID: String? = nil,
		maskID: String? = nil,
		vectorEffect: SVGVectorEffect = .none
	) {
		self.color = color
		self.fill = fill
		self.fillOpacity = fillOpacity
		self.fillRule = fillRule
		self.stroke = stroke
		self.strokeWidth = strokeWidth
		self.strokeLineCap = strokeLineCap
		self.strokeLineJoin = strokeLineJoin
		self.strokeMiterLimit = strokeMiterLimit
		self.strokeDashArray = strokeDashArray
		self.strokeDashOffset = strokeDashOffset
		self.strokeOpacity = strokeOpacity
		self.paintOrder = paintOrder
		self.opacity = opacity
		self.transform = transform
		self.visibility = visibility
		self.display = display
		self.clipPathID = clipPathID
		self.filterID = filterID
		self.maskID = maskID
		self.vectorEffect = vectorEffect
	}

	public static let defaults = SVGPaintAttributes()
}

/// SVG paint value for solid colors, inherited current color, none, or URL references.
public enum SVGPaint: Equatable, Sendable {
	case none
	case color(Color)
	case currentColor
	case url(String)
	indirect case urlWithFallback(String, SVGPaint)
	case contextFill
	case contextStroke
}

/// SVG `paint-order` value for arranging fill, stroke, and marker painting.
public enum SVGPaintOrder: Equatable, Sendable {
	case normal
	case specified([SVGPaintOperation])

	public var resolvedOperations: [SVGPaintOperation] {
		switch self {
		case .normal:
			SVGPaintOperation.normalOrder
		case .specified(let operations):
			operations + SVGPaintOperation.normalOrder.filter { !operations.contains($0) }
		}
	}
}

/// Individual SVG paint operation used by `SVGPaintOrder`.
public enum SVGPaintOperation: Equatable, Sendable, Hashable {
	case fill
	case stroke
	case markers

	static let normalOrder: [SVGPaintOperation] = [.fill, .stroke, .markers]
}

/// SVG visibility property value.
public enum SVGVisibility: Sendable, Equatable, Hashable {
	case visible
	case hidden
	case collapse
}

/// SVG display property value.
public enum SVGDisplay: Sendable, Equatable, Hashable {
	case inline
	case none
}

/// SVG vector-effect property value that controls constrained transform behavior.
public enum SVGVectorEffect: Sendable, Equatable, Hashable {
	case none
	case effects([SVGVectorEffectComponent], coordinateSpace: SVGVectorEffectCoordinateSpace)
}

/// Individual vector-effect keyword other than none or coordinate space.
public enum SVGVectorEffectComponent: Sendable, Equatable, Hashable {
	case nonScalingStroke
	case nonScalingSize
	case nonRotation
	case fixedPosition
}

/// Host coordinate space used for vector-effect constrained transformations.
public enum SVGVectorEffectCoordinateSpace: Sendable, Equatable, Hashable {
	case viewport
	case screen
}

/// Per-element style override that renderers can apply after parsing.
public struct SVGOverride: Equatable, Sendable {
	public var fill: Color?
	public var stroke: Color?
	public var strokeWidth: Double?
	public var opacity: Double?
	public var fillOpacity: Double?
	public var strokeOpacity: Double?
	public var dashArray: [Double]?
	public var visibility: SVGVisibility?
	public var isHidden: Bool

	public init(
		fill: Color? = nil,
		stroke: Color? = nil,
		strokeWidth: Double? = nil,
		opacity: Double? = nil,
		fillOpacity: Double? = nil,
		strokeOpacity: Double? = nil,
		dashArray: [Double]? = nil,
		visibility: SVGVisibility? = nil,
		isHidden: Bool = false
	) {
		self.fill = fill
		self.stroke = stroke
		self.strokeWidth = strokeWidth
		self.opacity = opacity
		self.fillOpacity = fillOpacity
		self.strokeOpacity = strokeOpacity
		self.dashArray = dashArray
		self.visibility = visibility
		self.isHidden = isHidden
	}
}
