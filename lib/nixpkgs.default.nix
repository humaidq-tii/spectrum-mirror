# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

# Generated by scripts/update-nixpkgs.sh.

import (builtins.fetchTarball {
  url = "https://spectrum-os.org/git/nixpkgs/snapshot/nixpkgs-bcaa21f4708228284ca3b26f19594565804b8e18.tar.gz";
  sha256 = "09zmahbz1j1gl8ipiq4l8xz5g6fq41nz27dfllma3v42hkaxbgi4";
})
