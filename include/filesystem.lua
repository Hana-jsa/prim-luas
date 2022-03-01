local ffi = require("ffi")

ffi.cdef[[
    // read file type                    class  buffer size file             
    typedef int(__thiscall* read_file_t)(void*, void*, int, void*);
    // write file type                    class     text      size file
    typedef int(__thiscall* write_file_t)(void*, void const*, int, void*);
    // open file type                    class  path mode path_id
    typedef void*(__thiscall* open_file_t)(void*, const char*, const char*, const char*);
    // close file type                   class  file
    typedef void(__thiscall* close_file_t)(void*, void*);
    // file size type                   class  file
    typedef unsigned int(__thiscall* file_size_t)(void*, void*);
    // file exists type                  class  path path_id
    typedef bool(__thiscall* file_exist_t)(void*, const char*, const char*);
    // all functions we use from VBaseFileSystem011 

    // add search path 
    typedef void(__thiscall* add_search_path_t)(void*, const char*, const char*, int);
    // remove search path 
    typedef void(__thiscall* remove_search_path_t)(void*, const char*, const char*);
    // remove file 
    typedef bool(__thiscall* remove_file_t)(void*, const char*, const char*);
    // rename file
    typedef bool(__thiscall* rename_file_t)(void*, const char*, const char*, const char*);
    // create directory hierarchy
    typedef void(__thiscall* create_dir_hierarchy_t)(void*, const char*, const char*);
    // is directory
    typedef bool(__thiscall* is_directory_t)(void*, const char*, const char*);
    // find first file
    typedef const char*(__thiscall* find_first_file_t)(void*, const char*, int*);
    // find next file
    typedef const char*(__thiscall* find_next_file_t)(void*, int);
    // find is directory
    typedef bool(__thiscall* find_is_directory_t)(void*, int);
    // find close
    typedef void(__thiscall* find_close_t)(void*, int);
]]


local class_ptr = ffi.typeof("void***")
local rawfilesystem = memory.create_interface("filesystem_stdio.dll", "VBaseFileSystem011") or error("error", 2)
local fs_class = ffi.cast(class_ptr, rawfilesystem) or error("error", 2)


local read_file = ffi.cast("read_file_t", fs_class[0][0]) or error("error", 2)
local write_file = ffi.cast("write_file_t", fs_class[0][1]) or error("error", 2)
local open_file = ffi.cast("open_file_t", fs_class[0][2]) or error("error", 2)
local close_file = ffi.cast("close_file_t", fs_class[0][3]) or error("error", 2)
local file_size = ffi.cast("file_size_t", fs_class[0][7]) or error("error", 2)
local file_exist = ffi.cast("file_exist_t", fs_class[0][10]) or error("error", 2)


local full_rawfilesystem = memory.create_interface("filesystem_stdio.dll", "VFileSystem017") or error("error", 2)
local full_filesystem = ffi.cast(class_ptr, full_rawfilesystem) or error("error", 2)


local add_search_path = ffi.cast("add_search_path_t", full_filesystem[0][11]) or error("error", 2)
local remove_search_path = ffi.cast("remove_search_path_t", full_filesystem[0][12]) or error("error", 2)
local remove_file = ffi.cast("remove_file_t", full_filesystem[0][20]) or error("error", 2)
local rename_file = ffi.cast("rename_file_t", full_filesystem[0][21]) or error("error", 2) 
local create_dir_hierarchy = ffi.cast("create_dir_hierarchy_t", full_filesystem[0][22]) or error("error", 2)
local is_directory = ffi.cast("is_directory_t", full_filesystem[0][23]) or error("error", 2)
local find_first_file = ffi.cast("find_first_file_t", full_filesystem[0][32]) or error("error", 2)
local find_next_file = ffi.cast("find_next_file_t", full_filesystem[0][33]) or error("error", 2)
local find_is_directory = ffi.cast("find_is_directory_t", full_filesystem[0][34]) or error("error", 2)
local find_close = ffi.cast("find_close_t", full_filesystem[0][35]) or error("error", 2)

local MODES = {
    ["r"] = "r",
    ["w"] = "w",
    ["a"] = "a",
    ["r+"] = "r+",
    ["w+"] = "w+",
    ["a+"] = "a+",
    ["rb"] = "rb", 
    ["wb"] = "wb",
    ["ab"] = "ab",
    ["rb+"] = "rb+",
    ["wb+"] = "wb+",
    ["ab+"] = "ab+"
}

local FileSystem = {}
FileSystem.__index = FileSystem

function FileSystem.exists(file, path_id)
    return file_exist(fs_class, file, path_id)
end

function FileSystem.rename(old_name, new_name, path_id)
    rename_file(full_filesystem, old_name, new_name, path_id)
end

function FileSystem.remove(file, path_id)
    remove_file(full_filesystem, file, path_id)
end

function FileSystem.create_dir(path, path_id)
    create_dir_hierarchy(full_filesystem, path, path_id)
end

function FileSystem.is_dir(path, path_id)
    return is_directory(full_filesystem, path, path_id)
end

function FileSystem.find_first(path)
    local handle = ffi.new("int[1]")
    local file = find_first_file(full_filesystem, path, handle)

    if file == ffi.NULL then return nill end

    return ffi.string(file)
end

function FileSystem.find_next(handle)
    local file = find_next_file(full_filesystem, handle)

    if file == ffi.NULL then return nill end

    return ffi.string(file)
end

function FileSystem.find_is_dir(handle)
    return find_is_directory(full_filesystem, handle)
end

function FileSystem.find_close(handle)
    find_close(full_filesystem, handle)
end

function FileSystem.add_search_path(path, path_id, typee)
    add_search_path(full_filesystem, path, path_id, typee)
end

function FileSystem.remove_search_path(path, path_id)
    remove_search_path(full_filesystem, path, path_id)
end

function FileSystem.open(file, mode, path_id)
    if not MODES[mode] then error("invalid mode", 2) end

    local self = setmetatable({
        file = file,
        mode = mode,
        path_id = path_id,
        handle = open_file(fs_class, file, mode, path_id)
    }, FileSystem)

    if self.handle == -1 then error("error opening file", 2) end

    return self
end

function FileSystem:get_size()
    return file_size(fs_class, self.handle)
end

function FileSystem:write(buffer)
    write_file(fs_class, buffer, #buffer, self.handle)
end

function FileSystem:read()
    local size = self:get_size()
    local output = ffi.new("char[?]", size + 1)

    read_file(fs_class, output, size, self.handle)

    return ffi.string(output)
end

function FileSystem:close()
    close_file(fs_class, self.handle)
end


return FileSystem