import CoreGraphics
import Foundation
import SwiftUI

/// A SwiftUI view that renders an `SVGDocument` with the package's native path renderer.
public struct SVG: View {
	@Binding private var boundDocument: SVGDocument?
	@State private var loadedDocument: SVGDocument?
	@State private var loadedSourceID: String?

	private var initialDocument: SVGDocument?
	private var usesBoundDocument: Bool
	private var loadSource: SVGLoadSource?

	/// Rendering and layout options applied to the document.
	public var options: SVGRenderOptions

	/// The parsed SVG document this view renders when one is available.
	public var document: SVGDocument? {
		usesBoundDocument ? boundDocument : initialDocument
	}

	/// Creates a SwiftUI SVG view from a parsed document.
	///
	/// - Parameters:
	///   - document: The parsed SVG document to display.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(_ document: SVGDocument, options: SVGRenderOptions = SVGRenderOptions()) {
		self.init(initialDocument: document, boundDocument: nil, loadSource: nil, options: options)
	}

	/// Creates a SwiftUI SVG view backed by a mutable optional document binding.
	///
	/// Use this initializer when the document may be loaded later, or when callers want to modify the parsed document after the view appears.
	///
	/// - Parameters:
	///   - document: A binding to the document the view should render.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(_ document: Binding<SVGDocument?>, options: SVGRenderOptions = SVGRenderOptions()) {
		self.init(initialDocument: nil, boundDocument: document, loadSource: nil, options: options)
	}

	/// Creates a SwiftUI SVG view backed by a mutable document binding.
	///
	/// - Parameters:
	///   - document: A binding to the document the view should render.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(_ document: Binding<SVGDocument>, options: SVGRenderOptions = SVGRenderOptions()) {
		self.init(Binding<SVGDocument?>(
			get: { document.wrappedValue },
			set: { newValue in
				if let newValue {
					document.wrappedValue = newValue
				}
			}
		), options: options)
	}

	/// Parses SVG source and creates a SwiftUI SVG view when parsing succeeds.
	///
	/// - Parameters:
	///   - source: The SVG XML source string to parse.
	///   - parser: The parser configuration to use.
	///   - options: Rendering and layout options for the root drawing pass.
	public init?(source: String, parser: SVGParser = SVGParser(), options: SVGRenderOptions = SVGRenderOptions()) {
		guard let document = parser.parse(source) else { return nil }
		self.init(document, options: options)
	}

	/// Creates a SwiftUI SVG view that loads SVG XML from a bundled resource path.
	///
	/// This mirrors SwiftUI's `Image` initializer for the common bundled-asset case. Pass `"checkmark"` for `checkmark.svg`, or a relative path such as `"Icons/checkmark.svg"` for a resource in a bundle subdirectory.
	///
	/// - Parameters:
	///   - assetPath: The bundled SVG resource name or relative path.
	///   - bundle: The bundle that contains the SVG resource.
	///   - document: An optional binding that receives the parsed document after loading.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(_ assetPath: String, bundle: Bundle = .main, document: Binding<SVGDocument?>? = nil, options: SVGRenderOptions = SVGRenderOptions()) {
		let url = SVGBundleResource.url(for: assetPath, in: bundle)
		self.init(initialDocument: nil, boundDocument: document, loadSource: url.map(SVGLoadSource.file), options: options)
	}

	/// Creates a SwiftUI SVG view that loads SVG XML from a network URL.
	///
	/// - Parameters:
	///   - url: The remote URL to load with `URLSession`.
	///   - document: An optional binding that receives the parsed document after loading.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(url: URL, document: Binding<SVGDocument?>? = nil, options: SVGRenderOptions = SVGRenderOptions()) {
		self.init(initialDocument: nil, boundDocument: document, loadSource: .url(url), options: options)
	}

	/// Creates a SwiftUI SVG view that loads SVG XML from a bundled resource.
	///
	/// - Parameters:
	///   - name: The resource name in `bundle`.
	///   - bundle: The bundle that contains the SVG resource.
	///   - fileExtension: The resource extension, usually `"svg"`.
	///   - subdirectory: An optional bundle subdirectory.
	///   - document: An optional binding that receives the parsed document after loading.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(asset name: String, bundle: Bundle = .main, fileExtension: String? = "svg", subdirectory: String? = nil, document: Binding<SVGDocument?>? = nil, options: SVGRenderOptions = SVGRenderOptions()) {
		let url = bundle.url(forResource: name, withExtension: fileExtension, subdirectory: subdirectory)
			?? bundle.url(forResource: name, withExtension: fileExtension)
		self.init(initialDocument: nil, boundDocument: document, loadSource: url.map(SVGLoadSource.file), options: options)
	}

	/// Creates a SwiftUI SVG view that loads SVG XML from a file URL.
	///
	/// - Parameters:
	///   - url: The file URL for an SVG stored in the app's filesystem.
	///   - document: An optional binding that receives the parsed document after loading.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(file url: URL, document: Binding<SVGDocument?>? = nil, options: SVGRenderOptions = SVGRenderOptions()) {
		self.init(initialDocument: nil, boundDocument: document, loadSource: .file(url), options: options)
	}

	/// Creates a SwiftUI SVG view that loads SVG XML from a filesystem path.
	///
	/// - Parameters:
	///   - path: The path for an SVG stored in the app's filesystem.
	///   - document: An optional binding that receives the parsed document after loading.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(file path: String, document: Binding<SVGDocument?>? = nil, options: SVGRenderOptions = SVGRenderOptions()) {
		self.init(file: URL(fileURLWithPath: path), document: document, options: options)
	}

	/// The SwiftUI body that renders the document into a `Canvas`.
	public var body: some View {
		Group {
			if let renderDocument {
				render(renderDocument)
			} else {
				SwiftUI.Color.clear
			}
		}
		.task(id: loadTaskID) {
			await loadSourceIfNeeded()
		}
	}

	private init(initialDocument: SVGDocument?, boundDocument: Binding<SVGDocument?>?, loadSource: SVGLoadSource?, options: SVGRenderOptions) {
		if let boundDocument {
			_boundDocument = boundDocument
			usesBoundDocument = true
		} else {
			_boundDocument = .constant(nil)
			usesBoundDocument = false
		}
		_loadedDocument = State(initialValue: initialDocument)
		_loadedSourceID = State(initialValue: nil)
		self.initialDocument = initialDocument
		self.loadSource = loadSource
		self.options = options
	}

	private var loadTaskID: String {
		"\(loadSource?.id ?? "none"):\(renderDocument == nil)"
	}

	private var renderDocument: SVGDocument? {
		usesBoundDocument ? boundDocument : loadedDocument ?? initialDocument
	}

	@ViewBuilder private func render(_ document: SVGDocument) -> some View {
		Canvas { context, size in
			let renderer = SVGCanvasRenderer(document: document, size: size, options: options)
			renderer.render(in: &context)
		}
		.aspectRatio(document.viewBox.aspectRatio, contentMode: options.contentMode)
	}

	@MainActor private func loadSourceIfNeeded() async {
		guard let loadSource else { return }
		guard renderDocument == nil || loadedSourceID != loadSource.id else { return }
		guard let document = try? await SVGDocumentLoader.load(from: loadSource) else { return }
		if usesBoundDocument {
			boundDocument = document
		} else {
			loadedDocument = document
		}
		loadedSourceID = loadSource.id
	}
}

/// Controls how `SVG` maps a parsed document into SwiftUI layout and drawing.
public struct SVGRenderOptions {
	/// The SwiftUI content mode used when the view proposes the document aspect ratio.
	public var contentMode: ContentMode
	/// An optional override for the root document's `preserveAspectRatio` mapping.
	public var preserveAspectRatio: SVGPreserveAspectRatio?
	/// A root opacity multiplier applied to all rendered content.
	public var opacity: Double

	/// Creates rendering options for `SVG`.
	///
	/// - Parameters:
	///   - contentMode: The SwiftUI content mode used for aspect-ratio layout.
	///   - preserveAspectRatio: A root `preserveAspectRatio` override, or `nil` to use the parsed document value.
	///   - opacity: A root opacity multiplier applied to rendered content.
	public init(contentMode: ContentMode = .fit, preserveAspectRatio: SVGPreserveAspectRatio? = nil, opacity: Double = 1) {
		self.contentMode = contentMode
		self.preserveAspectRatio = preserveAspectRatio
		self.opacity = opacity
	}
}

enum SVGLoadSource: Equatable {
	case url(URL)
	case file(URL)

	var id: String {
		switch self {
		case .url(let url):
			return "url:\(url.absoluteString)"
		case .file(let url):
			return "file:\(url.path)"
		}
	}
}

enum SVGDocumentLoader {
	static func load(from source: SVGLoadSource) async throws -> SVGDocument? {
		let data: Data
		switch source {
		case .url(let url):
			let response: URLResponse
			(data, response) = try await URLSession.shared.data(from: url)
			if let response = response as? HTTPURLResponse, !(200..<300).contains(response.statusCode) {
				return nil
			}
		case .file(let url):
			data = try Data(contentsOf: url)
		}
		return SVGParser().parse(data)
	}
}

enum SVGBundleResource {
	static func url(for path: String, in bundle: Bundle) -> URL? {
		let filePath = path as NSString
		let fileExtension = filePath.pathExtension.isEmpty ? "svg" : filePath.pathExtension
		let pathWithoutExtension = filePath.pathExtension.isEmpty ? path : filePath.deletingPathExtension
		let resourcePath = pathWithoutExtension as NSString
		let name = resourcePath.lastPathComponent
		let directory = resourcePath.deletingLastPathComponent
		let subdirectory = directory.isEmpty || directory == "." ? nil : directory

		return bundle.url(forResource: name, withExtension: fileExtension, subdirectory: subdirectory)
			?? bundle.url(forResource: pathWithoutExtension, withExtension: fileExtension)
			?? bundle.url(forResource: name, withExtension: fileExtension)
			?? bundle.url(forResource: path, withExtension: nil)
	}
}

private struct SVGCanvasRenderer {
	var document: SVGDocument
	var size: CGSize
	var options: SVGRenderOptions

	func render(in context: inout GraphicsContext) {
		guard size.width > 0, size.height > 0 else { return }
		guard let transform = (options.preserveAspectRatio ?? document.preserveAspectRatio).viewBoxTransform(
			from: document.viewBox,
			to: Rect(x: 0, y: 0, width: size.width, height: size.height)
		) else { return }

		context.drawLayer { layer in
			layer.concatenate(transform.cgAffineTransform)
			for element in document.elements {
				render(element, opacity: options.opacity, in: &layer)
			}
		}
	}

	private func render(_ element: SVGElement, opacity: Double, in context: inout GraphicsContext) {
		switch element {
		case .path(let data):
			render(path: data.path, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: false, in: &context)
		case .rect(let data):
			render(path: data.path, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: false, in: &context)
		case .circle(let data):
			render(path: data.path, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: false, in: &context)
		case .ellipse(let data):
			render(path: data.path, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: false, in: &context)
		case .line(let data):
			render(path: data.path, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: true, in: &context)
		case .polygon(let data):
			render(path: data.path, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: false, in: &context)
		case .polyline(let data):
			render(path: data.path, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: true, in: &context)
		case .group(let data):
			render(children: data.children, attributes: data.attributes, inheritedOpacity: opacity, in: &context)
		case .switch(let data):
			render(children: data.children, attributes: data.attributes, inheritedOpacity: opacity, in: &context)
		case .link(let data):
			render(children: data.children, attributes: data.attributes, inheritedOpacity: opacity, in: &context)
		case .svg(let data):
			render(viewport: data, inheritedOpacity: opacity, in: &context)
		case .unknown(let data):
			render(children: data.children, attributes: data.attributes, inheritedOpacity: opacity, in: &context)
		case .foreignObject(let data):
			render(children: data.children, attributes: data.attributes, inheritedOpacity: opacity, in: &context)
		case .use(let data):
			render(use: data, inheritedOpacity: opacity, in: &context)
		case .text(let data):
			render(text: data, inheritedOpacity: opacity, in: &context)
		case .image:
			break
		}
	}

	private func render(children: [SVGElement], attributes: SVGPaintAttributes, inheritedOpacity: Double, in context: inout GraphicsContext) {
		guard attributes.canRender else { return }
		context.drawLayer { layer in
			layer.concatenate(attributes.transform.cgAffineTransform)
			let childBounds = bounds(for: children)
			applyClip(attributes: attributes, bounds: childBounds, in: &layer)
			drawMasked(attributes: attributes, bounds: childBounds, in: &layer) { maskedLayer in
				let opacity = inheritedOpacity * attributes.opacity
				for child in children {
					render(child, opacity: opacity, in: &maskedLayer)
				}
			}
		}
	}

	private func render(viewport data: SVGViewportData, inheritedOpacity: Double, in context: inout GraphicsContext) {
		guard data.attributes.canRender else { return }
		context.drawLayer { layer in
			layer.concatenate(data.attributes.transform.cgAffineTransform)
			let viewportBounds = Rect(x: data.x, y: data.y, width: data.width, height: data.height)
			applyClip(attributes: data.attributes, bounds: viewportBounds, in: &layer)
			if let viewBox = data.viewBox, let transform = data.preserveAspectRatio.viewBoxTransform(
				from: viewBox,
				to: viewportBounds
			) {
				layer.concatenate(transform.cgAffineTransform)
			} else {
				layer.concatenate(Transform.identity.translatedBy(x: data.x, y: data.y).cgAffineTransform)
			}
			drawMasked(attributes: data.attributes, bounds: viewportBounds, in: &layer) { maskedLayer in
				let opacity = inheritedOpacity * data.attributes.opacity
				for child in data.children {
					render(child, opacity: opacity, in: &maskedLayer)
				}
			}
		}
	}

	private func render(use data: SVGUseData, inheritedOpacity: Double, in context: inout GraphicsContext) {
		guard data.attributes.canRender else { return }
		let referenceID = data.href.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
		context.drawLayer { layer in
			layer.concatenate(data.attributes.transform.translatedBy(x: data.x, y: data.y).cgAffineTransform)
			let useBounds = bounds(for: data)
			applyClip(attributes: data.attributes, bounds: useBounds, in: &layer)
			drawMasked(attributes: data.attributes, bounds: useBounds, in: &layer) { maskedLayer in
				let opacity = inheritedOpacity * data.attributes.opacity
				if let elements = document.defs.reusableElements[referenceID] {
					for element in elements {
						render(element, opacity: opacity, in: &maskedLayer)
					}
				} else if let symbol = document.defs.symbols[referenceID] {
					render(symbol: symbol, use: data, opacity: opacity, in: &maskedLayer)
				}
			}
		}
	}

	private func render(symbol: SVGSymbolData, use data: SVGUseData, opacity: Double, in context: inout GraphicsContext) {
		let width = data.width ?? symbol.width
		let height = data.height ?? symbol.height
		if let viewBox = symbol.viewBox, let transform = symbol.preserveAspectRatio.viewBoxTransform(
			from: viewBox,
			to: Rect(x: symbol.x, y: symbol.y, width: width, height: height)
		) {
			context.concatenate(transform.cgAffineTransform)
		}
		for child in symbol.children {
			render(child, opacity: opacity * symbol.attributes.opacity, in: &context)
		}
	}

	private func render(path model: Path, attributes: SVGPaintAttributes, inheritedOpacity: Double, forceStroke: Bool, in context: inout GraphicsContext) {
		guard attributes.canRender else { return }
		context.drawLayer { layer in
			layer.concatenate(attributes.transform.cgAffineTransform)
			let cgPath = model.cgPath
			let path = SwiftUI.Path(cgPath)
			let pathBounds = cgPath.svgBounds
			applyClip(attributes: attributes, bounds: pathBounds, in: &layer)
			drawMasked(attributes: attributes, bounds: pathBounds, in: &layer) { maskedLayer in
				let opacity = inheritedOpacity * attributes.opacity
				for operation in attributes.paintOrder.resolvedOperations {
					switch operation {
					case .fill:
						if !forceStroke {
							fill(path: path, bounds: pathBounds, paint: attributes.fill, currentColor: attributes.color, opacity: opacity * attributes.fillOpacity, fillRule: attributes.fillRule, in: &maskedLayer)
						}
					case .stroke:
						if let shading = shading(from: attributes.stroke, currentColor: attributes.color, opacity: opacity * attributes.strokeOpacity, bounds: pathBounds), attributes.strokeWidth > 0 {
							maskedLayer.stroke(path, with: shading, style: StrokeStyle(
								lineWidth: CGFloat(attributes.strokeWidth),
								lineCap: attributes.strokeLineCap.cgLineCap,
								lineJoin: attributes.strokeLineJoin.cgLineJoin,
								miterLimit: CGFloat(attributes.strokeMiterLimit),
								dash: attributes.strokeDashArray.map { CGFloat($0) },
								dashPhase: CGFloat(attributes.strokeDashOffset)
							))
						}
					case .markers:
						renderMarkers(for: model, attributes: attributes, inheritedOpacity: opacity, in: &maskedLayer)
					}
				}
			}
		}
	}

	private func renderMarkers(for path: Path, attributes: SVGPaintAttributes, inheritedOpacity: Double, in context: inout GraphicsContext) {
		guard attributes.markerStart != .none || attributes.markerMid != .none || attributes.markerEnd != .none else { return }
		for marker in markerPlacements(for: path, attributes: attributes) {
			render(marker: marker, inheritedOpacity: inheritedOpacity, in: &context)
		}
	}

	private func render(marker placement: SVGRenderMarkerPlacement, inheritedOpacity: Double, in context: inout GraphicsContext) {
		guard placement.definition.attributes.canRender, placement.definition.markerWidth > 0, placement.definition.markerHeight > 0 else { return }
		let markerBounds = Rect(x: 0, y: 0, width: placement.definition.markerWidth, height: placement.definition.markerHeight)
		let viewBoxTransform = placement.definition.viewBox.flatMap {
			placement.definition.preserveAspectRatio.viewBoxTransform(from: $0, to: markerBounds)
		} ?? .identity
		let referencePoint = Point(
			markerCoordinate(placement.definition.refX, basis: .horizontal, definition: placement.definition),
			markerCoordinate(placement.definition.refY, basis: .vertical, definition: placement.definition)
		).applying(viewBoxTransform)
		let unitScale = placement.definition.markerUnits == .strokeWidth ? max(0, placement.strokeWidth) : 1

		context.drawLayer { layer in
			layer.translateBy(x: placement.point.x, y: placement.point.y)
			layer.rotate(by: .radians(placement.angle))
			layer.scaleBy(x: unitScale, y: unitScale)
			layer.translateBy(x: -referencePoint.x, y: -referencePoint.y)
			layer.clip(to: SwiftUI.Path(Path(commands: [.rect(markerBounds)]).cgPath))
			layer.concatenate(viewBoxTransform.cgAffineTransform)
			let opacity = inheritedOpacity * placement.definition.attributes.opacity
			for child in placement.definition.children {
				render(child, opacity: opacity, in: &layer)
			}
		}
	}

	private func markerCoordinate(_ value: String, basis: SVGLengthPercentageBasis, definition: SVGMarkerDef) -> Double {
		SVGLengthParser.parse(value, context: SVGLengthContext(
			fontSize: 16,
			rootFontSize: 16,
			viewportWidth: definition.markerWidth,
			viewportHeight: definition.markerHeight
		), percentageBasis: basis) ?? 0
	}

	private func markerPlacements(for path: Path, attributes: SVGPaintAttributes) -> [SVGRenderMarkerPlacement] {
		let subpaths = markerSubpaths(for: path)
		guard !subpaths.isEmpty else { return [] }
		var placements: [SVGRenderMarkerPlacement] = []
		for subpath in subpaths {
			guard let firstSegment = subpath.segments.first, let lastSegment = subpath.segments.last else { continue }
			if let marker = markerDefinition(for: attributes.markerStart) {
				placements.append(SVGRenderMarkerPlacement(
					definition: marker,
					point: firstSegment.start,
					angle: markerAngle(for: marker.orient, incoming: nil, outgoing: firstSegment.startDirection, isStart: true),
					strokeWidth: attributes.strokeWidth
				))
			}
			if let marker = markerDefinition(for: attributes.markerMid), subpath.segments.count > 1 {
				for index in 0..<(subpath.segments.count - 1) {
					let incoming = subpath.segments[index].endDirection
					let outgoing = subpath.segments[index + 1].startDirection
					placements.append(SVGRenderMarkerPlacement(
						definition: marker,
						point: subpath.segments[index].end,
						angle: markerAngle(for: marker.orient, incoming: incoming, outgoing: outgoing, isStart: false),
						strokeWidth: attributes.strokeWidth
					))
				}
			}
			if let marker = markerDefinition(for: attributes.markerEnd) {
				placements.append(SVGRenderMarkerPlacement(
					definition: marker,
					point: lastSegment.end,
					angle: markerAngle(for: marker.orient, incoming: lastSegment.endDirection, outgoing: nil, isStart: false),
					strokeWidth: attributes.strokeWidth
				))
			}
		}
		return placements
	}

	private func markerDefinition(for reference: SVGMarkerReference) -> SVGMarkerDef? {
		switch reference {
		case .none:
			return nil
		case .url(let id):
			return document.defs.markers[id.trimmingCharacters(in: CharacterSet(charactersIn: "#"))]
		}
	}

	private func markerAngle(for orient: SVGMarkerOrient, incoming: Point?, outgoing: Point?, isStart: Bool) -> Double {
		switch orient {
		case .angle(let angle):
			return angle
		case .auto:
			return automaticMarkerAngle(incoming: incoming, outgoing: outgoing)
		case .autoStartReverse:
			let angle = automaticMarkerAngle(incoming: incoming, outgoing: outgoing)
			return isStart ? angle + .pi : angle
		}
	}

	private func automaticMarkerAngle(incoming: Point?, outgoing: Point?) -> Double {
		switch (incoming?.normalizedDirection, outgoing?.normalizedDirection) {
		case (.some(let incoming), .some(let outgoing)):
			let combined = incoming + outgoing
			guard combined.length > 0.000001 else { return atan2(outgoing.y, outgoing.x) }
			return atan2(combined.y, combined.x)
		case (.some(let incoming), .none):
			return atan2(incoming.y, incoming.x)
		case (.none, .some(let outgoing)):
			return atan2(outgoing.y, outgoing.x)
		case (.none, .none):
			return 0
		}
	}

	private func markerSubpaths(for path: Path) -> [SVGRenderMarkerSubpath] {
		var subpaths: [SVGRenderMarkerSubpath] = []
		var segments: [SVGRenderPathSegment] = []
		var currentPoint: Point?
		var subpathStart: Point?

		func finishSubpath() {
			if !segments.isEmpty {
				subpaths.append(SVGRenderMarkerSubpath(segments: segments))
				segments = []
			}
		}

		func appendSegment(to end: Point, startDirection: Point, endDirection: Point) {
			guard let start = currentPoint else {
				currentPoint = end
				return
			}
			guard start.distance(to: end) > 0.000001 else {
				currentPoint = end
				return
			}
			segments.append(SVGRenderPathSegment(start: start, end: end, startDirection: startDirection, endDirection: endDirection))
			currentPoint = end
		}

		for command in path.commands {
			switch command {
			case .move(let point):
				finishSubpath()
				currentPoint = point
				subpathStart = point
			case .line(let point):
				let direction = point - (currentPoint ?? point)
				appendSegment(to: point, startDirection: direction, endDirection: direction)
			case .cubic(let point, let control1, let control2):
				let start = currentPoint ?? control1
				appendSegment(to: point, startDirection: nonzeroDirection(control1 - start, fallback: point - start), endDirection: nonzeroDirection(point - control2, fallback: point - start))
			case .quad(let point, let control):
				let start = currentPoint ?? control
				appendSegment(to: point, startDirection: nonzeroDirection(control - start, fallback: point - start), endDirection: nonzeroDirection(point - control, fallback: point - start))
			case .arc(let center, let radius, let startAngle, let endAngle, let clockwise):
				let start = Point(center.x + cos(startAngle) * radius, center.y + sin(startAngle) * radius)
				if currentPoint == nil {
					currentPoint = start
					subpathStart = start
				}
				let end = Point(center.x + cos(endAngle) * radius, center.y + sin(endAngle) * radius)
				appendSegment(to: end, startDirection: arcDirection(radiusX: radius, radiusY: radius, angle: startAngle, clockwise: clockwise), endDirection: arcDirection(radiusX: radius, radiusY: radius, angle: endAngle, clockwise: clockwise))
			case .ellipticalArc(let center, let radiusX, let radiusY, let startAngle, let endAngle, let clockwise):
				let start = Point(center.x + cos(startAngle) * radiusX, center.y + sin(startAngle) * radiusY)
				if currentPoint == nil {
					currentPoint = start
					subpathStart = start
				}
				let end = Point(center.x + cos(endAngle) * radiusX, center.y + sin(endAngle) * radiusY)
				appendSegment(to: end, startDirection: arcDirection(radiusX: radiusX, radiusY: radiusY, angle: startAngle, clockwise: clockwise), endDirection: arcDirection(radiusX: radiusX, radiusY: radiusY, angle: endAngle, clockwise: clockwise))
			case .close:
				if let subpathStart, let currentPoint {
					let direction = subpathStart - currentPoint
					appendSegment(to: subpathStart, startDirection: direction, endDirection: direction)
				}
			case .rect(let rect):
				appendRectMarkerSegments(rect)
			case .ellipse(let rect):
				appendEllipseMarkerSegments(rect)
			case .roundedRect(let rect, _, _):
				appendRectMarkerSegments(rect)
			}
		}
		finishSubpath()
		return subpaths

		func appendRectMarkerSegments(_ rect: Rect) {
			guard rect.width > 0, rect.height > 0 else { return }
			finishSubpath()
			let points = [rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft]
			currentPoint = points[0]
			subpathStart = points[0]
			for point in points.dropFirst() {
				let direction = point - (currentPoint ?? point)
				appendSegment(to: point, startDirection: direction, endDirection: direction)
			}
			if let subpathStart, let currentPoint {
				let direction = subpathStart - currentPoint
				appendSegment(to: subpathStart, startDirection: direction, endDirection: direction)
			}
			finishSubpath()
			currentPoint = nil
			subpathStart = nil
		}

		func appendEllipseMarkerSegments(_ rect: Rect) {
			guard rect.width > 0, rect.height > 0 else { return }
			finishSubpath()
			let center = rect.center
			let radiusX = rect.width / 2
			let radiusY = rect.height / 2
			let angles: [Double] = [0, .pi / 2, .pi, .pi * 3 / 2, .pi * 2]
			currentPoint = Point(center.x + radiusX, center.y)
			subpathStart = currentPoint
			for index in 1..<angles.count {
				let angle = angles[index]
				let previousAngle = angles[index - 1]
				let end = Point(center.x + cos(angle) * radiusX, center.y + sin(angle) * radiusY)
				appendSegment(to: end, startDirection: arcDirection(radiusX: radiusX, radiusY: radiusY, angle: previousAngle, clockwise: true), endDirection: arcDirection(radiusX: radiusX, radiusY: radiusY, angle: angle, clockwise: true))
			}
			finishSubpath()
			currentPoint = nil
			subpathStart = nil
		}
	}

	private func nonzeroDirection(_ direction: Point, fallback: Point) -> Point {
		direction.length > 0.000001 ? direction : fallback
	}

	private func arcDirection(radiusX: Double, radiusY: Double, angle: Double, clockwise: Bool) -> Point {
		let direction = Point(-sin(angle) * radiusX, cos(angle) * radiusY)
		return clockwise ? direction : Point(-direction.x, -direction.y)
	}

	private func render(text data: SVGTextData, inheritedOpacity: Double, in context: inout GraphicsContext) {
		guard data.attributes.canRender else { return }
		context.drawLayer { layer in
			layer.concatenate(data.attributes.transform.cgAffineTransform)
			let textBounds = bounds(for: data)
			applyClip(attributes: data.attributes, bounds: textBounds, in: &layer)
			drawMasked(attributes: data.attributes, bounds: textBounds, in: &layer) { maskedLayer in
				let runs = textRuns(for: data, inheritedOpacity: inheritedOpacity, in: &maskedLayer)
				for run in runs {
					var resolved = maskedLayer.resolve(SwiftUI.Text(run.text).font(run.font))
					let runBounds = Rect(x: run.x, y: run.y - Double(run.baseline), width: Double(run.size.width), height: Double(run.size.height))
					guard let shading = shading(from: run.attributes.fill, currentColor: run.attributes.color, opacity: run.opacity * run.attributes.fillOpacity, bounds: runBounds) else { continue }
					resolved.shading = shading
					maskedLayer.draw(resolved, in: CGRect(x: run.x, y: run.y - Double(run.baseline), width: Double(run.size.width), height: Double(run.size.height)))
				}
			}
		}
	}

	private func textRuns(for data: SVGTextData, inheritedOpacity: Double, in context: inout GraphicsContext) -> [SVGRenderTextRun] {
		var runs: [SVGRenderTextRun] = []
		var currentX = data.x + (data.dxValues.first ?? 0)
		var currentY = data.y + (data.dyValues.first ?? 0)
		let rootOpacity = inheritedOpacity * data.attributes.opacity

		for span in data.spans {
			guard span.textPath == nil else { continue }
			let attributes = span.attributes ?? data.attributes
			let spanOpacity = span.attributes?.opacity ?? 1
			guard attributes.canRender else { continue }
			let fontSize = span.fontSize ?? data.fontSize
			let font = textFont(family: data.fontFamily, size: fontSize, weight: span.fontWeight ?? data.fontWeight)
			let text = SwiftUI.Text(span.text).font(font)
			let resolved = context.resolve(text)
			let size = resolved.measure(in: CGSize(width: 10_000, height: 10_000))
			guard size.width > 0, size.height > 0 else { continue }
			let baseline = resolved.firstBaseline(in: size)
			let x = (span.x ?? currentX) + span.dx
			let y = (span.y ?? currentY) + span.dy
			runs.append(SVGRenderTextRun(
				text: span.text,
				x: x,
				y: y,
				size: size,
				baseline: baseline,
				font: font,
				attributes: attributes,
				opacity: rootOpacity * spanOpacity
			))
			currentX = x + Double(size.width)
			currentY = y
		}

		guard !runs.isEmpty else { return [] }
		let lineWidth = runs.reduce(0) { max($0, ($1.x + Double($1.size.width)) - runs[0].x) }
		let offset: Double
		switch data.textAnchor {
		case .start:
			offset = 0
		case .middle:
			offset = -lineWidth / 2
		case .end:
			offset = -lineWidth
		}
		guard offset != 0 else { return runs }
		return runs.map { run in
			var adjusted = run
			adjusted.x += offset
			return adjusted
		}
	}

	private func textFont(family: String, size: Double, weight: String) -> SwiftUI.Font {
		let fontWeight = textFontWeight(from: weight)
		if family.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			return .system(size: CGFloat(size), weight: fontWeight)
		}
		return .custom(family, fixedSize: CGFloat(size)).weight(fontWeight)
	}

	private func textFontWeight(from value: String) -> SwiftUI.Font.Weight {
		switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
		case "100", "ultralight":
			return .ultraLight
		case "200", "thin":
			return .thin
		case "300", "light":
			return .light
		case "500", "medium":
			return .medium
		case "600", "semibold", "demibold":
			return .semibold
		case "700", "bold", "bolder":
			return .bold
		case "800", "heavy", "extra-bold", "extrabold":
			return .heavy
		case "900", "black":
			return .black
		default:
			return .regular
		}
	}

	private func drawMasked(attributes: SVGPaintAttributes, bounds: Rect?, in context: inout GraphicsContext, draw: (inout GraphicsContext) -> Void) {
		guard let maskID = attributes.maskID else {
			draw(&context)
			return
		}
		let referenceID = maskID.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
		guard let definition = document.defs.masks[referenceID], let region = maskRegion(for: definition, bounds: bounds) else {
			draw(&context)
			return
		}

		context.drawLayer { maskedLayer in
			maskedLayer.clipToLayer { maskLayer in
				maskLayer.addFilter(.luminanceToAlpha)
				maskLayer.drawLayer { sourceLayer in
					sourceLayer.clip(to: SwiftUI.Path(Path(commands: [.rect(region)]).cgPath))
					if definition.maskContentUnits == .objectBoundingBox {
						guard let bounds, bounds.width > 0, bounds.height > 0 else { return }
						sourceLayer.concatenate(Transform.identity.translatedBy(x: bounds.x, y: bounds.y).scaledBy(x: bounds.width, y: bounds.height).cgAffineTransform)
					}
					for child in definition.children {
						render(child, opacity: 1, in: &sourceLayer)
					}
				}
			}
			draw(&maskedLayer)
		}
	}

	private func maskRegion(for definition: SVGMaskDef, bounds: Rect?) -> Rect? {
		let region: Rect
		switch definition.maskUnits {
		case .userSpaceOnUse:
			region = Rect(x: definition.x, y: definition.y, width: definition.width, height: definition.height)
		case .objectBoundingBox:
			guard let bounds, bounds.width > 0, bounds.height > 0 else { return nil }
			region = Rect(
				x: bounds.x + definition.x * bounds.width,
				y: bounds.y + definition.y * bounds.height,
				width: definition.width * bounds.width,
				height: definition.height * bounds.height
			)
		}
		guard region.width > 0, region.height > 0 else { return nil }
		return region
	}

	private func applyClip(attributes: SVGPaintAttributes, bounds: Rect?, in context: inout GraphicsContext) {
		guard let clip = clipPath(from: attributes.clipPath, bounds: bounds) else { return }
		context.clip(to: SwiftUI.Path(clip.path), style: FillStyle(eoFill: clip.fillRule == .evenOdd))
	}

	private func clipPath(from value: SVGClipPathValue, bounds: Rect?) -> SVGRenderClipPath? {
		switch value {
		case .none, .basicShape:
			return nil
		case .url(let id):
			let referenceID = id.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
			guard let definition = document.defs.clipPathDefinitions[referenceID] else { return nil }
			return clipPath(from: definition, bounds: bounds)
		case .geometryBox(let box):
			return clipPath(from: box, bounds: bounds)
		}
	}

	private func clipPath(from definition: SVGClipPathDef, bounds: Rect?) -> SVGRenderClipPath? {
		let rootTransform: Transform
		switch definition.units {
		case .userSpaceOnUse:
			rootTransform = .identity
		case .objectBoundingBox:
			guard let bounds, bounds.width > 0, bounds.height > 0 else { return nil }
			rootTransform = Transform.identity.translatedBy(x: bounds.x, y: bounds.y).scaledBy(x: bounds.width, y: bounds.height)
		}

		let path = CGMutablePath()
		let fillRule = appendClipPathElements(definition.children, transform: rootTransform, to: path)
		guard !path.isEmpty else { return nil }
		return SVGRenderClipPath(path: path, fillRule: fillRule)
	}

	private func clipPath(from box: SVGGeometryBox, bounds: Rect?) -> SVGRenderClipPath? {
		let rect: Rect?
		switch box {
		case .viewBox:
			rect = document.viewBox
		case .contentBox, .paddingBox, .borderBox, .marginBox, .fillBox, .strokeBox:
			rect = bounds
		}
		guard let rect, rect.width > 0, rect.height > 0 else { return nil }
		return SVGRenderClipPath(path: Path(commands: [.rect(rect)]).cgPath, fillRule: .winding)
	}

	@discardableResult
	private func appendClipPathElements(_ elements: [SVGElement], transform: Transform, to path: CGMutablePath) -> FillRule {
		var fillRule = FillRule.winding
		for element in elements {
			let elementFillRule = appendClipPathElement(element, transform: transform, to: path)
			if elementFillRule == .evenOdd {
				fillRule = .evenOdd
			}
		}
		return fillRule
	}

	@discardableResult
	private func appendClipPathElement(_ element: SVGElement, transform: Transform, to path: CGMutablePath) -> FillRule {
		switch element {
		case .path(let data):
			appendClipPath(data.path.cgPath, attributes: data.attributes, transform: transform, to: path)
			return data.attributes.clipRule
		case .rect(let data):
			appendClipPath(data.path.cgPath, attributes: data.attributes, transform: transform, to: path)
			return data.attributes.clipRule
		case .circle(let data):
			appendClipPath(data.path.cgPath, attributes: data.attributes, transform: transform, to: path)
			return data.attributes.clipRule
		case .ellipse(let data):
			appendClipPath(data.path.cgPath, attributes: data.attributes, transform: transform, to: path)
			return data.attributes.clipRule
		case .line(let data):
			appendClipPath(data.path.cgPath, attributes: data.attributes, transform: transform, to: path)
			return data.attributes.clipRule
		case .polygon(let data):
			appendClipPath(data.path.cgPath, attributes: data.attributes, transform: transform, to: path)
			return data.attributes.clipRule
		case .polyline(let data):
			appendClipPath(data.path.cgPath, attributes: data.attributes, transform: transform, to: path)
			return data.attributes.clipRule
		case .group(let data):
			guard data.attributes.canContributeToClip else { return .winding }
			return appendClipPathElements(data.children, transform: transform.concatenating(data.attributes.transform), to: path)
		case .switch(let data):
			guard data.attributes.canContributeToClip else { return .winding }
			return appendClipPathElements(data.children, transform: transform.concatenating(data.attributes.transform), to: path)
		case .link(let data):
			guard data.attributes.canContributeToClip else { return .winding }
			return appendClipPathElements(data.children, transform: transform.concatenating(data.attributes.transform), to: path)
		case .svg(let data):
			guard data.attributes.canContributeToClip else { return .winding }
			var viewportTransform = data.attributes.transform
			if let viewBox = data.viewBox, let transform = data.preserveAspectRatio.viewBoxTransform(
				from: viewBox,
				to: Rect(x: data.x, y: data.y, width: data.width, height: data.height)
			) {
				viewportTransform = viewportTransform.concatenating(transform)
			} else {
				viewportTransform = viewportTransform.translatedBy(x: data.x, y: data.y)
			}
			return appendClipPathElements(data.children, transform: transform.concatenating(viewportTransform), to: path)
		case .unknown(let data):
			guard data.attributes.canContributeToClip else { return .winding }
			return appendClipPathElements(data.children, transform: transform.concatenating(data.attributes.transform), to: path)
		case .foreignObject(let data):
			guard data.attributes.canContributeToClip else { return .winding }
			return appendClipPathElements(data.children, transform: transform.concatenating(data.attributes.transform), to: path)
		case .use(let data):
			return appendUseClipPath(data, transform: transform, to: path)
		case .image, .text:
			return .winding
		}
	}

	private func appendClipPath(_ cgPath: CGPath, attributes: SVGPaintAttributes, transform: Transform, to path: CGMutablePath) {
		guard attributes.canContributeToClip else { return }
		path.addPath(cgPath, transform: transform.concatenating(attributes.transform).cgAffineTransform)
	}

	private func appendUseClipPath(_ data: SVGUseData, transform: Transform, to path: CGMutablePath) -> FillRule {
		guard data.attributes.canContributeToClip else { return .winding }
		let referenceID = data.href.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
		let useTransform = transform.concatenating(data.attributes.transform.translatedBy(x: data.x, y: data.y))
		if let elements = document.defs.reusableElements[referenceID] {
			return appendClipPathElements(elements, transform: useTransform, to: path)
		}
		if let symbol = document.defs.symbols[referenceID] {
			var symbolTransform = Transform.identity
			if let viewBox = symbol.viewBox, let transform = symbol.preserveAspectRatio.viewBoxTransform(
				from: viewBox,
				to: Rect(x: symbol.x, y: symbol.y, width: data.width ?? symbol.width, height: data.height ?? symbol.height)
			) {
				symbolTransform = symbolTransform.concatenating(transform)
			}
			return appendClipPathElements(symbol.children, transform: useTransform.concatenating(symbolTransform), to: path)
		}
		return .winding
	}

	private func fill(path: SwiftUI.Path, bounds: Rect, paint: SVGPaint, currentColor: Color, opacity: Double, fillRule: FillRule, in context: inout GraphicsContext) {
		if let patternID = patternID(from: paint), let pattern = document.defs.patterns[patternID] {
			fill(path: path, bounds: bounds, pattern: pattern, opacity: opacity, fillRule: fillRule, in: &context)
		} else if let shading = shading(from: paint, currentColor: currentColor, opacity: opacity, bounds: bounds) {
			context.fill(path, with: shading, style: FillStyle(eoFill: fillRule == .evenOdd))
		}
	}

	private func fill(path: SwiftUI.Path, bounds: Rect, pattern: SVGPatternDef, opacity: Double, fillRule: FillRule, in context: inout GraphicsContext) {
		guard let tile = tileRect(for: pattern, bounds: bounds), tile.width > 0, tile.height > 0 else { return }
		context.drawLayer { layer in
			layer.clip(to: path, style: FillStyle(eoFill: fillRule == .evenOdd))
			layer.concatenate(pattern.patternTransform.cgAffineTransform)
			let startX = Int(floor((bounds.left - tile.right) / tile.width))
			let endX = Int(ceil((bounds.right - tile.left) / tile.width))
			let startY = Int(floor((bounds.top - tile.bottom) / tile.height))
			let endY = Int(ceil((bounds.bottom - tile.top) / tile.height))
			for column in startX...endX {
				for row in startY...endY {
					layer.drawLayer { tileLayer in
						tileLayer.concatenate(Transform.identity.translatedBy(
							x: tile.x + Double(column) * tile.width,
							y: tile.y + Double(row) * tile.height
						).cgAffineTransform)
						if let viewBox = pattern.viewBox, let transform = pattern.preserveAspectRatio.viewBoxTransform(
							from: viewBox,
							to: Rect(x: 0, y: 0, width: tile.width, height: tile.height)
						) {
							tileLayer.concatenate(transform.cgAffineTransform)
						} else if pattern.patternContentUnits == .objectBoundingBox {
							tileLayer.concatenate(Transform.identity.scaledBy(x: bounds.width, y: bounds.height).cgAffineTransform)
						}
						for child in pattern.children {
							render(child, opacity: opacity * pattern.attributes.opacity, in: &tileLayer)
						}
					}
				}
			}
		}
	}

	private func tileRect(for pattern: SVGPatternDef, bounds: Rect) -> Rect? {
		switch pattern.patternUnits {
		case .userSpaceOnUse:
			Rect(x: pattern.x, y: pattern.y, width: pattern.width, height: pattern.height)
		case .objectBoundingBox:
			Rect(
				x: bounds.x + pattern.x * bounds.width,
				y: bounds.y + pattern.y * bounds.height,
				width: pattern.width * bounds.width,
				height: pattern.height * bounds.height
			)
		}
	}

	private func shading(from paint: SVGPaint, currentColor: Color, opacity: Double, bounds: Rect) -> GraphicsContext.Shading? {
		switch paint {
		case .none, .contextFill, .contextStroke:
			return nil
		case .color(let color):
			return .color(swiftUIColor(from: color, opacity: opacity))
		case .currentColor:
			return .color(swiftUIColor(from: currentColor, opacity: opacity))
		case .url(let id):
			return paintServerShading(id: id, opacity: opacity, bounds: bounds)
		case .urlWithFallback(let id, let fallback):
			return paintServerShading(id: id, opacity: opacity, bounds: bounds) ?? shading(from: fallback, currentColor: currentColor, opacity: opacity, bounds: bounds)
		}
	}

	private func paintServerShading(id: String, opacity: Double, bounds: Rect) -> GraphicsContext.Shading? {
		let referenceID = id.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
		if let gradient = document.defs.linearGradients[referenceID] {
			return linearGradientShading(gradient, opacity: opacity, bounds: bounds)
		}
		if let gradient = document.defs.radialGradients[referenceID] {
			return radialGradientShading(gradient, opacity: opacity, bounds: bounds)
		}
		return nil
	}

	private func linearGradientShading(_ gradient: SVGLinearGradientDef, opacity: Double, bounds: Rect) -> GraphicsContext.Shading? {
		let stops = gradientStops(gradient.stops, opacity: opacity, padEndpoints: gradient.spreadMethod != .pad)
		guard let firstStop = stops.first else { return nil }
		let start = gradientPoint(x: gradient.x1, y: gradient.y1, units: gradient.gradientUnits, bounds: bounds)
			.applying(gradient.gradientTransform)
		let end = gradientPoint(x: gradient.x2, y: gradient.y2, units: gradient.gradientUnits, bounds: bounds)
			.applying(gradient.gradientTransform)
		guard let spread = spreadStops(stops, method: gradient.spreadMethod, lowerBound: linearGradientLowerBound(start: start, end: end, bounds: bounds), upperBound: linearGradientUpperBound(start: start, end: end, bounds: bounds)) else {
			return .color(firstStop.color)
		}
		let vector = end - start
		let spreadStart = start + vector * spread.lowerBound
		let spreadEnd = start + vector * spread.upperBound
		return .linearGradient(
			Gradient(stops: spread.stops),
			startPoint: spreadStart.cgPoint,
			endPoint: spreadEnd.cgPoint
		)
	}

	private func radialGradientShading(_ gradient: SVGRadialGradientDef, opacity: Double, bounds: Rect) -> GraphicsContext.Shading? {
		let stops = gradientStops(gradient.stops, opacity: opacity, padEndpoints: gradient.spreadMethod != .pad)
		guard let firstStop = stops.first else { return nil }
		let center = gradientPoint(x: gradient.cx, y: gradient.cy, units: gradient.gradientUnits, bounds: bounds)
			.applying(gradient.gradientTransform)
		let radius = gradientRadius(gradient.r, units: gradient.gradientUnits, bounds: bounds)
		let startRadius = gradientRadius(gradient.fr, units: gradient.gradientUnits, bounds: bounds)
		let radiusDelta = radius - startRadius
		guard let spread = spreadStops(stops, method: gradient.spreadMethod, lowerBound: 0, upperBound: radialGradientUpperBound(center: center, startRadius: startRadius, radiusDelta: radiusDelta, bounds: bounds)) else {
			return .color(firstStop.color)
		}
		return .radialGradient(
			Gradient(stops: spread.stops),
			center: center.cgPoint,
			startRadius: CGFloat(max(0, startRadius + spread.lowerBound * radiusDelta)),
			endRadius: CGFloat(max(0, startRadius + spread.upperBound * radiusDelta))
		)
	}

	private func gradientStops(_ stops: [SVGGradientStop], opacity: Double, padEndpoints: Bool = false) -> [GradientPaintStop] {
		var paintStops = stops.map { stop in
			GradientPaintStop(color: swiftUIColor(from: stop.color, opacity: opacity * stop.opacity), offset: stop.offset)
		}.sorted { $0.offset < $1.offset }
		if padEndpoints, let first = paintStops.first, first.offset > 0 {
			paintStops.insert(GradientPaintStop(color: first.color, offset: 0), at: 0)
		}
		if padEndpoints, let last = paintStops.last, last.offset < 1 {
			paintStops.append(GradientPaintStop(color: last.color, offset: 1))
		}
		return paintStops
	}

	private func spreadStops(_ stops: [GradientPaintStop], method: SVGGradientSpreadMethod, lowerBound: Double?, upperBound: Double?) -> SpreadGradientStops? {
		guard let lowerBound, let upperBound, lowerBound.isFinite, upperBound.isFinite, upperBound > lowerBound else { return nil }
		switch method {
		case .pad:
			return SpreadGradientStops(lowerBound: 0, upperBound: 1, stops: stops.map(\.gradientStop))
		case .repeat, .reflect:
			let firstCycle = floor(lowerBound)
			let lastCycle = ceil(upperBound)
			let cycleCount = Int(lastCycle - firstCycle)
			guard cycleCount > 0, cycleCount <= 512 else { return nil }
			let denominator = lastCycle - firstCycle
			let spreadStops = (0..<cycleCount).flatMap { cycleIndex in
				let cycle = firstCycle + Double(cycleIndex)
				let reflectedCycle = method == .reflect && Int(cycle) % 2 != 0
				let cycleStops = reflectedCycle ? Array(stops.reversed()) : stops
				return cycleStops.map { stop in
					let offset = reflectedCycle ? 1 - stop.offset : stop.offset
					return Gradient.Stop(color: stop.color, location: (cycle + offset - firstCycle) / denominator)
				}
			}.sorted { $0.location < $1.location }
			return SpreadGradientStops(lowerBound: firstCycle, upperBound: lastCycle, stops: spreadStops)
		}
	}

	private func gradientPoint(x: Double, y: Double, units: SVGGradientUnits, bounds: Rect) -> Point {
		switch units {
		case .userSpaceOnUse:
			Point(x, y)
		case .objectBoundingBox:
			Point(bounds.x + x * bounds.width, bounds.y + y * bounds.height)
		}
	}

	private func gradientRadius(_ radius: Double, units: SVGGradientUnits, bounds: Rect) -> Double {
		switch units {
		case .userSpaceOnUse:
			radius
		case .objectBoundingBox:
			radius * max(bounds.width, bounds.height)
		}
	}

	private func linearGradientLowerBound(start: Point, end: Point, bounds: Rect) -> Double? {
		linearGradientProjections(start: start, end: end, bounds: bounds)?.min()
	}

	private func linearGradientUpperBound(start: Point, end: Point, bounds: Rect) -> Double? {
		linearGradientProjections(start: start, end: end, bounds: bounds)?.max()
	}

	private func linearGradientProjections(start: Point, end: Point, bounds: Rect) -> [Double]? {
		let vector = end - start
		let lengthSquared = vector.x * vector.x + vector.y * vector.y
		guard lengthSquared > 0 else { return nil }
		return [bounds.topLeft, bounds.topRight, bounds.bottomRight, bounds.bottomLeft].map { point in
			let relative = point - start
			return (relative.x * vector.x + relative.y * vector.y) / lengthSquared
		}
	}

	private func radialGradientUpperBound(center: Point, startRadius: Double, radiusDelta: Double, bounds: Rect) -> Double? {
		guard radiusDelta > 0 else { return nil }
		return [bounds.topLeft, bounds.topRight, bounds.bottomRight, bounds.bottomLeft]
			.map { (max(0, $0.distance(to: center) - startRadius)) / radiusDelta }
			.max()
	}

	private func patternID(from paint: SVGPaint) -> String? {
		switch paint {
		case .url(let id), .urlWithFallback(let id, _):
			let referenceID = id.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
			return document.defs.patterns[referenceID] == nil ? nil : referenceID
		case .none, .color, .currentColor, .contextFill, .contextStroke:
			return nil
		}
	}

	private func swiftUIColor(from paint: SVGPaint, currentColor: Color, opacity: Double) -> SwiftUI.Color? {
		switch paint {
		case .none, .url, .contextFill, .contextStroke:
			return nil
		case .color(let color):
			return SwiftUI.Color(red: color.red, green: color.green, blue: color.blue, opacity: color.alpha * opacity)
		case .currentColor:
			return SwiftUI.Color(red: currentColor.red, green: currentColor.green, blue: currentColor.blue, opacity: currentColor.alpha * opacity)
		case .urlWithFallback(_, let fallback):
			return swiftUIColor(from: fallback, currentColor: currentColor, opacity: opacity)
		}
	}

	private func swiftUIColor(from color: Color, opacity: Double) -> SwiftUI.Color {
		SwiftUI.Color(red: color.red, green: color.green, blue: color.blue, opacity: color.alpha * opacity)
	}

	private func bounds(for elements: [SVGElement]) -> Rect? {
		bounds(for: elements, transform: .identity)
	}

	private func bounds(for elements: [SVGElement], transform: Transform) -> Rect? {
		elements.reduce(nil) { partial, element in
			partial.union(bounds(for: element, transform: transform))
		}
	}

	private func bounds(for element: SVGElement, transform: Transform) -> Rect? {
		switch element {
		case .path(let data):
			return bounds(for: data.path.cgPath, transform: transform.concatenating(data.attributes.transform))
		case .rect(let data):
			return bounds(for: data.path.cgPath, transform: transform.concatenating(data.attributes.transform))
		case .circle(let data):
			return bounds(for: data.path.cgPath, transform: transform.concatenating(data.attributes.transform))
		case .ellipse(let data):
			return bounds(for: data.path.cgPath, transform: transform.concatenating(data.attributes.transform))
		case .line(let data):
			return bounds(for: data.path.cgPath, transform: transform.concatenating(data.attributes.transform))
		case .polygon(let data):
			return bounds(for: data.path.cgPath, transform: transform.concatenating(data.attributes.transform))
		case .polyline(let data):
			return bounds(for: data.path.cgPath, transform: transform.concatenating(data.attributes.transform))
		case .group(let data):
			return bounds(for: data.children, transform: transform.concatenating(data.attributes.transform))
		case .switch(let data):
			return bounds(for: data.children, transform: transform.concatenating(data.attributes.transform))
		case .link(let data):
			return bounds(for: data.children, transform: transform.concatenating(data.attributes.transform))
		case .svg(let data):
			let viewport = Rect(x: data.x, y: data.y, width: data.width, height: data.height)
			return bounds(for: Path(commands: [.rect(viewport)]).cgPath, transform: transform.concatenating(data.attributes.transform))
		case .unknown(let data):
			return bounds(for: data.children, transform: transform.concatenating(data.attributes.transform))
		case .foreignObject(let data):
			return bounds(for: data.children, transform: transform.concatenating(data.attributes.transform))
		case .use(let data):
			return bounds(for: data, transform: transform)
		case .image(let data):
			let imageBounds = Path(commands: [.rect(Rect(x: data.x, y: data.y, width: data.width, height: data.height))]).cgPath
			return bounds(for: imageBounds, transform: transform.concatenating(data.attributes.transform))
		case .text(let data):
			return bounds(for: data, transform: transform.concatenating(data.attributes.transform))
		}
	}

	private func bounds(for data: SVGTextData, transform: Transform = .identity) -> Rect? {
		let text = data.spans.filter { $0.textPath == nil }.map(\.text).joined()
		guard !text.isEmpty else { return nil }
		let width = max(1, Double(text.count) * data.fontSize * 0.62)
		let height = max(1, data.fontSize * 1.25)
		let xOffset: Double
		switch data.textAnchor {
		case .start:
			xOffset = 0
		case .middle:
			xOffset = -width / 2
		case .end:
			xOffset = -width
		}
		let bounds = CGRect(x: data.x + xOffset, y: data.y - data.fontSize, width: width, height: height)
			.applying(transform.cgAffineTransform)
		guard bounds.width > 0, bounds.height > 0 else { return nil }
		return Rect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: bounds.height)
	}

	private func bounds(for data: SVGUseData, transform: Transform = .identity) -> Rect? {
		let referenceID = data.href.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
		let useTransform = transform.concatenating(data.attributes.transform.translatedBy(x: data.x, y: data.y))
		if let elements = document.defs.reusableElements[referenceID] {
			return bounds(for: elements, transform: useTransform)
		}
		if let symbol = document.defs.symbols[referenceID] {
			let width = data.width ?? symbol.width
			let height = data.height ?? symbol.height
			if let viewBox = symbol.viewBox, let symbolTransform = symbol.preserveAspectRatio.viewBoxTransform(
				from: viewBox,
				to: Rect(x: symbol.x, y: symbol.y, width: width, height: height)
			) {
				return bounds(for: symbol.children, transform: useTransform.concatenating(symbolTransform))
			}
			return bounds(for: symbol.children, transform: useTransform)
		}
		return nil
	}

	private func bounds(for cgPath: CGPath, transform: Transform) -> Rect? {
		let bounds = cgPath.boundingBoxOfPath.applying(transform.cgAffineTransform)
		guard bounds.width > 0, bounds.height > 0 else { return nil }
		return Rect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: bounds.height)
	}
}

/// A native SwiftUI gradient stop prepared from an SVG `<stop>` element.
private struct GradientPaintStop {
	var color: SwiftUI.Color
	var offset: Double

	var gradientStop: Gradient.Stop {
		Gradient.Stop(color: color, location: offset)
	}
}

/// A synthesized stop list and coordinate span for a spread gradient.
private struct SpreadGradientStops {
	var lowerBound: Double
	var upperBound: Double
	var stops: [Gradient.Stop]
}

/// A prepared native clipping path and the winding rule SwiftUI should use for it.
private struct SVGRenderClipPath {
	var path: CGPath
	var fillRule: FillRule
}

/// A marker instance prepared for rendering at a path vertex.
private struct SVGRenderMarkerPlacement {
	var definition: SVGMarkerDef
	var point: Point
	var angle: Double
	var strokeWidth: Double
}

/// A marker-relevant subpath split into drawable path segments.
private struct SVGRenderMarkerSubpath {
	var segments: [SVGRenderPathSegment]
}

/// A drawable path segment with endpoint tangent directions.
private struct SVGRenderPathSegment {
	var start: Point
	var end: Point
	var startDirection: Point
	var endDirection: Point
}

/// A measured native text run prepared for drawing through `GraphicsContext`.
private struct SVGRenderTextRun {
	var text: String
	var x: Double
	var y: Double
	var size: CGSize
	var baseline: CGFloat
	var font: SwiftUI.Font
	var attributes: SVGPaintAttributes
	var opacity: Double
}

private extension Rect {
	var aspectRatio: CGFloat? {
		guard width > 0, height > 0 else { return nil }
		return CGFloat(width / height)
	}

	func union(_ other: Rect?) -> Rect {
		guard let other else { return self }
		let minX = min(left, other.left)
		let minY = min(top, other.top)
		let maxX = max(right, other.right)
		let maxY = max(bottom, other.bottom)
		return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
	}
}

private extension Point {
	var length: Double {
		hypot(x, y)
	}

	var normalizedDirection: Point? {
		let length = length
		guard length > 0.000001 else { return nil }
		return Point(x / length, y / length)
	}
}

private extension Optional where Wrapped == Rect {
	func union(_ other: Rect?) -> Rect? {
		switch (self, other) {
		case (.some(let lhs), .some(let rhs)):
			return lhs.union(rhs)
		case (.some(let lhs), .none):
			return lhs
		case (.none, .some(let rhs)):
			return rhs
		case (.none, .none):
			return nil
		}
	}
}

private extension SVGPaintAttributes {
	var canRender: Bool {
		display != .none && visibility == .visible && opacity > 0
	}

	var canContributeToClip: Bool {
		display != .none
	}
}

private extension CGPath {
	var svgBounds: Rect {
		let bounds = boundingBoxOfPath
		return Rect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: bounds.height)
	}
}
