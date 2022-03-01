local FileSystem = require("filesystem")

if not FileSystem.is_dir("/lua_filesystem") then 
    print("Creating /lua_filesystem")
    FileSystem.create_dir("/lua_filesystem")
end

local file = FileSystem.open("/lua_filesystem/hi.txt", "w")
file:write("Hello World!")
file:close()

local file2 = FileSystem.open("/lua_filesystem/awoo.txt", "w")
file:write("Awoo!")
file:close()

local file3 = FileSystem.open("/lua_filesystem/zzz.txt", "w")
file:write("zzz! im sleeping")
file:close()

local button = menu.add_button("Lua test", "read and print all files in /lua_filesystem", function()
local read_1 = FileSystem.open("/lua_filesystem/hi.txt", "r")
local read_2 = FileSystem.open("/lua_filesystem/awoo.txt", "r")
local read_3 = FileSystem.open("/lua_filesystem/zzz.txt", "r")

print(read_1:read())
print(read_2:read())
print(read_3:read())

read_1:close()
read_2:close()
read_3:close()
end)

local button = menu.add_button("lua test 2", "remove zzz", function()
    FileSystem.remove("/lua_filesystem/zzz.txt")    
end)

local button = menu.add_button("lua test 3", "rename hi to hi2", function()
    FileSystem.rename("/lua_filesystem/hi.txt", "/lua_filesystem/hi2.txt") -- not to sure if this works well
end)

function on_paint()

end

callbacks.add(e_callbacks.PAINT, on_paint)

