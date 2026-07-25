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

@Test func svgParserHandlesDefaultNamespaceAndXLinkHref() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 10 10">
		<defs>
			<path id="symbolPath" d="M0 0 L1 1"/>
		</defs>
		<use id="copy" xlink:href="#symbolPath" x="2" y="3"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.viewBox == Rect(x: 0, y: 0, width: 10, height: 10))
	#expect(document.defs.reusableElements["symbolPath"]?.count == 1)

	guard case .use(let use) = document.elements.first else {
		Issue.record("Expected root element to be a use element")
		return
	}
	#expect(use.id == "copy")
	#expect(use.href == "symbolPath")
	#expect(use.x == 2)
	#expect(use.y == 3)
}

@Test func svgParserHandlesPrefixedSVGNamespaceAndHrefPrecedence() throws {
	let svg = """
	<svg:svg xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 16 16">
		<svg:defs>
			<svg:path id="preferred" d="M0 0 L2 2"/>
			<svg:path id="legacy" d="M1 1 L3 3"/>
		</svg:defs>
		<custom:path xmlns:custom="https://example.com/custom" id="foreign" d="M0 0 L9 9"/>
		<svg:use id="copy" href="#preferred" xlink:href="#legacy"/>
	</svg:svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.viewBox == Rect(x: 0, y: 0, width: 16, height: 16))
	#expect(document.defs.reusableElements["preferred"]?.count == 1)
	#expect(document.defs.reusableElements["legacy"]?.count == 1)
	#expect(document.elementIDs.contains("foreign") == false)

	guard case .use(let use) = document.elements.first else {
		Issue.record("Expected root element to be a use element")
		return
	}
	#expect(use.href == "preferred")
}
