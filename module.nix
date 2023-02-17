{ self }: { config, pkgs, lib, modulesPath, ... }:

let
  cfg = config.services.dashy;
  toYAML = name: text: pkgs.runCommand "name" { inherit text; passAsFile = [ "text" ]; } "${pkgs.json2yaml}/bin/json2yaml < $textPath > $out" ;
in {
  options.services.dashy = {
    enable = lib.mkEnableOption "Enables dashy server";

    host = lib.mkOption rec {
      type = lib.types.str;
      default = "0.0.0.0";
      example = "127.0.0.1";
      description = "ip to bind the service";
    };

    port = lib.mkOption rec {
      type = lib.types.port;
      default = 4000;
      example = default;
      description = "port to bind the web service";
    };

    settings = lib.mkOption rec {
      type = lib.types.str;
      default = ''
pageInfo:
  title: Dashy
  description: Welcome to your new dashboard!
  navLinks:
    - title: GitHub
      path: https://github.com/Lissy93/dashy
    - title: Documentation
      path: https://dashy.to/docs
appConfig:
  theme: colorful
  layout: auto
  iconSize: medium
  language: en
sections:
  - name: Getting Started
    icon: fas fa-rocket
    items:
      - title: Dashy Live
        description: Development a project management links for Dashy
        icon: https://i.ibb.co/qWWpD0v/astro-dab-128.png
        url: https://live.dashy.to/
        target: newtab
        id: 0_1481_dashylive
      - title: GitHubGGRGRG
        description: Source Code, Issues and Pull Requests
        icon: favicon
        url: https://github.com/lissy93/dashy
        id: 1_1481_githubggrgrg
      - title: Docs
        description: Configuring & Usage Documentation
        provider: Dashy.to
        icon: far fa-book
        url: https://dashy.to/docs
        id: 2_1481_docs
      - title: Showcase
        description: See how others are using Dashy
        url: https://github.com/Lissy93/dashy/blob/master/docs/showcase.md
        icon: far fa-grin-hearts
        id: 3_1481_showcase
      - title: Config Guide
        description: See full list of configuration options
        url: https://github.com/Lissy93/dashy/blob/master/docs/configuring.md
        icon: fas fa-wrench
        id: 4_1481_configguide
      - title: Support
        description: Get help with Dashy, raise a bug, or get in contact
        url: https://github.com/Lissy93/dashy/blob/master/.github/SUPPORT.md
        icon: far fa-hands-helping
        id: 5_1481_support
    displayData:
      sortBy: default
      rows: 2
      cols: 1
      collapsed: false
      hideForGuests: false
      '';
      example = default;
      description = "Config, in yaml, sorry. To persist changes made in the UI, export the config and paste it here.";
    };

    mutableConfig = lib.mkOption rec {
      type = lib.types.bool;
      description = "allow mutation via the interactive editor";
      default = true;
      example = default;
    };

  };

  config = lib.mkIf cfg.enable {
    users.groups."dashy" = {};

    users.users."dashy" = {
      isSystemUser = true;
      group = "dashy";
    };

    systemd.services."dashy" =
      let
        configFile = pkgs.writeText "conf.yml" cfg.settings;
        package = self.packages.${pkgs.system}.default;
      in {
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        environment = {
          HOST = cfg.host;
          PORT = toString cfg.port;
        };
        path = with pkgs; [ bashInteractive ffmpeg nodejs-16_x openssl yarn python3 ];

        script = ''
          #!/bin/sh

          if [ ! -d /var/lib/dashy/public ]; then
            umask 077
            mkdir -p /var/lib/dashy/public
            cp -R ${package}/lib/node_modules/Dashy/public/* /var/lib/dashy/public/
            rm /var/lib/dashy/public/conf.yml
          fi
        ''
        + (if cfg.mutableConfig then ''
          if [ ! -e /var/lib/dashy/public/conf.yml ]; then
            cp ${configFile} /var/lib/dashy/public/conf.yml
            chmod 0600 /var/lib/dashy/public/conf.yml
          fi
        '' else ''
          ln -f -s ${configFile} /var/lib/dashy/public/conf.yml
        '') +
        ''
          node ${package}/lib/node_modules/Dashy/server
        ''
        ;

        serviceConfig = {
          Type = "simple";
          Restart = "always";
          User = "dashy";
          Group = "dashy";
          StateDirectory = "dashy";
          StateDirectoryMode = "0700";
          WorkingDirectory = "/var/lib/dashy";
        };
      };
  };
}
