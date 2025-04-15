unpack = unpack or table.unpack
require "lang" 
inspect = require "inspect" 
while true do
    io.write("\n> ")
    local code = io.read()
    print("----")
    print("\n< "..tostring(execute(deserialize(code:gsub("\n", " "))) or "[nil]"))
end