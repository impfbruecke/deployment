{ config, pkgs, lib, ... }:
let
  # Custom package, building from relative path
  # https://nixos.org/manual/nixpkgs/stable/#ex-buildGoModule
  impfbruecke = pkgs.buildGoModule rec {
    pname = "impfbruecke";
    version = "0.0.1";
    src = ../backend-go;
    vendorSha256 = "0lsy6bna388f7w90hdqmg87748bbiwliaw5naabjfc77mlaxr730";
    subPackages = [ "." ];
    deleteVendor = false;

    postInstall = ''
      mkdir -p $out
      cp -R templates $out/bin
      cp -R static $out/bin
        '';

  };
in with lib; {
  imports = [ <nixpkgs/nixos/modules/profiles/qemu-guest.nix> ];

  config = {

    # Basic VM settings
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      autoResize = true;
    };

    boot.growPartition = true;
    boot.kernelParams = [ "console=ttyS0" ];
    boot.loader.grub.device = "/dev/vda";
    boot.loader.timeout = 0;

    # Users
    users = {
      users.root = {
        openssh.authorizedKeys.keyFiles =
          [ (builtins.fetchurl { url = "https://github.com/pinpox.keys"; }) ];
      };
    };

    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      keyMap = "us";
    };

    # Install some basic utilities
    environment.systemPackages =
      [ pkgs.git pkgs.docker-compose pkgs.ag pkgs.htop pkgs.go impfbruecke ];

    # Docker
    virtualisation.docker.enable = true;
    boot.kernel.sysctl."net.ipv4.ip_forward" = true;

    # Networking, SSH, SSL
    networking.hostName = "impf-back";

    security.acme.email = "acme@impfbruecke.de";
    security.acme.acceptTerms = true;

    services.nginx = {
      enable = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      clientMaxBodySize = "128m";

      commonHttpConfig = ''
        server_names_hash_bucket_size 128;
      '';

      virtualHosts = {

        # Static page
        # "impfbruecke.de" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   root = "/var/www/";
        # };

        # API
        "api.impfbruecke.de" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = { proxyPass = "http://127.0.0.1:12000"; };
        };
      };
    };

    programs.ssh.startAgent = false;

    networking.firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [ 80 443 22 ];
    };

    services.openssh = {
      enable = true;
      passwordAuthentication = false;
      startWhenNeeded = true;
      challengeResponseAuthentication = false;
      permitRootLogin = "yes";
    };

    users.groups."impfbruecke" = { };
    users.users."impfbruecke" = {
      description = "impfbruecke System user";
      group = "impfbruecke";
      extraGroups = [ ];
      home = "/var/lib/impfbruecke";
      createHome = true;
      isSystemUser = true;
    };

    systemd.services.impfbruecke = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Impfbruecke backend";
      serviceConfig = {
        User = "impfbruecke";
        ExecStart = "${impfbruecke}/bin/backend-go";
        WorkingDirectory = "${impfbruecke}/bin";
        # ExecStop = ''${pkgs.screen}/bin/screen -S irc -X quit'';
      };
    };
  };
}
