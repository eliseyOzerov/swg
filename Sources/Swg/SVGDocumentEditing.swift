import Foundation

public extension SVGDocument {
	/// Returns the first element in the document tree with the requested SVG `id`.
	///
	/// - Parameter id: The SVG `id` attribute to find.
	func element(id: String) -> SVGElement? {
		elements.firstNonNil { $0.element(id: id) }
	}

	/// Returns a copy of the document with every element transformed recursively.
	///
	/// - Parameter transform: A closure that receives each element after its descendants have been transformed.
	func mapElements(_ transform: (SVGElement) -> SVGElement) -> SVGDocument {
		var copy = self
		copy.elements = elements.map { $0.recursivelyMapping(transform) }
		return copy
	}

	/// Mutates the document by transforming every element recursively.
	///
	/// - Parameter transform: A closure that receives each element after its descendants have been transformed.
	mutating func updateElements(_ transform: (SVGElement) -> SVGElement) {
		self = mapElements(transform)
	}

	/// Returns a copy of the document with the element matching `id` transformed.
	///
	/// - Parameters:
	///   - id: The SVG `id` attribute of the element to transform.
	///   - modify: A closure that receives the matching element and returns its replacement.
	func modifyingElement(id: String, _ modify: (SVGElement) -> SVGElement) -> SVGDocument {
		mapElements { element in
			element.elementID == id ? modify(element) : element
		}
	}
}

public extension SVGElement {
	/// The parsed SVG `id` for this element.
	var elementID: String {
		switch self {
		case .path(let data):
			return data.id
		case .rect(let data):
			return data.id
		case .circle(let data):
			return data.id
		case .ellipse(let data):
			return data.id
		case .line(let data):
			return data.id
		case .polygon(let data):
			return data.id
		case .polyline(let data):
			return data.id
		case .group(let data):
			return data.id
		case .switch(let data):
			return data.id
		case .link(let data):
			return data.id
		case .svg(let data):
			return data.id
		case .unknown(let data):
			return data.id
		case .use(let data):
			return data.id
		case .image(let data):
			return data.id
		case .foreignObject(let data):
			return data.id
		case .text(let data):
			return data.id
		}
	}

	/// Returns the paint attributes carried by this element, when it has presentation state.
	var attributes: SVGPaintAttributes? {
		switch self {
		case .path(let data):
			return data.attributes
		case .rect(let data):
			return data.attributes
		case .circle(let data):
			return data.attributes
		case .ellipse(let data):
			return data.attributes
		case .line(let data):
			return data.attributes
		case .polygon(let data):
			return data.attributes
		case .polyline(let data):
			return data.attributes
		case .group(let data):
			return data.attributes
		case .switch(let data):
			return data.attributes
		case .link(let data):
			return data.attributes
		case .svg(let data):
			return data.attributes
		case .unknown(let data):
			return data.attributes
		case .use(let data):
			return data.attributes
		case .image(let data):
			return data.attributes
		case .foreignObject(let data):
			return data.attributes
		case .text(let data):
			return data.attributes
		}
	}

	/// Returns the first element in this subtree with the requested SVG `id`.
	///
	/// - Parameter id: The SVG `id` attribute to find.
	func element(id: String) -> SVGElement? {
		if elementID == id {
			return self
		}
		return children.firstNonNil { $0.element(id: id) }
	}

	/// Returns a copy of the element with its paint attributes edited.
	///
	/// - Parameter modify: A closure that edits the element's presentation attributes.
	func modifyingAttributes(_ modify: (inout SVGPaintAttributes) -> Void) -> SVGElement {
		guard var attributes else { return self }
		modify(&attributes)
		return withAttributes(attributes)
	}
}

private extension SVGElement {
	var children: [SVGElement] {
		switch self {
		case .group(let data):
			return data.children
		case .switch(let data):
			return data.children
		case .link(let data):
			return data.children
		case .svg(let data):
			return data.children
		case .unknown(let data):
			return data.children
		case .foreignObject(let data):
			return data.children
		default:
			return []
		}
	}

	func recursivelyMapping(_ transform: (SVGElement) -> SVGElement) -> SVGElement {
		transform(withChildren(children.map { $0.recursivelyMapping(transform) }))
	}

	func withChildren(_ children: [SVGElement]) -> SVGElement {
		switch self {
		case .group(let data):
			return .group(SVGGroupData(id: data.id, attributes: data.attributes, children: children, language: data.language, unknownAttributes: data.unknownAttributes))
		case .switch(let data):
			return .switch(SVGSwitchData(id: data.id, attributes: data.attributes, children: children, language: data.language, unknownAttributes: data.unknownAttributes))
		case .link(let data):
			return .link(SVGLinkData(id: data.id, href: data.href, target: data.target, download: data.download, ping: data.ping, rel: data.rel, hreflang: data.hreflang, type: data.type, referrerPolicy: data.referrerPolicy, xlinkTitle: data.xlinkTitle, attributes: data.attributes, children: children, language: data.language, unknownAttributes: data.unknownAttributes))
		case .svg(let data):
			return .svg(SVGViewportData(id: data.id, x: data.x, y: data.y, width: data.width, height: data.height, viewBox: data.viewBox, preserveAspectRatio: data.preserveAspectRatio, attributes: data.attributes, children: children, language: data.language, unknownAttributes: data.unknownAttributes))
		case .unknown(let data):
			return .unknown(SVGUnknownElementData(id: data.id, name: data.name, namespaceURI: data.namespaceURI, attributes: data.attributes, children: children, language: data.language, unknownAttributes: data.unknownAttributes))
		case .foreignObject(let data):
			return .foreignObject(SVGForeignObjectData(id: data.id, x: data.x, y: data.y, width: data.width, height: data.height, attributes: data.attributes, children: children, language: data.language, unknownAttributes: data.unknownAttributes))
		default:
			return self
		}
	}

	func withAttributes(_ attributes: SVGPaintAttributes) -> SVGElement {
		switch self {
		case .path(let data):
			return .path(SVGPathData(id: data.id, d: data.d, attributes: attributes, language: data.language, unknownAttributes: data.unknownAttributes))
		case .rect(let data):
			return .rect(SVGRectData(id: data.id, x: data.x, y: data.y, width: data.width, height: data.height, rx: data.rx, ry: data.ry, attributes: attributes, rxIsAuto: data.rxIsAuto, ryIsAuto: data.ryIsAuto, language: data.language, unknownAttributes: data.unknownAttributes))
		case .circle(let data):
			return .circle(SVGCircleData(id: data.id, cx: data.cx, cy: data.cy, r: data.r, attributes: attributes, language: data.language, unknownAttributes: data.unknownAttributes))
		case .ellipse(let data):
			return .ellipse(SVGEllipseData(id: data.id, cx: data.cx, cy: data.cy, rx: data.rx, ry: data.ry, attributes: attributes, rxIsAuto: data.rxIsAuto, ryIsAuto: data.ryIsAuto, language: data.language, unknownAttributes: data.unknownAttributes))
		case .line(let data):
			return .line(SVGLineData(id: data.id, x1: data.x1, y1: data.y1, x2: data.x2, y2: data.y2, attributes: attributes, language: data.language, unknownAttributes: data.unknownAttributes))
		case .polygon(let data):
			return .polygon(SVGPolygonData(id: data.id, points: data.points, attributes: attributes, language: data.language, unknownAttributes: data.unknownAttributes))
		case .polyline(let data):
			return .polyline(SVGPolylineData(id: data.id, points: data.points, attributes: attributes, language: data.language, unknownAttributes: data.unknownAttributes))
		case .group(let data):
			return .group(SVGGroupData(id: data.id, attributes: attributes, children: data.children, language: data.language, unknownAttributes: data.unknownAttributes))
		case .switch(let data):
			return .switch(SVGSwitchData(id: data.id, attributes: attributes, children: data.children, language: data.language, unknownAttributes: data.unknownAttributes))
		case .link(let data):
			return .link(SVGLinkData(id: data.id, href: data.href, target: data.target, download: data.download, ping: data.ping, rel: data.rel, hreflang: data.hreflang, type: data.type, referrerPolicy: data.referrerPolicy, xlinkTitle: data.xlinkTitle, attributes: attributes, children: data.children, language: data.language, unknownAttributes: data.unknownAttributes))
		case .svg(let data):
			return .svg(SVGViewportData(id: data.id, x: data.x, y: data.y, width: data.width, height: data.height, viewBox: data.viewBox, preserveAspectRatio: data.preserveAspectRatio, attributes: attributes, children: data.children, language: data.language, unknownAttributes: data.unknownAttributes))
		case .unknown(let data):
			return .unknown(SVGUnknownElementData(id: data.id, name: data.name, namespaceURI: data.namespaceURI, attributes: attributes, children: data.children, language: data.language, unknownAttributes: data.unknownAttributes))
		case .use(let data):
			return .use(SVGUseData(id: data.id, href: data.href, x: data.x, y: data.y, width: data.width, height: data.height, attributes: attributes, language: data.language, unknownAttributes: data.unknownAttributes))
		case .image(let data):
			return .image(SVGImageData(id: data.id, x: data.x, y: data.y, width: data.width, height: data.height, href: data.href, attributes: attributes, language: data.language, unknownAttributes: data.unknownAttributes))
		case .foreignObject(let data):
			return .foreignObject(SVGForeignObjectData(id: data.id, x: data.x, y: data.y, width: data.width, height: data.height, attributes: attributes, children: data.children, language: data.language, unknownAttributes: data.unknownAttributes))
		case .text(let data):
			return .text(SVGTextData(id: data.id, x: data.x, y: data.y, xValues: data.xValues, yValues: data.yValues, dxValues: data.dxValues, dyValues: data.dyValues, rotateValues: data.rotateValues, fontSize: data.fontSize, fontFamily: data.fontFamily, fontWeight: data.fontWeight, textAnchor: data.textAnchor, dominantBaseline: data.dominantBaseline, whiteSpace: data.whiteSpace, attributes: attributes, spans: data.spans, language: data.language, unknownAttributes: data.unknownAttributes))
		}
	}
}

private extension Sequence {
	func firstNonNil<Value>(_ transform: (Element) -> Value?) -> Value? {
		for element in self {
			if let value = transform(element) {
				return value
			}
		}
		return nil
	}
}
