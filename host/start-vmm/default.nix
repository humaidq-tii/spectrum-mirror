# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix (
{ src, lib, stdenv, fetchCrate, fetchFromGitHub, fetchurl, buildPackages
, meson, ninja, rustc, clippy, run-spectrum-vm
}:

let
  packageCache = [
    (fetchCrate {
      pname = "itoa";
      version = "1.0.10";
      unpack = false;
      hash = "sha256-saRtGhcdhlql+D+SaVdlyqBHqbTLriy/N9vWE6eT/Uw=";
    })
    (fetchurl {
      name = "miniserde-0.1.37.tar.gz";
      url = "https://github.com/dtolnay/miniserde/archive/0.1.37.tar.gz";
      hash = "sha256-zE4WY6uI/7P7NaJyb2aZAnSL1rBSq5hAtx26151qUEk=";
    })
    (fetchCrate {
      pname = "proc-macro2";
      version = "1.0.78";
      unpack = false;
      hash = "sha256-4kIq1kXYnJn48+a4ip/eyn+r6sg2sQAjccQ2fI+YSq4=";
    })
    (fetchCrate {
      pname = "quote";
      version = "1.0.35";
      unpack = false;
      hash = "sha256-KR7Jq179k0qvUDpkZsXVJRU10QjudHRyw5d8xazIaO8=";
    })
    (fetchCrate {
      pname = "ryu";
      version = "1.0.17";
      unpack = false;
      hash = "sha256-6GaXyRYBmoWIyZtfrDzq107AtLgZcHpoL9TSP6DOG6E=";
    })
    (fetchCrate {
      pname = "syn";
      version = "2.0.41";
      unpack = false;
      hash = "sha256-RMiyjEd8w78OeWZWHjRgEw4SVfehz3GTEHXxxeen4mk=";
    })
    (fetchCrate {
      pname = "unicode-ident";
      version = "1.0.12";
      unpack = false;
      hash = "sha256-M1S5rD+uH/Z1XLbbU2g622YWNPZ1V5Qt6k+s6+wP7ks=";
    })
  ];
in

stdenv.mkDerivation (finalAttrs: {
  name = "start-vmm";

  src = lib.fileset.toSource {
    root = ../..;
    fileset = lib.fileset.intersection src ./.;
  };
  sourceRoot = "source/host/start-vmm";

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ meson ninja rustc ];

  postPatch = lib.concatMapStringsSep "\n" (crate: ''
    mkdir -p subprojects/packagecache
    ln -s ${crate} subprojects/packagecache/${crate.name}
  '') packageCache;

  preConfigure = ''
    mesonFlagsArray+=(-Drust_args="-C panic=abort" -Dtests=false -Dwerror=true)
  '';

  passthru.tests = {
    clippy = finalAttrs.finalPackage.overrideAttrs (
      { name, nativeBuildInputs ? [], ... }:
      {
        name = "${name}-clippy";
        nativeBuildInputs = nativeBuildInputs ++ [ clippy ];
        RUSTC = "clippy-driver";
        preConfigure = ''
          # It's not currently possible to enable warnings only for
          # non-subprojects without enumerating the subprojects.
          # https://github.com/mesonbuild/meson/issues/9398#issuecomment-954094750
          mesonFlagsArray+=(
              -Dwerror=true
              -Dproc-macro2:werror=false
              -Dproc-macro2:warning_level=0
          )
        '';
        postBuild = ''touch $out && exit 0'';
      }
    );

    run = run-spectrum-vm.override { start-vmm = finalAttrs.finalPackage; };

    tests = finalAttrs.finalPackage.overrideAttrs ({ name, ... }: {
      name = "${name}-tests";
      preConfigure = "";
      doCheck = true;
    });
  };

  meta = {
    mainProgram = "start-vmm";
  };
})
) (_: {})