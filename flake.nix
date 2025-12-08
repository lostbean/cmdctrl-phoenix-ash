{
  description = "Development environment with formatting tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Markdown
            nodePackages.prettier

            # JSON / YAML
            nodePackages.prettier

            # Shell scripts
            shfmt
            shellcheck

            # TOML
            taplo

            # Nix
            nixfmt-rfc-style

            # General
            treefmt
          ];

          shellHook = ''
            echo "Development shell loaded with formatting tools:"
            echo "  - prettier (markdown, json, yaml, html, css, js)"
            echo "  - shfmt (shell scripts)"
            echo "  - shellcheck (shell linting)"
            echo "  - taplo (toml)"
            echo "  - nixfmt (nix)"
            echo "  - treefmt (orchestration)"
          '';
        };
      }
    );
}
