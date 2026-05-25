{
  inputs = {
    utils.url = "github:numtide/flake-utils/main";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    zig-overlay = {
      url = "github:mitchellh/zig-overlay/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zls-flake = {
      url = "github:zigtools/zls/0.15.1";
      inputs.zig-overlay.follows = "zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, utils, zig-overlay, zls-flake }:
    utils.lib.eachDefaultSystem(system:
      let
        zls = zls-flake.packages.${system}.default;
        zig = zig-overlay.packages.${system}."0.15.1";
        pkgs = import nixpkgs { inherit system; };
        cache = import ./nix/cache.nix {
          inherit pkgs;
          inherit zig;
        };
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [ zig zls ];
        };

        packages.default = pkgs.stdenv.mkDerivation {
          pname = "lsr";
          version = "1.0.0";
          doCheck = false;
          src = ./.;

          nativeBuildInputs = [ zig ];

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
