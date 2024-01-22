{ lib
, stdenv
, fetchurl
, undmg
, dpkg
, expat
, autoPatchelfHook
, commandLineArgs ? ""
, wrapGAppsHook
, makeWrapper
, alsa-lib
, at-spi2-atk
, cairo
, cups
, nspr
, nss
, mesa # for libgbm
, pango
, xorg
, xdg-utils
, libdrm
, libGL
, libglvnd
, libnotify
, libsecret
, libuuid
, libxcb
, libxkbcommon
, gtk3
, systemd
}:
let
  pname = "r3playx";
  version = "2.7.4";

  inherit (lib) escapeShellArg;

  srcs = {
    x86_64-linux = fetchurl {
      url = "https://github.com/Sherlockouo/music/releases/download/${version}/R3PLAYX-${version}-linux-amd64.deb";
      hash = "sha256-LQOPFspu+Sfbz1LKo8Iw186DCoemK6gO1AWqaC2fCdE=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/Sherlockouo/music/releases/download/${version}/R3PLAYX-${version}-linux-arm64.deb";
      hash = "sha256-gcLu8zX6FEEHjyjEB+oHVXegMRjnCmWiT+Vl7c94wpI=";
    };
    x86_64-darwin = fetchurl {
      url = "https://github.com/Sherlockouo/music/releases/download/${version}/R3PLAYX-${version}-mac-x64.dmg";
      hash = "sha256-wnt+m5wqQ1tvZEMVDRsf2GNHgt3+pUb2vamwVJa5vOs=";
    };
    aarch64-darwin = fetchurl {
      url = "https://github.com/Sherlockouo/music/releases/download/${version}/R3PLAYX-${version}-mac-arm64.dmg";
      hash = "sha256-gr2gFpolFUjj3k4Whtseq1nIubbWdbucmkhE43pEw6Y=";
    };
  };
  src = srcs.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  libraries = [
    alsa-lib
    at-spi2-atk
    cups
    expat
    nspr
    nss
    mesa
    pango
    xorg.libxshmfence
    xorg.libXScrnSaver
    xorg.libXtst
    xdg-utils
    libdrm
    libGL
    libglvnd
    libnotify
    libsecret
    libuuid
    libxcb
    libxkbcommon
    gtk3
  ];

  meta = with lib; {
    description = "A music player forked from YesPlayMusic";
    homepage = "https://github.com/Sherlockouo/music";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ ChaosAttractor ];
    platforms = builtins.attrNames srcs;
  };
in
if stdenv.isDarwin
then stdenv.mkDerivation {
  inherit pname version src meta;

  nativeBuildInputs = [ undmg ];

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/Applications
    cp -r *.app $out/Applications
  '';
}
else stdenv.mkDerivation {
  inherit pname version src meta;

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook
    makeWrapper
  ];

  buildInputs = libraries;

  runtimeDependencies = [
    (lib.getLib systemd)
  ];

  unpackPhase = ''
    ${dpkg}/bin/dpkg-deb -x $src .
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -r opt $out/opt
    cp -r usr/share $out/share
    mv $out/share/applications/desktop.desktop $out/share/applications/r3playx.desktop
    substituteInPlace $out/share/applications/r3playx.desktop \
      --replace "/opt/R3PLAYX/desktop" "$out/bin/r3playx"
    makeWrapper $out/opt/R3PLAYX/desktop $out/bin/r3playx \
      --argv0 "r3playx" \
      --add-flags "$out/opt/R3PLAYX/resources/app.asar"

    # patch r3playx binary
    interpreter="$(cat $NIX_BINTOOLS/nix-support/dynamic-linker)"
    patchelf --set-interpreter $interpreter $out/opt/R3PLAYX/desktop

    ln -s $(libGL)/lib/libGL.so.1 $out/opt/R3PLAYX/libGL.so.1
    ln -s $out/opt/R3PLAYX/libEGL.so $out/opt/R3PLAYX/libEGL.so.1
    patchelf --add-needed libGL.so.1 $out/opt/R3PLAYX/desktop
    patchelf --add-needed libEGL.so.1 $out/opt/R3PLAYX/desktop

    runHook postInstall
  '';
  
  preFixup = ''
    gappsWrapperArgs+=(
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
      --add-flags ${lib.escapeShellArg commandLineArgs}
    )
  '';
}
