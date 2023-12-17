# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

{ ... } @ args:

let
  config = import ../lib/config.nix args;
  pkgs = import ./overlaid.nix ({ elaboratedConfig = config; } // args);

  inherit (pkgs.lib) cleanSource fileset makeScope optionalAttrs;

  scope = self: let pkgs = self.callPackage ({ pkgs }: pkgs) {}; in {
    inherit config;

    callSpectrumPackage =
      path: (import path { inherit (self) callPackage; }).override;

    lseek = self.callSpectrumPackage ../tools/lseek {};
    rootfs = self.callSpectrumPackage ../host/rootfs {};
    start-vm = self.callSpectrumPackage ../host/start-vm {};

    # Packages from the overlay, so it's possible to build them from
    # the CLI easily.
    inherit (pkgs) cloud-hypervisor foot;

    pkgsStatic = makeScope pkgs.pkgsStatic.newScope scope;

    srcWithNix = fileset.difference
      (fileset.fromSource (cleanSource ../.))
      (fileset.unions (map fileset.maybeMissing [
        ../Documentation/.jekyll-cache
        ../Documentation/_site
        ../Documentation/diagrams/stack.svg
        ../host/initramfs/build
        ../host/rootfs/build
        ../img/app/build
        ../release/live/build
        ../vm/sys/net/build
      ]));

    src = fileset.difference
      self.srcWithNix
      (fileset.fileFilter ({ hasExt, ... }: hasExt "nix") ../.);
  };
in

pkgs.makeScopeWithSplicing' {
  otherSplices = {
    selfBuildBuild = makeScope pkgs.pkgsBuildBuild.newScope scope;
    selfBuildHost = makeScope pkgs.pkgsBuildHost.newScope scope;
    selfBuildTarget = makeScope pkgs.pkgsBuildTarget.newScope scope;
    selfHostHost = makeScope pkgs.pkgsHostHost.newScope scope;
    selfTargetTarget = optionalAttrs (pkgs.pkgsTargetTarget ? newScope)
      (makeScope pkgs.pkgsTargetTarget.newScope scope);
  };
  f = scope;
}
