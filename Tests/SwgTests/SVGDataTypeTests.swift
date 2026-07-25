import Foundation
import Testing
@testable import Swg

@Test func svgIntegerParserParsesSignedDigitSequences() {
	#expect(SVGIntegerParser.parse("0") == 0)
	#expect(SVGIntegerParser.parse("42") == 42)
	#expect(SVGIntegerParser.parse("+42") == 42)
	#expect(SVGIntegerParser.parse("-42") == -42)
	#expect(SVGIntegerParser.parse(" 2147483647 ") == 2147483647)
	#expect(SVGIntegerParser.parse("-2147483648") == -2147483648)
}

@Test func svgIntegerParserRejectsNonIntegerSyntax() {
	#expect(SVGIntegerParser.parse("") == nil)
	#expect(SVGIntegerParser.parse("+") == nil)
	#expect(SVGIntegerParser.parse("1.0") == nil)
	#expect(SVGIntegerParser.parse("1e2") == nil)
	#expect(SVGIntegerParser.parse("10px") == nil)
	#expect(SVGIntegerParser.parse("1 2") == nil)
}

@Test func svgLengthParserParsesUnitlessLengthsAsUserUnits() {
	#expect(SVGLengthParser.parseUnitless("0") == 0)
	#expect(SVGLengthParser.parseUnitless("42") == 42)
	#expect(SVGLengthParser.parseUnitless(" +.5 ") == 0.5)
	#expect(SVGLengthParser.parseUnitless("-.25e2") == -25)
}

@Test func svgLengthParserRejectsUnitsForUnitlessLengthParsing() {
	#expect(SVGLengthParser.parseUnitless("") == nil)
	#expect(SVGLengthParser.parseUnitless("10px") == nil)
	#expect(SVGLengthParser.parseUnitless("10pt") == nil)
	#expect(SVGLengthParser.parseUnitless("10%") == nil)
	#expect(SVGLengthParser.parseUnitless("1 2") == nil)
}

@Test func svgLengthParserConvertsAbsoluteLengthUnitsToUserUnits() {
	#expect(SVGLengthParser.parse("5px") == 5)
	#expect(SVGLengthParser.parse("1in") == 96)
	#expect(SVGLengthParser.parse("72pt") == 96)
	#expect(SVGLengthParser.parse("6pc") == 96)
	#expect(SVGLengthParser.parse("2.54cm") == 96)
	#expect(SVGLengthParser.parse("25.4mm") == 96)
}

@Test func svgLengthParserConvertsFontRelativeUnitsToUserUnits() {
	let context = SVGLengthContext(fontSize: 20, rootFontSize: 18, xHeight: 9, zeroAdvance: 11)

	#expect(SVGLengthParser.parse("2em", context: context) == 40)
	#expect(SVGLengthParser.parse("2ex", context: context) == 18)
	#expect(SVGLengthParser.parse("2ch", context: context) == 22)
	#expect(SVGLengthParser.parse("2rem", context: context) == 36)
}

@Test func svgLengthParserUsesFontMetricFallbacksForExAndCh() {
	let horizontal = SVGLengthContext(fontSize: 20, rootFontSize: 16)
	let upright = SVGLengthContext(fontSize: 20, rootFontSize: 16, isUprightText: true)

	#expect(SVGLengthParser.parse("2ex", context: horizontal) == 20)
	#expect(SVGLengthParser.parse("2ch", context: horizontal) == 20)
	#expect(SVGLengthParser.parse("2ch", context: upright) == 40)
}

@Test func svgLengthParserConvertsViewportRelativeUnitsToUserUnits() {
	let context = SVGLengthContext(viewportWidth: 200, viewportHeight: 100)

	#expect(SVGLengthParser.parse("10vw", context: context) == 20)
	#expect(SVGLengthParser.parse("10vh", context: context) == 10)
	#expect(SVGLengthParser.parse("10vmin", context: context) == 10)
	#expect(SVGLengthParser.parse("10vmax", context: context) == 20)
}

@Test func svgLengthParserConvertsPercentageLengthsToUserUnits() throws {
	let context = SVGLengthContext(viewportWidth: 200, viewportHeight: 100)
	let diagonal = try #require(SVGLengthParser.parse("10%", context: context, percentageBasis: .normalizedDiagonal))

	#expect(SVGLengthParser.parse("50%", context: context, percentageBasis: .horizontal) == 100)
	#expect(SVGLengthParser.parse("50%", context: context, percentageBasis: .vertical) == 50)
	#expect(abs(diagonal - 15.811388300841898) < 0.000001)
	#expect(SVGLengthParser.parse("25%", context: context, percentageBasis: .custom(80)) == 20)
	#expect(SVGLengthParser.parse("50%") == 50)
}

@Test func svgLengthParserRejectsUppercaseUnitsAndMalformedPercentages() {
	#expect(SVGLengthParser.parse("10PX") == nil)
	#expect(SVGLengthParser.parse("10EM") == nil)
	#expect(SVGLengthParser.parse("10VW") == nil)
	#expect(SVGLengthParser.parse("%") == nil)
	#expect(SVGLengthParser.parse("10%%") == nil)
}
