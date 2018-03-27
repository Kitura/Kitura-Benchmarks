-- example HTTP POST script which demonstrates setting the
-- HTTP method, body, and adding a header

wrk.method = "POST"
wrk.body   = [[
{
  "3": "foo",
  "4": "bar",
  "2": "bat",
  "6": "wibble",
  "9": "qux",
  "10": "fish",
  "8": "chips",
  "7": "peas",
  "1": "banana",
  "5": "apple"
}
]]
wrk.headers["Content-Type"] = "application/raw"
