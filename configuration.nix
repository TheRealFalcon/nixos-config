# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

# Notes:
# recreate audiobookshelf from scratch as the newer version will fail
#   to work with the old database anyway.
#

# nixos-rebuild switch --flake /etc/nixos#nixos

# TODO:
# networking.hostFiles = [ /etc/nixos/hosts.txt ];
# services.dnsmasq.enable = true;
# services.dnsmasq.alwaysKeepRunning = true;
# services.dnsmasq.servers = [ "8.8.8.8" "8.8.4.4" ];
# services.dnsmasq.extraConfig = "cache-size=500";/

{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:

{
  nix = {
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.download-buffer-size = 524288000;
  };
  system.stateVersion = "24.05"; # Did you read the comment?

  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  environment.systemPackages = with pkgs; [
    abcde
    bashInteractive
    cddiscid
    cdparanoia
    coreutils
    fd
    findutils
    git
    id3
    id3v2
    jq
    jujutsu
    lame
    less
    lsof
    man
    mg
    ncdu
    nix-index
    procps
    python313Packages.eyed3
    shadow
    starship
    strace
    tuckr
    util-linux
    vim
    wavpack
    wget
    zlib-ng
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sdb";
  boot.loader.timeout = 2;
  boot.loader.grub.useOSProber = false;

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/c5bf6e6a-c4c9-4a5c-8395-1e2e390004b6";
      fsType = "ext4";
    };
    "/backup" = {
      device = "/dev/disk/by-uuid/068C27968C277EF5";
      fsType = "ntfs";
    };
    "/stuff" = {
      device = "/dev/disk/by-uuid/3884dbcb-1fc1-4d41-94cb-7f488ece86ef";
      fsType = "ext4";
    };
    "/data" = {
      device = "/dev/disk/by-uuid/736fc740-dcb2-4251-9b7f-0dd09b6f0bcd";
      fsType = "ext4";
    };
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 4 * 1024; # 4GB
    }
  ];

  networking = {
    dhcpcd.enable = false;
    firewall = {
      allowPing = true;
      enable = true;
      allowedTCPPorts = [
        8123 # home-assistant
        8384 # syncthing web GUI
        22000 # syncthing sync
      ];
      trustedInterfaces = [ "incusbr0" ];
    };
    nftables.enable = true;
    useDHCP = false;
    useHostResolvConf = false;
  };

  systemd.network = {
    enable = true;
    networks."enp0s31f6" = {
      matchConfig = {
        PermanentMACAddress = "1c:1b:0d:1b:44:c4";
        Name = "enp0s31f6";
      };
      networkConfig = {
        DHCP = "ipv4";
        LinkLocalAddressing = "ipv6";
        Address = "192.168.1.43/24";
        IPv6AcceptRA = true;
      };
      dns = [
        "8.8.8.8"
        "4.4.4.4"
      ];
      routes = [
        {
          Destination = "0.0.0.0/0";
          Gateway = "192.168.1.1";
        }
      ];
    };
  };

  users.users = {
    james = {
      hashedPasswordFile = "/var/lib/private/james.pw";
      shell = pkgs.fish;
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDVFCuncf2UzPNMH2qAupg0/8L3pIH6Y86lyfWa6nke/haXITT9xKsjLrau2aAGoyPBpgFah6TIqPIEaHCm8OjYzcpHQLRXbu3mCAK70E23ud8zubBiEZ3GSdvhedrNvxgo9p84UaEIPhDik30HzSiiv2oYrUmnnPFdacMXG8Q99khvSKnC15jylINFDAdzETKidDMV/p0xn5zVydwCxNzChJOb5nXzdTwXZ1YiB1vgRuGeOjZ77SwoTWkqFfDaUT4B7U88pTwOnAvQOIVd9LCQzcMUucAL4QdHK6XXtAciJUrG8I+h4xDt/JmpsQ4WbeYFukQt6pf1cpxSLWPigMhmFAygZZEft+gXkszELpMA6DBqy+VLjJ0/sNZzZvR7UwhG1n9o2OLdwxyw0Shxm0ZeFeFYNeNp6AaficHPEH+wGQuvgHuN35ZEgAw8MGLSoDdDPOxn5Py7gtz5fK4gSN+QtkaNFRIUZULoyBRDxr6SFVqnVvw8CxuCvkKfoygMXQk= james@cow"
      ];
      extraGroups = [ 
        "incus-admin"
        "wheel"
      ];
    };
  };

  programs.fish.enable = true;
  security.sudo.wheelNeedsPassword = false;

  systemd.tmpfiles.rules = [
    # Make sure all the private permissions are set correctly
    "z /var/lib/private 0555 root root"
    "z /var/lib/private/james.pw 0600 root root"
    "z /var/lib/private/syncthing-key.pem 0400 james users"
    "z /var/lib/private/syncthing-cert.pem 0440 james users"
    "z /var/lib/private/linkwarden.env 0400 linkwarden linkwarden"
    "z /var/lib/private/linkwarden_api_token 0400 root root"

    # SSH keys
    "f+ /home/james/.ssh/id_rsa.pub 0644 james users"
    "w /home/james/.ssh/id_rsa.pub - - - - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDVFCuncf2UzPNMH2qAupg0/8L3pIH6Y86lyfWa6nke/haXITT9xKsjLrau2aAGoyPBpgFah6TIqPIEaHCm8OjYzcpHQLRXbu3mCAK70E23ud8zubBiEZ3GSdvhedrNvxgo9p84UaEIPhDik30HzSiiv2oYrUmnnPFdacMXG8Q99khvSKnC15jylINFDAdzETKidDMV/p0xn5zVydwCxNzChJOb5nXzdTwXZ1YiB1vgRuGeOjZ77SwoTWkqFfDaUT4B7U88pTwOnAvQOIVd9LCQzcMUucAL4QdHK6XXtAciJUrG8I+h4xDt/JmpsQ4WbeYFukQt6pf1cpxSLWPigMhmFAygZZEft+gXkszELpMA6DBqy+VLjJ0/sNZzZvR7UwhG1n9o2OLdwxyw0Shxm0ZeFeFYNeNp6AaficHPEH+wGQuvgHuN35ZEgAw8MGLSoDdDPOxn5Py7gtz5fK4gSN+QtkaNFRIUZULoyBRDxr6SFVqnVvw8CxuCvkKfoygMXQk= james@cow\n"
    "z /var/lib/private/id_rsa 0600 james users"
    "L+ /home/james/.ssh/id_rsa - - - - /var/lib/private/id_rsa"

    # Tuckr symlink
    "L+ /home/james/.config/dotfiles - - - - /home/james/sync/configs/dotfiles"
  ];

  systemd.timers."linkwarden-backup" = {
    description = "Backup Linkwarden data";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
      Unit = "linkwarden-backup.service";
    };
  };

  systemd.services."linkwarden-backup" = {
    script = ''
      /run/current-system/sw/bin/curl  --request GET \
            --url http://192.168.1.43:3000/api/v1/migration \
            --header 'Accept: application/json' \
            --header "Authorization: Bearer $(cat /var/lib/private/linkwarden_api_token)" \
            --output /data/linkwarden-backup.json
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  services.audiobookshelf = {
    enable = true;
    host = "0.0.0.0";
    port = 13378;
    openFirewall = true;
  };

  services.deluge = {
    enable = true;
    web.enable = true;
    web.openFirewall = true;
    web.port = 8112;
  };

  services.home-assistant = {
    enable = true;
    # openFirewall = true;  # Can only be used in declarative config

    # config = {
    # http.server_port = 8123;
    # http.server_host = "0.0.0.0";
    # };
    config = null;
    lovelaceConfig = null;
    configDir = "/etc/home-assistant";

    # package = pkgs.home-assistant.override {
    #   extraPackages = ps: [ ps.pynacl ];
    # };
    # package = (pkgs.callPackage pkgs.path {
    #   inherit (pkgs) home-assistant;
    # }).home-assistant.override {
    #   extraPackages = ps: [ ps.pynacl ];
    # };

    package = pkgs.home-assistant.override {
      extraPackages = ps: [
        ps.aiodhcpwatcher
        ps.aiodiscover
        ps.aiousbwatcher
        ps.async-upnp-client
        ps.getmac
        ps.go2rtc-client
        ps.hassil
        ps.home-assistant-intents
        ps.mutagen
        ps.pymicro-vad
        ps.pynacl
        ps.pyserial
        ps.pyspeex-noise
      ];
    };

    extraComponents = [
      # "analytics"
      "google"
      "google_assistant"
      "google_drive"
      "google_mail"
      "google_maps"
      "google_photos"
      "google_translate"
      "isal"
      "met"
      "nest"
      "radio_browser"
      "spotify"
      "tailscale"
      "tplink"
    ];
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  services.linkwarden = {
    enable = true;
    enableRegistration = true;
    environmentFile = "/var/lib/private/linkwarden.env";
    host = "0.0.0.0";
    port = 3000;
    openFirewall = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  services.samba = {
    enable = true;
    securityType = "user";
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "NixOS Server";
        "map to guest" = "Bad User";
        "guest account" = "james";
      };
      "public" = {
        path = "/home/james/share";
        "guest ok" = true;
        "valid users" = [ "james" ];
        "read only" = false;
        "browsable" = true;
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "james";
        "force group" = "users";
        "public" = true;
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true; # This does NOT open the web GUI port, 8384 opened in networking.firewall.allowedTCPPorts
    guiAddress = "0.0.0.0:8384";
    user = "james";
    group = "users";
    configDir = "/home/james/.syncthingconfig"; # if ~/.config/syncthing, nixos will create ~/.config owned by root
    # extraFlags = [ "--no-default-folder" ]; # Don't create default ~/Sync folder
    key = "/var/lib/private/syncthing-key.pem";
    cert = "/var/lib/private/syncthing-cert.pem";
    settings = {
      devices = {
        "pixel8" = {
          id = "KPVQJ5S-WJ4YTRN-5R5JSXU-ARIIPIN-3I7TC3R-M6Q26RG-2XAP3B6-RVXI5QE";
        };
        "cow" = {
          id = "7BSDDTD-QF5PTSR-L24GNLA-3KWU66Y-OAMPDBW-YGGPF2X-LR57MTA-UPMPKAQ";
        };
      };
      folders = {
        "pixel_8_jr4z-photos" = {
          label = "pixel 8 photos";
          path = "/home/james/sync/pixel8_photos";
          devices = [
            "pixel8"
            "cow"
          ];
        };
        "odl0c-z0c4d" = {
          label = "phone sync";
          path = "/home/james/sync/phone";
          devices = [
            "pixel8"
            "cow"
          ];
        };
        "jhuqq-vp3qp" = {
          label = "configs";
          path = "/home/james/sync/configs";
          devices = [ "cow" ];
        };
        "nwgye-qxqhz" = {
          label = "james crap";
          path = "/home/james/sync/james_crap";
          devices = [ "cow" ];
        };
        "jaurg-xzbvu" = {
          label = "pics";
          path = "/home/james/sync/pics";
          devices = [ "cow" ];
        };
      };
    };
  };

  services.tailscale = {
    enable = true;
    authKeyFile = "/var/lib/private/tailscale_auth_key";
  };
  
  virtualisation = {
    incus.enable = true;
    oci-containers.containers = {
      dispatcharr = {
        image = "ghcr.io/dispatcharr/dispatcharr:latest";
        ports = [ "9191:9191" ];
        volumes = [
          "dispatcharr_data:/data"
        ];
      };
  };
}
