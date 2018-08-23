/*
 * Copyright 2016-2018 JD Fergason
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

class Grammar {
    var grammar = [String: [Evaluator]]()

    init() {
        grammar["comment"] = commentEvaluators()
        grammar["string"] = stringEvaluators()
        grammar["literalString"] = literalStringEvaluators()
        grammar["multilineString"] = multiLineStringEvaluators()
        grammar["multilineLiteralString"] = multiLineStringLiteralEvaluators()
        grammar["tableName"] = tableNameEvaluators()
        grammar["tableArray"] = tableArrayEvaluators()
        grammar["value"] = valueEvaluators()
        grammar["array"] = arrayEvaluators()
        grammar["inlineTable"] = inlineTableEvaluators()
        grammar["root"] = rootEvaluators()
    }

    private func commentEvaluators() -> [Evaluator] {
        return [
            Evaluator(regex: "[\r\n]", generator: { _ in nil }, pop: true),
            // to enable saving comments in the tokenizer use the following line
            // Evaluator(regex: ".*", generator: { (r: String) in .Comment(r.trim()) }, pop: true)
            Evaluator(regex: ".*", generator: { _ in nil }, pop: true)
        ]
    }

    private func stringEvaluators() -> [Evaluator] {
        return [
            Evaluator(regex: "\"", generator: { _ in nil }, pop: true),
            Evaluator(regex: "([\\u0020-\\u0021\\u0023-\\u005B\\u005D-\\uFFFF]|\\\\\"|\\\\)+",
                generator: { (r: String) in .Identifier(try r.replaceEscapeSequences()) })
        ]
    }

    private func literalStringEvaluators() -> [Evaluator] {
        return [
            Evaluator(regex: "'", generator: { _ in nil }, pop: true),
            Evaluator(regex: "([\\u0020-\\u0026\\u0028-\\uFFFF])+",
                generator: { (r: String) in .Identifier(r) })
        ]
    }

    private func multiLineStringEvaluators() -> [Evaluator] {
        let validUnicodeChars = "\\u0020-\\u0021\\u0023-\\uFFFF"
        return [
            Evaluator(regex: "\"\"\"", generator: { _ in nil }, pop: true),
            // Note: Does not allow multi-line strings that end with double qoutes.
            // This is a common limitation of a variety of parsers I have tested
            Evaluator(regex: "([\n" + validUnicodeChars + "]\"?\"?)*[\n" + validUnicodeChars + "]+",
                generator: {
                    (r: String) in
                        .Identifier(try r.trim().stripLineContinuation().replaceEscapeSequences())
                }, multiline: true)
        ]
    }

    private func multiLineStringLiteralEvaluators() -> [Evaluator] {
        let validUnicodeChars = "\n\\u0020-\\u0026\\u0028-\\uFFFF"
        return [
            Evaluator(regex: "'''", generator: { _ in nil }, pop: true),
            Evaluator(regex: "([" + validUnicodeChars + "]'?'?)*[" + validUnicodeChars + "]+",
                generator: { (r: String) in .Identifier(r.trim()) }, multiline: true)
        ]
    }

    private func tableNameEvaluators() -> [Evaluator] {
        let tableErrorStr = "Invalid table name declaration"
        return [
            Evaluator(regex: "\"", generator: { _ in nil }, push: ["string"]),
            Evaluator(regex: "'", generator: { _ in nil }, push: ["literalString"]),
            Evaluator(regex: "\\.", generator: { _ in .TableSep }),
            // opening [ are prohibited directly within a table declaration
            Evaluator(regex: "\\[", generator: { _ in throw TomlError.SyntaxError(tableErrorStr) }),
            // hashes are prohibited directly within a table declaration
            Evaluator(regex: "#", generator: { _ in throw TomlError.SyntaxError(tableErrorStr) }),
            Evaluator(regex: "[A-Za-z0-9_-]+", generator: { (r: String) in .Identifier(r) }),
            Evaluator(regex: "\\]\\]", generator: { _ in .TableArrayEnd }, pop: true),
            Evaluator(regex: "\\]", generator: { _ in .TableEnd }, pop: true),
        ]
    }

    private func tableArrayEvaluators() -> [Evaluator] {
        let tableErrorStr = "Invalid table name declaration"
        return [
            Evaluator(regex: "\"", generator: { _ in nil }, push: ["string"]),
            Evaluator(regex: "'", generator: { _ in nil }, push: ["literalString"]),
            Evaluator(regex: "\\.", generator: { _ in .TableSep }),
            // opening [ are prohibited directly within a table declaration
            Evaluator(regex: "\\[", generator: { _ in throw TomlError.SyntaxError(tableErrorStr) }),
            // hashes are prohibited directly within a table declaration
            Evaluator(regex: "#", generator: { _ in throw TomlError.SyntaxError(tableErrorStr) }),
            Evaluator(regex: "[A-Za-z0-9_-]+", generator: { (r: String) in .Identifier(r) }),
            Evaluator(regex: "\\]\\]", generator: { _ in .TableArrayEnd }, pop: true),
        ]
    }

    private func dateValueEvaluators() -> [Evaluator] {
        let dateTimeStr = "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}"
        return [
            // Dates, RFC 3339 w/ fractional seconds and time offset
            Evaluator(regex: dateTimeStr + ".\\d+(Z|z|[-\\+]\\d{2}:\\d{2})", generator: {
                (r: String) in
                    if let date = Date(rfc3339String: r) {
                        return Token.DateTime(date)
                    } else {
                        throw TomlError.InvalidDateFormat("####-##-##T##:##:##.###+/-##:## (\(r))")
                    }
            }, pop: true),
            // RFC 3339 w/o fractional seconds and time offset
            Evaluator(regex: dateTimeStr + "(Z|z|[-\\+]\\d{2}:\\d{2})", generator: {
                (r: String) in
                    if let date = Date(rfc3339String: r, fractionalSeconds: false) {
                        return Token.DateTime(date)
                    } else {
                        throw TomlError.InvalidDateFormat("####-##-##T##:##:##+/-##:## (\(r))")
                    }
            }, pop: true),
            // Dates, RFC 3339 w/ fractional seconds and w/o time offset
            Evaluator(regex: dateTimeStr + ".\\d+", generator: { (r: String) in
                if let date = Date(rfc3339String: r, localTime: true) {
                    return Token.DateTime(date)
                } else {
                    throw TomlError.InvalidDateFormat("####-##-##T##:##:##.### (\(r))")
                }
            }, pop: true),
            // Dates, RFC 3339 w/o fractional seconds and w/o time offset
            Evaluator(regex: dateTimeStr, generator: { (r: String) in
                if let date = Date(rfc3339String: r, fractionalSeconds: false, localTime: true) {
                    return Token.DateTime(date)
                } else {
                    throw TomlError.InvalidDateFormat("####-##-##T##:##:## (\(r))")
                }
            }, pop: true),
            // Date only
            Evaluator(regex: "\\d{4}-\\d{2}-\\d{2}", generator: { (r: String) in
                if let date = Date(rfc3339String: r + "T00:00:00.0", localTime: true) {
                    return Token.DateTime(date)
                } else {
                    throw TomlError.InvalidDateFormat("####-##-## (\(r))")
                }
            }, pop: true)
        ]
    }

    private func stringValueEvaluators() -> [Evaluator] {
        return [
            // Multi-line string values (must come before single-line test)
            // Special case, empty multi-line string
            Evaluator(regex: "\"\"\"\"\"\"", generator: {_ in .Identifier("") }, pop: true),
            Evaluator(regex: "\"\"\"", generator: { _ in nil },
                push: ["multilineString"], pop: true),
            // Multi-line literal string values (must come before single-line test)
            Evaluator(regex: "'''", generator: { _ in nil },
                push: ["multilineLiteralString"], pop: true),
            // Special case, empty multi-line string literal
            Evaluator(regex: "''''''", generator: { _ in .Identifier("") },
                push: ["multilineLiteralString"], pop: true),
            // empty single line strings
            Evaluator(regex: "\"\"", generator: { _ in .Identifier("") }, pop: true),
            Evaluator(regex: "''", generator: { _ in .Identifier("") }, pop: true),
            // String values
            Evaluator(regex: "\"", generator: { _ in nil }, push: ["string"], pop: true),
            // Literal string values
            Evaluator(regex: "'", generator: { _ in nil }, push: ["literalString"], pop: true),
        ]
    }

    private func doubleValueEvaluators() -> [Evaluator] {
        let generator: TokenGenerator = { (val: String) in .DoubleNumber(Double(val)!) }
        return [
            // Double values with exponent
            Evaluator(regex: "[-\\+]?[0-9]+(\\.[0-9]+)?[eE][-\\+]?[0-9]+",
                generator: generator, pop:true),
            // Double values no exponent
            Evaluator(regex: "[-\\+]?[0-9]+\\.[0-9]+", generator: generator, pop: true),
        ]
    }

    private func intValueEvaluators() -> [Evaluator] {
        return [
            // Integer values
            Evaluator(regex: "[-\\+]?[0-9]+",
                generator: { (r: String) in .IntegerNumber(Int(r)!) }, pop: true),
        ]
    }

    private func booleanValueEvaluators() -> [Evaluator] {
        return [
            // Boolean values
            Evaluator(regex: "true", generator: { (r: String) in .Boolean(true) }, pop: true),
            Evaluator(regex: "false", generator: { (r: String) in .Boolean(false) }, pop: true),
        ]
    }

    private func whitespaceValueEvaluators() -> [Evaluator] {
        return [
            // Ignore white-space
            Evaluator(regex: "[ \t]", generator: { _ in nil }),
        ]
    }

    private func arrayValueEvaluators() -> [Evaluator] {
        return [
            // Arrays
            Evaluator(regex: "\\[", generator: {
                _ in .ArrayBegin
            }, push: ["array", "array"], pop: true),
        ]
    }

    private func inlineTableValueEvaluators() -> [Evaluator] {
        return [
            // Inline tables
            Evaluator(regex: "\\{", generator: {
                _ in .InlineTableBegin
            }, push: ["inlineTable"], pop: true),
        ]
    }

    private func valueEvaluators() -> [Evaluator] {
        let typeEvaluators = stringValueEvaluators() + dateValueEvaluators() +
            doubleValueEvaluators() + intValueEvaluators() + booleanValueEvaluators()

        return whitespaceValueEvaluators() + arrayValueEvaluators() +
            inlineTableValueEvaluators() + typeEvaluators
    }

    private func arrayEvaluators() -> [Evaluator] {
        return [
            // Ignore white-space
            Evaluator(regex: "[ \n\t]", generator: { _ in nil }),

            // Comments
            Evaluator(regex: "#", generator: { _ in nil }, push: ["comment"]),

            // Arrays
            Evaluator(regex: "\\[", generator: { _ in .ArrayBegin }, push: ["array"]),
            Evaluator(regex: "\\]", generator: { _ in .ArrayEnd }, pop: true),
            Evaluator(regex: ",", generator: { _ in nil }, push: ["array"]),
        ] + valueEvaluators()
    }

    private func stringKeyEvaluator() -> [Evaluator] {
        let validUnicodeChars = "\\u0020-\\u0021\\u0023-\\u005B\\u005D-\\uFFFF"
        return [
            // bare key
            Evaluator(regex: "[a-zA-Z0-9_-]+[ \t]*=",
                generator: {
                    (r: String) in
                        .Key(String(r[..<r.index(r.endIndex, offsetBy:-1)]).trim())
                },
                push: ["value"]),
            // string key
            Evaluator(regex: "\"([" + validUnicodeChars + "]|\\\\\"|\\\\)+\"[ \t]*=",
                generator: {
                    (r: String) in
                        .Key(try trimStringIdentifier(r, "\"").replaceEscapeSequences())
                },
                push: ["value"]),
            // literal string key
            Evaluator(regex: "'([\\u0020-\\u0026\\u0028-\\uFFFF])+'[ \t]*=",
                generator: { (r: String) in .Key(trimStringIdentifier(r, "'")) },
                push: ["value"]),
        ]
    }

    private func inlineTableEvaluators() -> [Evaluator] {
        return [
            // Ignore white-space and commas
            Evaluator(regex: "[ \t,]", generator: { _ in nil }),
            // inline-table
            Evaluator(regex: "\\{", generator: { _ in .InlineTableBegin }, push: ["inlineTable"]),
            Evaluator(regex: "\\}", generator: { _ in .InlineTableEnd }, pop: true),
        ] + stringKeyEvaluator()
    }

    private func rootEvaluators() -> [Evaluator] {
        return [
            // Ignore white-space
            Evaluator(regex: "[ \t\r\n]", generator: { _ in nil }),
            // Comments
            Evaluator(regex: "#", generator: { _ in nil }, push: ["comment"]),
        ] + stringKeyEvaluator() + [
            // Array of tables (must come before table)
            Evaluator(regex: "\\[\\[", generator: { _ in .TableArrayBegin }, push: ["tableArray"]),
            // Tables
            Evaluator(regex: "\\[", generator: { _ in .TableBegin }, push: ["tableName"]),
        ]
    }
}
