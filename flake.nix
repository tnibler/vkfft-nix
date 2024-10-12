{
  description = "Flake to build VkFFT with Vulkan";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    vkfft-src = {
      url = "github:DTolm/VkFFT";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    vkfft-src,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        glslang-tag-default = let
          inherit (builtins) match elemAt readFile;
          parse = match ''.*set\(GLSLANG_GIT_TAG "([^"]*)"\).*'' (readFile "${vkfft-src}/CMakeLists.txt");
        in
          elemAt parse 0;
        glslang-git = pkgs.fetchFromGitHub {
          owner = "KhronosGroup";
          repo = "glslang";
          rev = glslang-tag-default;
          hash = "sha256-NP5ph598YSPbpzJJUR2r+EkqFmuItxgvOSDgDaN+Swg=";
        };
      in {
        packages.default = with pkgs;
          stdenv.mkDerivation {
            name = "VkFFT";
            src = vkfft-src;
            buildInputs = [
              git
              cmake
              vulkan-headers
              vulkan-loader
              python312
            ];
            preConfigure = ''
              substituteInPlace CMakeLists.txt --replace-fail 'add_subdirectory(''${CMAKE_CURRENT_SOURCE_DIR}/glslang-main)' 'add_subdirectory(${glslang-git} glslang-INSTALL)'
            '';
            patches = [./patch];
            cmakeFlags = ["-DFETCHCONTENT_SOURCE_DIR_GLSLANG-MAIN=${glslang-git}"];
          };
      }
    );
}
