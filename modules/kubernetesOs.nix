{ self, inputs, ... }: {
  flake = { config, ... }: {
    packages.x86_64-linux = {
      linuxVM =
        let
          os = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ self.nixosModules.base self.nixosModules.vm self.nixosModules.kubernetes ];
          };
        in
        os.config.system.build.vm;
    };


    # NixOS Modules
    nixosModules = {

      base = _: {
        system.stateVersion = "22.05";
        networking.useDHCP = false;
        networking.interfaces.eth0.useDHCP = true;
        services.getty.autologinUser = "cluster-admin";
        users.users.cluster-admin = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
        };
        security.sudo.wheelNeedsPassword = false;
      };

      vm = { modulesPath, ... }: {
        imports = [
          # Import qemu-vm directly to avoid using vmVariant since this config
          # is only intended to be used as a VM. Using vmVariant will emit assertion
          # errors regarding `fileSystems."/"` and `boot.loader.grub.device`.
          (modulesPath + "/virtualisation/qemu-vm.nix")
        ];
        virtualisation = {
          memorySize = 4096;
          cores = 4;
          graphics = false;
          diskImage = null;
        };

        # virtualisation.vmVariant.virtualisation.graphics = false;
      };

      kubernetes = { lib, config, pkgs, ... }:
        {
          # Smooths out upstream service startup issues.
          imports = [ ./kubernetes-startup.nix ];

          # Provision single node kubernetes listening on localhost.
          services.kubernetes = {
            roles = [ "master" "node" ];
            masterAddress = "localhost";
            kubelet.extraOpts = "--image-service-endpoint unix:///run/nix-snapshotter/nix-snapshotter.sock";
          };

          # Do not take over cni/net.d as nerdctl wants it writeable as well.
          environment.etc = lib.mkMerge [
            { "cni/net.d".enable = false; }
            (
              lib.listToAttrs
                (lib.imap
                  (i: entry:
                    let name = "cni/net.d/${toString (10+i)}-${entry.type}.conf";
                    in
                    {
                      inherit name;
                      value = { source = pkgs.writeText name (builtins.toJSON entry); };
                    })
                  config.services.kubernetes.kubelet.cni.config
                )
            )
          ];

          # Allow non-root "admin" user to just use `kubectl`.
          services.certmgr.specs.clusterAdmin.private_key.owner = "rootless";
          environment.sessionVariables = {
            KUBECONFIG = "/etc/${config.services.kubernetes.pki.etcClusterAdminKubeconfig}";
          };
          environment.systemPackages = with pkgs; [
            kompose
            kubectl
            kubernetes
            bat
            containerd
            cri-tools
            git
            jq
            nerdctl
            redis
            tree
            vim
          ];
          users.users = {
            root = {
              initialHashedPassword = null;
              password = "root";
            };
          };

          services.openssh.enable = true;

          networking.firewall.allowedTCPPorts = [ 22 ];


        };
    };
  };
}
