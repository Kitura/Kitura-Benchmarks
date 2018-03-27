-- example HTTP POST script which demonstrates setting the
-- HTTP method, body, and adding a header

wrk.method = "POST"
wrk.body   = [[
{
	"A": 12345678901,
	"B": 23456789.012,
	"C": "a piece of string",
	"D": {
		"X": 34567890123,
		"Y": 45678901.234,
		"Z": [56789012345, 67890123456, 78901234567]
	},
        "E": 18446744073709551615,
        "F": 127,
        "G": 32767,
        "H": 2147483647,
        "I": 9223372036854775807,
        "J": 255,
        "K": 65535,
        "L": 4294967295,
        "M": 18446744073709551615
}
]]
wrk.headers["Content-Type"] = "application/raw"
