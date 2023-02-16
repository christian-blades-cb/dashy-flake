{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dream2nix = {
      url = "github:nix-community/dream2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dashy-src = {
      url = "github:lissy93/dashy?ref=2.1.1";
      flake = false;
    };
  };

  outputs = inputs @ { self, nixpkgs, dream2nix, flake-utils, gitignore, dashy-src }:
    dream2nix.lib.makeFlakeOutputs {
      systems = flake-utils.lib.defaultSystems;
      config.projectRoot = ./.;
      source = gitignore.lib.gitignoreSource dashy-src;
      autoProjects = true;
    } //
    {
      nixosModule = import ./module.nix { inherit self; };
      nixosConfigurations.container = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModule
          {
            services.dashy = {
              enable = true;
              port = 4000;
            };

            boot.isContainer = true;

            users.users.admin = {
              isNormalUser = true;
              initialPassword = "admin";
              extraGroups = [ "wheel" ];
            };

            services.openssh.settings.PasswordAuthentication = true;
            services.openssh.enable = true;
            networking.firewall.allowedTCPPorts = [ 4000 ];

            system.stateVersion = "23.05";
          }
        ];
      };
    };

}
