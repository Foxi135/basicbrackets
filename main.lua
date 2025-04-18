inspect = require "inspect"

lang = require "lang" 
lang.serializer = inspect

if love then
    --arg[1] = "examples/fizzbuzz"
    arg[1] = nil
end

if arg[1] then
    local file = io.open(arg[1], "r")
    local code = file:read("*a")
    file:close()
    --local start = love.timer.getTime()
    local r = lang.run(lang.deserialize(code:gsub("\n", " "))) or ""
    --print(love.timer.getTime()-start)
    io.write(r)
else
    while true do
        io.write("\n> ")
        local code = io.read()
        print("----")
        local r = inspect(lang.run(lang.deserialize(code:gsub("\n", " "))))
        print("\n< "..r)
    end
end
