# R3PLAYX-nix

Bring R3PALYX to NixOS

<!-- Remove this if you don't use github actions -->
![Build and populate cache](https://github.com/EndCredits/R3PLAYX-nix/workflows/Build%20and%20populate%20cache/badge.svg)

## How to use

Note: You'll need nix flake taking over your system management. If you're still using legacy way to describe your nixos build, please refer to link below to integrate your system management with flake.

en\_US: [Enabling NixOS with Flakes - NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/nixos-with-flakes-enabled)

zh\_CN: [使用 Flakes 来管理你的 NixOS - NixOS 与 Flakes](https://nixos-and-flakes.thiscute.world/zh/nixos-with-flakes/nixos-with-flakes-enabled)

1. Add this repository in your flakes inputs and pass input as special args to your submodules

```diff
/etc/nixos/flake.nix
  {
    description = "EndCredits's NixOS Flake";
    nixConfig = {};
    inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
++    r3playx.url = "github:EndCredits/R3PLAYX-nix/master";
    };

    outputs = { self, nixpkgs, ... }@inputs: {
      nixosConfigurations = {
        "crepuscular-nixos" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
++        specialArgs = inputs;
          modules = [
            ./configuration.nix
          ];
        };
      };
    };
  }
```

2. Add ```r3playx``` as a input parameter to your configuration and build r3playx package.

```diff
/etc/nixos/configuration.nix (or anywhere you define your system package)

--  { config, pkgs, ... }:
++  { config, pkgs, r3playx, ... }:

    {
      imports =
        [ # Include the results of the hardware scan.
          ./hardware-configuration.nix
          ./configs/configs.nix
        ];

    ......

    environment.systemPackages = with pkgs; [
        ......
++      r3playx.packages."${pkgs.system}".r3playx
    ]

    ......

    }
```

3. Update your flake lock

In ```/etc/nixos```

```bash
sudo nix flake update
```

4. Rebuild your NixOS

In ```/etc/nixos/```

```bash
sudo nixos-rebuild switch --flake ./
```