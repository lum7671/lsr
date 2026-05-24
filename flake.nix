{
  inputs = {
    utils.url = "github:numtide/flake-utils/main";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    zig-overlay = {
      url = "github:mitchellh/zig-overlay/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, utils, zig-overlay }:
    utils.lib.eachDefaultSystem(system:
      let
        pkgs = import nixpkgs { inherit system; };
        cache = import ./nix/cache.nix { inherit pkgs; };
        zig = zig-overlay.packages.${system};
      in {
        devshells.default = pkgs.mkShell {
          nativeBuildInputs = [ zig."0.15.1" pkgs.zls ];
        };

        packages.default = pkgs.stdenv.mkDerivation {
          pname = "lsr";
          version = "1.0.0";
          doCheck = false;
          src = ./.;

          nativeBuildInputs = [ zig."0.15.1" ];

          buildPhase = ''
            export ZIG_GLOBAL_CACHE_DIR=$(mktemp -d)
            ln -sf ${cache} $ZIG_GLOBAL_CACHE_DIR/p
            zig build -Dtarget=native-native-musl \
              -Doptimize=ReleaseFast --summary all
          '';

          installPhase = ''
            install -Ds -m755 zig-out/bin/lsr $out/bin/lsr
          '';

          meta = with pkgs.lib; {
            description = "ls(1) but with io_uring";
            homepage = "https://tangled.sh/@rockorager.dev/lsr";
            maintainers = with maintainers; [ rockorager ];
            platforms = platforms.linux;
            license = licenses.mit;
          };
        };
      });
}
