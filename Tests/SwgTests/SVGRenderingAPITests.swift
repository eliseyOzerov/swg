import CoreGraphics
import SwiftUI
import Testing
@testable import Swg

@Test func svgPathConvertsToCoreGraphicsPath() {
	let path = SVGRectData(id: "box", x: 2, y: 3, width: 10, height: 12, rx: 0, ry: 0, attributes: .defaults).path
	let cgPath = path.cgPath

	#expect(cgPath.boundingBox == CGRect(x: 2, y: 3, width: 10, height: 12))
}

@Test func svgGeometryConvertsToCoreGraphicsTypes() {
	let point = Point(3, 4)
	let rect = Rect(x: 1, y: 2, width: 5, height: 8)
	let transform = Transform.identity.translatedBy(x: 7, y: 9)

	#expect(point.cgPoint == CGPoint(x: 3, y: 4))
	#expect(rect.cgRect == CGRect(x: 1, y: 2, width: 5, height: 8))
	#expect(CGPoint(x: 1, y: 1).applying(transform.cgAffineTransform) == CGPoint(x: 8, y: 10))
}

@Test func svgCanBeCreatedFromDocumentOrSource() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
		<circle id="dot" cx="12" cy="12" r="4" fill="red"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let documentView = SVG(document, options: SVGRenderOptions(opacity: 0.8))
	let sourceView = try #require(SVG(source: svg))

	#expect(documentView.document.viewBox == Rect(x: 0, y: 0, width: 24, height: 24))
	#expect(documentView.options.opacity == 0.8)
	#expect(sourceView.document.elementIDs == ["dot"])
}
