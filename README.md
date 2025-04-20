# basicbrackets
Very simple lisp-like interpreted scripting language written in lua, intended for use as a game command language. Originally made for 1x1.

Commands/code can look like this: `fly false` <br>
..or like this: `def buildplatform {loop 10 {(var i (i)|(+ 1)) (placetile (tile) (x)|(+ (i)) (y))}} tile x y width` 

The language is very forgiving (unless you throw an internal error; usualy users fault), it will shut up if you run a nonexisting command. (feature, not a bug...) <br>
`this_function_doesnt_exist ".. so what?"` <br>
But you can add your own handler at the bottom of the `run` function

## How to use:
### 1. require "lang"
You can rename the file ofc, that doesnt matter. <br>
The entire library is in `lang.lua`
```lua
local lang = require "lang"
```
### 2. setup serializer (used to print complex values)
Write your own function
```lua
lang.serializer = function(value,options)
    -- ...
end
```
...or and existing library...
```lua
lang.serializer = require "inspect"
```
### 3. use it ;p
make sure to remove newlines
```lua
print(lang.run(lang.deserialize(([[
    loop 10 {
        (var i (i)|(+ 1))
        (log (join "fox no. " (i)))
    }
]]):gsub("\n", " "))))
```
