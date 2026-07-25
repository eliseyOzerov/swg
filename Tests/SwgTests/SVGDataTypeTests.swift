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

@Test func svgLengthParserRejectsRelativePercentAndUppercaseUnitsForAbsoluteParsing() {
	#expect(SVGLengthParser.parse("10em") == nil)
	#expect(SVGLengthParser.parse("10ex") == nil)
	#expect(SVGLengthParser.parse("10rem") == nil)
	#expect(SVGLengthParser.parse("10vw") == nil)
	#expect(SVGLengthParser.parse("10%") == nil)
	#expect(SVGLengthParser.parse("10PX") == nil)
}
