local MiniTest = require("mini.test")
local url = require("viewim.url")

local T = MiniTest.new_set()

-- is_http_url
T["is_http_url"] = MiniTest.new_set()

T["is_http_url"]["returns true for http scheme"] = function()
  MiniTest.expect.equality(url.is_http_url("http://example.com/image.png"), true)
end

T["is_http_url"]["returns true for https scheme"] = function()
  MiniTest.expect.equality(url.is_http_url("https://example.com/image.png"), true)
end

T["is_http_url"]["returns false for ftp scheme"] = function()
  MiniTest.expect.equality(url.is_http_url("ftp://example.com/file"), false)
end

T["is_http_url"]["returns false for plain string"] = function()
  MiniTest.expect.equality(url.is_http_url("not a url"), false)
end

T["is_http_url"]["returns false for empty string"] = function()
  MiniTest.expect.equality(url.is_http_url(""), false)
end

T["is_http_url"]["returns false for nil"] = function()
  MiniTest.expect.equality(url.is_http_url(nil), false)
end

T["is_http_url"]["returns false for local path"] = function()
  MiniTest.expect.equality(url.is_http_url("/home/user/image.png"), false)
end

-- get_scheme
T["get_scheme"] = MiniTest.new_set()

T["get_scheme"]["extracts https"] = function()
  MiniTest.expect.equality(url.get_scheme("https://example.com"), "https")
end

T["get_scheme"]["extracts http"] = function()
  MiniTest.expect.equality(url.get_scheme("http://example.com"), "http")
end

T["get_scheme"]["extracts ftp"] = function()
  MiniTest.expect.equality(url.get_scheme("ftp://files.example.com/file.zip"), "ftp")
end

T["get_scheme"]["returns nil for plain string"] = function()
  MiniTest.expect.equality(url.get_scheme("not a url"), nil)
end

T["get_scheme"]["returns nil for empty string"] = function()
  MiniTest.expect.equality(url.get_scheme(""), nil)
end

T["get_scheme"]["returns nil for nil input"] = function()
  MiniTest.expect.equality(url.get_scheme(nil), nil)
end

T["get_scheme"]["scheme is lowercased"] = function()
  MiniTest.expect.equality(url.get_scheme("HTTPS://example.com"), "https")
end

-- extension_from_url
T["extension_from_url"] = MiniTest.new_set()

T["extension_from_url"]["extracts png extension"] = function()
  MiniTest.expect.equality(url.extension_from_url("https://example.com/image.png"), ".png")
end

T["extension_from_url"]["extracts jpg extension"] = function()
  MiniTest.expect.equality(url.extension_from_url("https://example.com/photo.jpg"), ".jpg")
end

T["extension_from_url"]["strips query string before extracting"] = function()
  MiniTest.expect.equality(url.extension_from_url("https://example.com/image.png?v=1&size=large"), ".png")
end

T["extension_from_url"]["strips fragment before extracting"] = function()
  MiniTest.expect.equality(url.extension_from_url("https://example.com/image.jpg#anchor"), ".jpg")
end

T["extension_from_url"]["returns lowercase extension"] = function()
  MiniTest.expect.equality(url.extension_from_url("https://example.com/IMAGE.PNG"), ".png")
end

T["extension_from_url"]["returns nil when no extension"] = function()
  MiniTest.expect.equality(url.extension_from_url("https://example.com/no-ext"), nil)
end

T["extension_from_url"]["returns nil for nil input"] = function()
  MiniTest.expect.equality(url.extension_from_url(nil), nil)
end

T["extension_from_url"]["returns nil for empty string"] = function()
  MiniTest.expect.equality(url.extension_from_url(""), nil)
end

return T
