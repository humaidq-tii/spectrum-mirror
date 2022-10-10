# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>

{ config ? import ../../../nix/eval-config.nix {} }:

import ../make-vm.nix { inherit config; } {
  providers.net = [ "netvm" ];
  sharedDirs.virtiofs0.path = "/ext";
  run = "${config.pkgs.pkgsStatic.mg}/bin/mg";
}
