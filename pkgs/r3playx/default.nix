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
  version = "2.7.5";

  inherit (lib) escapeShellArg;

  srcs = {
    x86_64-linux = fetchurl {
      url = "https://github.com/Sherlockouo/music/releases/download/${version}/R3PLAYX-${version}-linux-amd64.deb";
      hash = "sha256-KUEv2AIzBqlr+mTJdmxYCEiyhXi3DCZsdaVadAjXd8k=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/Sherlockouo/music/releases/download/${version}/R3PLAYX-${version}-linux-arm64.deb";
      hash = "sha256-YxRE/MgA0RJzjRq7iqzqLJTg3+qjkEUFXNmI/BRNvKI=";
    };
    x86_64-darwin = fetchurl {
      url = "https://github.com/Sherlockouo/music/releases/download/${version}/R3PLAYX-${version}-mac-x64.dmg";
      hash = "sha256-Wvx6PGaCXP+cOiU2bYEJMuby7ooU//oFlxkGnSIPz80=";
    };
    aarch64-darwin = fetchurl {
      url = "https://github.com/Sherlockouo/music/releases/download/${version}/R3PLAYX-${version}-mac-arm64.dmg";
      hash = "sha256-6zkHvqr33DYa+TMRFcGjwOmm2GtPnXBRRDEePWa1rdw=";
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

    runHook postInstall
  '';
  
  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libGL ]}"
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
      --add-flags ${lib.escapeShellArg commandLineArgs}
    )
  '';
}
