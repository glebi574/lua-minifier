# Lua minifier
Removes unnecessary spaces, tabulations, newline characters and replaces required ones with spaces. Removes comments.  
Consists of script `minifier.lua`, which can be used manually to minify file and executable `lua-minify-dir.exe`, which uses script to minify all Lua files in a folder recursively.
## minifier.lua
`minify(str)` - function returns string, containing minified code.  
`minify_file(input_path, output_path)` - minifies contents of `input_path` and  writes them to `output_path`.  
## lua-minify-dir.exe
Open folder, using executable or drag-and-drop it in executable's console to provide path. Minifies all Lua files in the folder recursively.
