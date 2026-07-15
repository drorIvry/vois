import Foundation

/// Cleans captured text and splits it into speakable sentences (PRD §6 F12).
enum TextPreprocessor {
    static func sentences(from raw: String) -> [String] {
        let cleaned = clean(raw)
        guard !cleaned.isEmpty else { return [] }

        var result: [String] = []
        let tokenizer = NLTokenizerWrapper()
        for sentence in tokenizer.sentences(in: cleaned) {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            // Kokoro degrades on very long inputs; split oversized sentences on clause boundaries.
            if trimmed.count > 400 {
                result.append(contentsOf: splitLong(trimmed))
            } else {
                result.append(trimmed)
            }
        }
        return result
    }

    static func clean(_ raw: String) -> String {
        var text = raw

        // Markdown noise: images, links (keep link text), emphasis, headings, code fences.
        text = text.replacingOccurrences(of: #"!\[[^\]]*\]\([^)]*\)"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\[([^\]]+)\]\([^)]*\)"#, with: "$1", options: .regularExpression)
        text = text.replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: [.regularExpression])
        text = text.replacingOccurrences(of: #"```[\s\S]*?```"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"[*_`~]{1,3}"#, with: "", options: .regularExpression)

        // Bare URLs and emails.
        text = text.replacingOccurrences(of: #"(https?|ftp)://\S+"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\S+@\S+\.\S+"#, with: "", options: .regularExpression)

        // Common abbreviations that trip sentence splitting / sound wrong.
        let abbreviations: [(String, String)] = [
            ("e.g.", "for example"), ("i.e.", "that is"), ("etc.", "et cetera"),
            ("vs.", "versus"), ("approx.", "approximately"),
        ]
        for (abbr, expansion) in abbreviations {
            text = text.replacingOccurrences(of: abbr, with: expansion)
        }

        // Collapse whitespace.
        text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func splitLong(_ sentence: String) -> [String] {
        var chunks: [String] = []
        var current = ""
        for part in sentence.split(separator: ",", omittingEmptySubsequences: true) {
            if current.count + part.count > 300, !current.isEmpty {
                chunks.append(current.trimmingCharacters(in: .whitespaces))
                current = String(part)
            } else {
                current += current.isEmpty ? String(part) : ",\(part)"
            }
        }
        if !current.isEmpty { chunks.append(current.trimmingCharacters(in: .whitespaces)) }
        return chunks
    }
}

import NaturalLanguage

private struct NLTokenizerWrapper {
    func sentences(in text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        var out: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            out.append(String(text[range]))
            return true
        }
        return out
    }
}
