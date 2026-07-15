import Testing
@testable import Vois

@Suite struct TextPreprocessorTests {
    @Test func splitsSentences() {
        let s = TextPreprocessor.sentences(from: "Hello world. This is Vois! Does it work?")
        #expect(s.count == 3)
        #expect(s[0] == "Hello world.")
    }

    @Test func stripsMarkdownAndURLs() {
        let cleaned = TextPreprocessor.clean("See [the docs](https://example.com) at https://example.com/x **now**.")
        #expect(!cleaned.contains("http"))
        #expect(!cleaned.contains("*"))
        #expect(cleaned.contains("the docs"))
    }

    @Test func expandsAbbreviations() {
        let cleaned = TextPreprocessor.clean("Use tools, e.g. hammers.")
        #expect(cleaned.contains("for example"))
    }

    @Test func emptyInput() {
        #expect(TextPreprocessor.sentences(from: "   \n ") == [])
    }

    @Test func longSentenceChunked() {
        let long = (0..<60).map { "clause number \($0)" }.joined(separator: ", ") + "."
        let s = TextPreprocessor.sentences(from: long)
        #expect(s.count > 1)
        #expect(s.allSatisfy { $0.count <= 400 })
    }
}
