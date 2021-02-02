#!/usr/bin/env bash

# nix-build '<nixpkgs/nixos>' -A config.system.build.qcow2 --arg configuration "{ imports = [ ./build-qcow2.nix ]; }"

GC_DONT_GC=1  nix-build '<nixpkgs/nixos>' -A config.system.build.qcow2 -I nixos-config=./build-qcow2.nix
