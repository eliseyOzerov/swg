import Testing
@testable import Swg

@Test func svgParserBuildsDocumentFromFoundationXMLParser() throws {
	let svg = """
	<svg width="24" height="24" viewBox="0 0 24 24">
		<style>.accent { fill: #336699; stroke-width: 2; }</style>
		<defs>
			<linearGradient id="fade" x1="0%" y1="0%" x2="100%" y2="0%">
				<stop offset="0%" stop-color="red"/>
				<stop offset="100%" stop-color="blue" stop-opacity="0.5"/>
			</linearGradient>
		</defs>
		<g id="icon" transform="translate(2,3)">
			<path id="mark" class="accent" d="M0 0 L10 0 Z"/>
			<circle id="dot" cx="12" cy="12" r="4" fill="url(#fade)"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.viewBox == Rect(x: 0, y: 0, width: 24, height: 24))
	#expect(document.elementIDs == ["icon", "mark", "dot"])
	#expect(document.defs.linearGradients["fade"]?.stops.count == 2)

	guard case .group(let group) = document.elements.first else {
		Issue.record("Expected root element to be a group")
		return
	}
	#expect(group.attributes.transform == Transform.identity.translatedBy(x: 2, y: 3))

	guard case .path(let path) = group.children.first else {
		Issue.record("Expected first child to be a path")
		return
	}
	#expect(path.attributes.fill == .color(Color(0.2, 0.4, 0.6)))
	#expect(path.attributes.strokeWidth == 2)
}
