{ self, inputs, ... }: {
  flake = { config, ... }: {
    packages.x86_64-linux = {
      linuxVM =
        let
          os = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ self.nixosModules.base self.nixosModules.vm ];
          };
        in
        os.config.system.build.vm;
    };


    # NixOS Modules
    nixosModules = {

      base = { pkgs, ... }: {
        system.stateVersion = "22.05";
        networking.useDHCP = false;
        networking.interfaces.eth0.useDHCP = true;
        services.getty.autologinUser = "test";
        users.users.test = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
        };
        security.sudo.wheelNeedsPassword = false;
      };

      vm = { ... }: {
        virtualisation.vmVariant.virtualisation.graphics = false;
      };

      kubernetes = { ... }: {
        virtualisation.vmVariant.virtualisation.graphics = false;
      };
    };
  };
}
