{ lib, stdenv
, fetchurl
, dpkg
, undmg
, makeWrapper
, nodePackages
, alsaLib
, at-spi2-atk
, at-spi2-core
, atk
, cairo
, cups
, curl
, dbus
, expat
, fontconfig
, freetype
, gdk-pixbuf
, glib
, gnome2
, gtk3
, libappindicator-gtk3
, libdrm
, libnotify
, libpulseaudio
, libuuid
, libxcb
, libxkbcommon
, libxshmfence
, mesa
, nspr
, nss
, pango
, sigtool
, systemd
, xdg-utils
, xorg
}:

let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  pname = "slack";

  x86_64-darwin-version = "4.16.0";
  x86_64-darwin-sha256 = "078f49sgazfa99vn0yyacfya3jl2vhqz7kgxh0qp56b66pnzwbxz";

  x86_64-linux-version = "4.16.0";
  x86_64-linux-sha256 = "0dj5k7r044mibis0zymh6wryhbw2fzsch30nddfrnn6ij89hhirv";

  aarch64-darwin-version = "4.16.0";
  aarch64-darwin-sha256 = "sha256-tR8tSU9tqtkwMRR+aI8kXQo0RH6c6pGvwPryZVRNYXc=";

  version = {
    x86_64-darwin = x86_64-darwin-version;
    x86_64-linux = x86_64-linux-version;
    aarch64-darwin =  aarch64-darwin-version;
  }.${system} or throwSystem;

  src = let
    base = "https://downloads.slack-edge.com";
  in {
    x86_64-darwin = fetchurl {
      url = "${base}/releases/macos/${version}/prod/x64/Slack-${version}-macOS.dmg";
      sha256 = x86_64-darwin-sha256;
    };
    x86_64-linux = fetchurl {
      url = "${base}/linux_releases/slack-desktop-${version}-amd64.deb";
      sha256 = x86_64-linux-sha256;
    };
    aarch64-darwin = fetchurl {
      url = "${base}/releases/macos/${version}/prod/arm64/Slack-${version}-macOS.dmg";
      sha256 = aarch64-darwin-sha256;
    };
  }.${system} or throwSystem;

  meta = with lib; {
    description = "Desktop client for Slack";
    homepage = "https://slack.com";
    license = licenses.unfree;
    maintainers = with maintainers; [ mmahut ];
    platforms = [ "x86_64-darwin" "x86_64-linux" "aarch64-darwin" ];
  };

  linux = stdenv.mkDerivation rec {
    inherit pname version src meta;

    passthru.updateScript = ./update.sh;

    rpath = lib.makeLibraryPath [
      alsaLib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      curl
      dbus
      expat
      fontconfig
      freetype
      gdk-pixbuf
      glib
      gnome2.GConf
      gtk3
      libappindicator-gtk3
      libdrm
      libnotify
      libpulseaudio
      libuuid
      libxcb
      libxkbcommon
      mesa
      nspr
      nss
      pango
      stdenv.cc.cc
      systemd
      xorg.libX11
      xorg.libXScrnSaver
      xorg.libXcomposite
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXi
      xorg.libXrandr
      xorg.libXrender
      xorg.libxshmfence
      xorg.libXtst
      xorg.libxkbfile
    ] + ":${stdenv.cc.cc.lib}/lib64";

    buildInputs = [
      gtk3  # needed for GSETTINGS_SCHEMAS_PATH
    ];

    nativeBuildInputs = [ dpkg makeWrapper nodePackages.asar ];

    dontUnpack = true;
    dontBuild = true;
    dontPatchELF = true;

    installPhase = ''
      # The deb file contains a setuid binary, so 'dpkg -x' doesn't work here
      dpkg --fsys-tarfile $src | tar --extract
      rm -rf usr/share/lintian

      mkdir -p $out
      mv usr/* $out

      # Otherwise it looks "suspicious"
      chmod -R g-w $out

      for file in $(find $out -type f \( -perm /0111 -o -name \*.so\* \) ); do
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$file" || true
        patchelf --set-rpath ${rpath}:$out/lib/slack $file || true
      done

      # Replace the broken bin/slack symlink with a startup wrapper
      rm $out/bin/slack
      makeWrapper $out/lib/slack/slack $out/bin/slack \
        --prefix XDG_DATA_DIRS : $GSETTINGS_SCHEMAS_PATH \
        --prefix PATH : ${xdg-utils}/bin

      # Fix the desktop link
      substituteInPlace $out/share/applications/slack.desktop \
        --replace /usr/bin/ $out/bin/ \
        --replace /usr/share/ $out/share/
    '';
  };

  darwin = stdenv.mkDerivation {
    inherit pname version src meta;

    passthru.updateScript = ./update.sh;

    nativeBuildInputs = [ undmg ] ++ lib.optional stdenv.isAarch64 [ sigtool ];

    sourceRoot = "Slack.app";

    installPhase = ''
      mkdir -p $out/Applications/Slack.app
      cp -R . $out/Applications/Slack.app
    '' + lib.optionalString (!stdenv.isAarch64) ''
      /usr/bin/defaults write com.tinyspeck.slackmacgap SlackNoAutoUpdates -Bool YES
    '';
  };
in if stdenv.isDarwin
  then darwin
  else linux
