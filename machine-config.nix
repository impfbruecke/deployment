{ config, pkgs, lib, ... }:
with lib; {
  imports = [
    <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
  ];

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
        # password = "nixos"; # In case you want a root password set
        openssh.authorizedKeys.keyFiles = [
          (builtins.fetchurl { url = "https://github.com/pinpox.keys"; })
        ];
      };
    };

    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      keyMap = "us";
    };

    # Install some basic utilities
    environment.systemPackages =
      [ pkgs.git pkgs.docker-compose pkgs.ag pkgs.htop ];

    # Docker
    virtualisation.docker.enable = true;
    boot.kernel.sysctl."net.ipv4.ip_forward" = true;

    # Networking, SSH, SSL
    networking.hostName = "impf-back";

    security.acme.email = "acme@pablo.tools";
    security.acme.acceptTerms = true;

    services.nginx = {
      enable = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      clientMaxBodySize = "128m";

      # Needed for bitwarden_rs, it seems to have trouble serving scripts for
      # the frontend without it.
      commonHttpConfig = ''
        server_names_hash_bucket_size 128;
      '';
    };

    programs.ssh.startAgent = false;

    services.openssh = {
      enable = true;
      passwordAuthentication = false;
      startWhenNeeded = true;
      challengeResponseAuthentication = false;
      permitRootLogin = "yes";
    };

  };
}
