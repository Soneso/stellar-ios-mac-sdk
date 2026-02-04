//
//  TomlParserTestCase.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 2026-02-03.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class TomlParserTestCase: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Basic TOML Parsing Tests

    func testParseBasicToml() throws {
        let tomlString = """
        title = "TOML Example"
        name = "Stellar"
        version = "1.0"
        """

        let toml = try Toml(withString: tomlString)

        XCTAssertEqual(toml.string("title"), "TOML Example", "Should parse simple string")
        XCTAssertEqual(toml.string("name"), "Stellar", "Should parse simple string")
        XCTAssertEqual(toml.string("version"), "1.0", "Should parse simple string")
    }

    func testParseNestedTables() throws {
        let tomlString = """
        [database]
        server = "192.168.1.1"
        port = 5000

        [database.connection]
        max_retries = 3
        timeout = 30
        """

        let toml = try Toml(withString: tomlString)

        // Test top-level table
        let database = toml.table("database")
        XCTAssertNotNil(database, "Should parse database table")
        XCTAssertEqual(database?.string("server"), "192.168.1.1", "Should parse server value")
        XCTAssertEqual(database?.int("port"), 5000, "Should parse port value")

        // Test nested table
        let connection = database?.table("connection")
        XCTAssertNotNil(connection, "Should parse nested connection table")
        XCTAssertEqual(connection?.int("max_retries"), 3, "Should parse max_retries value")
        XCTAssertEqual(connection?.int("timeout"), 30, "Should parse timeout value")
    }

    func testParseArrays() throws {
        let tomlString = """
        ports = [8001, 8002, 8003]
        hosts = ["alpha", "beta", "gamma"]
        data = [1, 2, 3]
        """

        let toml = try Toml(withString: tomlString)

        let ports: [Int]? = toml.array("ports")
        XCTAssertNotNil(ports, "Should parse integer array")
        XCTAssertEqual(ports?.count, 3, "Array should have 3 elements")
        XCTAssertEqual(ports?[0], 8001, "First element should be 8001")
        XCTAssertEqual(ports?[2], 8003, "Last element should be 8003")

        let hosts: [String]? = toml.array("hosts")
        XCTAssertNotNil(hosts, "Should parse string array")
        XCTAssertEqual(hosts?.count, 3, "Array should have 3 elements")
        XCTAssertEqual(hosts?[0], "alpha", "First element should be alpha")
        XCTAssertEqual(hosts?[2], "gamma", "Last element should be gamma")

        let data: [Int]? = toml.array("data")
        XCTAssertNotNil(data, "Should parse data array")
        XCTAssertEqual(data?.count, 3, "Array should have 3 elements")
    }

    func testParseInlineTables() throws {
        let tomlString = """
        name = { first = "Tom", last = "Preston-Werner" }
        point = { x = 1, y = 2 }
        """

        let toml = try Toml(withString: tomlString)

        let name = toml.table("name")
        XCTAssertNotNil(name, "Should parse inline table")
        XCTAssertEqual(name?.string("first"), "Tom", "Should parse first name")
        XCTAssertEqual(name?.string("last"), "Preston-Werner", "Should parse last name")

        let point = toml.table("point")
        XCTAssertNotNil(point, "Should parse inline table")
        XCTAssertEqual(point?.int("x"), 1, "Should parse x coordinate")
        XCTAssertEqual(point?.int("y"), 2, "Should parse y coordinate")
    }

    func testParseMultilineStrings() throws {
        let tomlString = """
        description = \"\"\"
        This is a multiline string.
        It can span multiple lines.
        \"\"\"
        """

        let toml = try Toml(withString: tomlString)

        let description = toml.string("description")
        XCTAssertNotNil(description, "Should parse multiline string")
        XCTAssertTrue(description!.contains("multiline string"), "Should contain multiline text")
        XCTAssertTrue(description!.contains("multiple lines"), "Should contain full text")
    }

    func testParseLiteralStrings() throws {
        let tomlString = """
        path = 'C:\\\\Users\\\\name'
        """

        let toml = try Toml(withString: tomlString)

        let path = toml.string("path")
        XCTAssertNotNil(path, "Should parse literal string")
    }

    func testParseDateTimes() throws {
        let tomlString = """
        date1 = 1979-05-27T07:32:00Z
        date2 = 1979-05-27T00:32:00-07:00
        """

        let toml = try Toml(withString: tomlString)

        let date1 = toml.date("date1")
        XCTAssertNotNil(date1, "Should parse datetime with Z timezone")

        let date2 = toml.date("date2")
        XCTAssertNotNil(date2, "Should parse datetime with offset timezone")
    }

    func testParseNumbers() throws {
        let tomlString = """
        integer = 42
        negative = -17
        float = 3.14
        negative_float = -0.01
        exponent = 5e+22
        """

        let toml = try Toml(withString: tomlString)

        XCTAssertEqual(toml.int("integer"), 42, "Should parse positive integer")
        XCTAssertEqual(toml.int("negative"), -17, "Should parse negative integer")

        let float = toml.double("float")
        XCTAssertNotNil(float, "Should parse float")
        XCTAssertEqual(float!, 3.14, accuracy: 0.001, "Should parse float value")

        let negFloat = toml.double("negative_float")
        XCTAssertNotNil(negFloat, "Should parse negative float")
        XCTAssertEqual(negFloat!, -0.01, accuracy: 0.001, "Should parse negative float value")

        let exp = toml.double("exponent")
        XCTAssertNotNil(exp, "Should parse exponent notation")
    }

    func testParseBooleans() throws {
        let tomlString = """
        enabled = true
        disabled = false
        """

        let toml = try Toml(withString: tomlString)

        XCTAssertEqual(toml.bool("enabled"), true, "Should parse true boolean")
        XCTAssertEqual(toml.bool("disabled"), false, "Should parse false boolean")
    }

    // MARK: - Error Handling Tests

    func testInvalidTomlThrows() {
        let invalidToml = """
        [invalid
        key = value
        """

        XCTAssertThrowsError(try Toml(withString: invalidToml), "Invalid TOML should throw error") { error in
            XCTAssertTrue(error is TomlError, "Should throw TomlError")
        }
    }

    func testMissingKeyReturnsNil() throws {
        let tomlString = """
        name = "test"
        """

        let toml = try Toml(withString: tomlString)

        XCTAssertNil(toml.string("nonexistent"), "Missing key should return nil")
        XCTAssertNil(toml.int("nonexistent"), "Missing key should return nil")
        XCTAssertNil(toml.bool("nonexistent"), "Missing key should return nil")
    }

    func testTypeMismatchReturnsNil() throws {
        let tomlString = """
        name = "test"
        count = 42
        enabled = true
        """

        let toml = try Toml(withString: tomlString)

        // Try to get string as int
        XCTAssertNil(toml.int("name"), "Type mismatch should return nil")

        // Try to get int as string
        XCTAssertNil(toml.string("count"), "Type mismatch should return nil")

        // Try to get bool as string
        XCTAssertNil(toml.string("enabled"), "Type mismatch should return nil")
    }

    // MARK: - Advanced TOML Features Tests

    func testParseComplexNestedStructure() throws {
        let tomlString = """
        [owner]
        name = "Stellar Development Foundation"

        [database]
        server = "192.168.1.1"
        ports = [8001, 8002, 8003]
        connection_max = 5000
        enabled = true

        [servers.alpha]
        ip = "10.0.0.1"
        dc = "eqdc10"

        [servers.beta]
        ip = "10.0.0.2"
        dc = "eqdc10"
        """

        let toml = try Toml(withString: tomlString)

        // Test owner table
        let owner = toml.table("owner")
        XCTAssertNotNil(owner, "Should parse owner table")
        XCTAssertEqual(owner?.string("name"), "Stellar Development Foundation", "Should parse owner name")

        // Test database table with mixed types
        let database = toml.table("database")
        XCTAssertNotNil(database, "Should parse database table")
        XCTAssertEqual(database?.string("server"), "192.168.1.1", "Should parse server")
        XCTAssertEqual(database?.int("connection_max"), 5000, "Should parse connection_max")
        XCTAssertEqual(database?.bool("enabled"), true, "Should parse enabled")

        let ports: [Int]? = database?.array("ports")
        XCTAssertNotNil(ports, "Should parse ports array")
        XCTAssertEqual(ports?.count, 3, "Ports array should have 3 elements")

        // Test nested servers tables
        let servers = toml.table("servers")
        XCTAssertNotNil(servers, "Should parse servers table")

        let alpha = servers?.table("alpha")
        XCTAssertNotNil(alpha, "Should parse alpha server")
        XCTAssertEqual(alpha?.string("ip"), "10.0.0.1", "Should parse alpha IP")

        let beta = servers?.table("beta")
        XCTAssertNotNil(beta, "Should parse beta server")
        XCTAssertEqual(beta?.string("ip"), "10.0.0.2", "Should parse beta IP")
    }

    func testParseEmptyToml() throws {
        let emptyToml = ""

        let toml = try Toml(withString: emptyToml)

        XCTAssertNotNil(toml, "Empty TOML should parse successfully")
        XCTAssertNil(toml.string("anything"), "Empty TOML should have no keys")
    }

    func testParseCommentsIgnored() throws {
        let tomlWithComments = """
        # This is a comment
        name = "test" # inline comment
        # Another comment
        count = 42
        """

        let toml = try Toml(withString: tomlWithComments)

        XCTAssertEqual(toml.string("name"), "test", "Should parse value with inline comment")
        XCTAssertEqual(toml.int("count"), 42, "Should parse value after comment lines")
    }

    func testParseEscapeSequences() throws {
        let tomlString = """
        basic = "I'm a string. \\"You can quote me\\". Name\\tJos\\u00E9\\nLocation\\tSF."
        """

        let toml = try Toml(withString: tomlString)

        let basic = toml.string("basic")
        XCTAssertNotNil(basic, "Should parse string with escape sequences")
        XCTAssertTrue(basic!.contains("\"You can quote me\""), "Should handle escaped quotes")
    }

    func testHasKeyMethod() throws {
        let tomlString = """
        [section]
        key = "value"
        """

        let toml = try Toml(withString: tomlString)

        XCTAssertTrue(toml.hasKey("section", "key"), "Should find existing key")
        XCTAssertFalse(toml.hasKey("section", "nonexistent"), "Should not find nonexistent key")
        XCTAssertTrue(toml.hasTable("section"), "Should find existing table")
        XCTAssertFalse(toml.hasTable("nonexistent"), "Should not find nonexistent table")
    }

    func testParseNumberVariations() throws {
        // This TOML parser doesn't support:
        // - Numbers with underscores (1_000_000)
        // - Hex/octal/binary integers (0xDEAD, 0o755, 0b1010)
        // - Special float values (inf, nan)
        // Test standard number formats only

        let tomlString = """
        large_number = 1000000
        decimal = 3.141592653
        """

        let toml = try Toml(withString: tomlString)

        XCTAssertEqual(toml.int("large_number"), 1000000, "Should parse large integer")

        let decimal = toml.double("decimal")
        XCTAssertNotNil(decimal, "Should parse decimal")
        XCTAssertEqual(decimal!, 3.141592653, accuracy: 0.000000001, "Should parse decimal value accurately")
    }

    func testParseEmptyArrays() throws {
        let tomlString = """
        empty_array = []
        """

        let toml = try Toml(withString: tomlString)

        let emptyArray: [String]? = toml.array("empty_array")
        XCTAssertNotNil(emptyArray, "Should parse empty array")
        XCTAssertEqual(emptyArray?.count, 0, "Empty array should have zero elements")
    }

    func testParseMixedArrayThrows() {
        let mixedArrayToml = """
        mixed = [1, "two", 3.0]
        """

        XCTAssertThrowsError(try Toml(withString: mixedArrayToml), "Mixed type array should throw error") { error in
            if let tomlError = error as? TomlError {
                if case .MixedArrayType = tomlError {
                    // Expected error
                } else {
                    XCTFail("Expected MixedArrayType error, got \(tomlError)")
                }
            }
        }
    }

    func testParseDuplicateKeyThrows() {
        let duplicateKeyToml = """
        name = "first"
        name = "second"
        """

        XCTAssertThrowsError(try Toml(withString: duplicateKeyToml), "Duplicate key should throw error") { error in
            if let tomlError = error as? TomlError {
                if case .DuplicateKey = tomlError {
                    // Expected error
                } else {
                    XCTFail("Expected DuplicateKey error, got \(tomlError)")
                }
            }
        }
    }

    func testParseFromFile() throws {
        // Create temporary TOML file
        let tomlContent = """
        title = "Test File"
        count = 123
        """

        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test_\(UUID().uuidString).toml")

        try tomlContent.write(to: tempFile, atomically: true, encoding: .utf8)

        // Test parsing from file
        let toml = try Toml(contentsOfFile: tempFile.path)

        XCTAssertEqual(toml.string("title"), "Test File", "Should parse from file")
        XCTAssertEqual(toml.int("count"), 123, "Should parse integer from file")

        // Cleanup
        try? FileManager.default.removeItem(at: tempFile)
    }

    func testTomlDescription() throws {
        let tomlString = """
        name = "test"
        count = 42
        """

        let toml = try Toml(withString: tomlString)

        let description = toml.description
        XCTAssertNotNil(description, "Should generate description")
        XCTAssertFalse(description.isEmpty, "Description should not be empty")
    }
}
