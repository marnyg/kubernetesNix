{ self, ... }: {
  perSystem = { config, pkgs, ... }: {

    mission-control.scripts = {
      vm = {
        description = "run kubernetes in vm";
        exec = self.packages.x86_64-linux.linuxVM;
      };
      hello = {
        description = "Say Hello";
        exec = "echo Hello";
      };
      r = {
        description = "reload direnv";
        exec = "direnv reload";
      };
      test = {
        description = "Say Hello";
        exec = "nix flake check";
      };
      fmt = {
        description = "Format the source tree";
        exec = config.treefmt.build.wrapper;
        category = "Dev Tools";
      };
    };

    devShells.default = pkgs.mkShell
      {
        buildInputs = [ pkgs.nixd pkgs.rnix-lsp pkgs.nil ];
        #LSP_SERVERS = "rnix, nixd, nil_ls";
        LSP_SERVERS = "nixd, nil_ls";
        shellHook = "${config.pre-commit.installationScript}";
        inputsFrom = [ config.mission-control.devShell ];
      };

    pre-commit = {
      settings.hooks.nixpkgs-fmt.enable = true;
      settings.hooks.deadnix.enable = true;
      settings.hooks.nil.enable = true;
      settings.hooks.statix.enable = true;
      settings.hooks.typos.enable = true;
      settings.hooks.yamllint.enable = true;
      settings.settings.statix.format = "stderr";

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
