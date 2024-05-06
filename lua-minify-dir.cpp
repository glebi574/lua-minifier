#include <iostream>
#include <filesystem>
#include <fstream>
#include <lua.hpp>

static std::filesystem::path initial_folder_path;

void minify_files(std::filesystem::path* folder_path) {
  for (std::filesystem::directory_entry entry : std::filesystem::directory_iterator(*folder_path)) {
    if (entry.is_directory()) {
      std::filesystem::path* local_folder_path = new std::filesystem::path(entry.path());
      if (local_folder_path->filename() == ".git")
        continue;
      minify_files(local_folder_path);
      delete local_folder_path;
    }
    else if (entry.is_regular_file() && (entry.path().extension() == ".lua" || entry.path().filename() == ".lua")) {
      std::ifstream file(entry.path());
      if (!file.is_open()) {
        std::cerr << "Error: Unable to open file for reading: " << entry.path() << std::endl;
        continue;
      }
      std::string contents = "";
      while (file)
        contents += file.get();
      file.close();

      std::string minifier_path = initial_folder_path.string() + "\\minifier.lua";
      std::string minified_contents;
      lua_State* L = luaL_newstate();
      luaL_openlibs(L);
      luaL_dofile(L, minifier_path.c_str());
      lua_getglobal(L, "minify");
      lua_pushstring(L, contents.c_str());
      lua_pcall(L, 1, 1, 0);
      minified_contents = lua_tostring(L, -1);
      lua_close(L);

      std::ofstream output_file(entry.path(), std::ios::trunc);
      if (!output_file.is_open()) {
        std::cerr << "Error: Unable to open file for writing: " << entry.path() << std::endl;
        continue;
      }
      output_file << std::string(minified_contents.begin(), minified_contents.end() - 1);
      output_file.close();
    }
  }
}

int main(int argc, char* argv[]) {
  initial_folder_path = std::filesystem::path(argv[0]).parent_path();
  std::filesystem::path folder_path;
  if (argc > 1) {
    folder_path = argv[1];
  }
  else {
    std::cout << "Enter folder path: ";
    std::cin >> folder_path;
    std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
  }

  std::filesystem::path minified_folder_path = initial_folder_path / "minified";

  if (std::filesystem::exists(minified_folder_path))
    std::filesystem::remove_all(minified_folder_path);
  std::filesystem::create_directory(minified_folder_path);

  std::filesystem::copy(folder_path, minified_folder_path, std::filesystem::copy_options::recursive);

  minify_files(&minified_folder_path);
  std::cout << "All Lua files in folder were minified." << std::endl;
  std::cin.get();
  return 0;
}