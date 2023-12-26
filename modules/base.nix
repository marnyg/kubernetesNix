{ self, ... }: {
  perSystem = { config, pkgs, ... }: {

    devShells = {
      default = pkgs.mkShell {
        buildInputs = [ pkgs.nixd pkgs.rnix-lsp ];
        LSP_SERVERS = "rnix, nixd";
      };
    };

    formatter = config.treefmt.build.wrapper;


    treefmt.config = {
      inherit (config.flake-root) projectRootFile;
      package = pkgs.treefmt;
      
      programs.nixpkgs-fmt.enable = true;
      programs.yamlfmt.enable = true;
    };
  };
}
