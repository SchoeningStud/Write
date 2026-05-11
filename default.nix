{ lib
, stdenv
, pkg-config
, sdl3
, libGL
, roboto
, imagemagick
}:

stdenv.mkDerivation {
  pname = "styluslabs-write";
  version = "dev";

  src = ./.;

  hardeningDisable = [ "format" ];
  makeFlags = [
    "DEBUG=0"
    "USE_SYSTEM_SDL=1"
    "PKGS=sdl3"
  ];

  NIX_CFLAGS_COMPILE = [
    "-I${sdl3.dev}/include"
    "-I${sdl3.dev}/include/sdl3"
  ];

  postPatch = ''
    substituteInPlace ugui/svggui_platform.h \
      --replace '#include "SDL_config.h"' '#include "sdl3/SDL_config.h"'
  '';

  preBuild = ''
    makeFlagsArray+=(
      "GITREV=dev"
      "GITCOUNT=0"
    )
    pushd syncscribble
  '';

  postBuild = ''
    popd
  '';

  strictDeps = true;

  nativeBuildInputs = [
    imagemagick
    pkg-config
  ];

  buildInputs = [
    sdl3
    libGL
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,opt}
    install -m555 -D syncscribble/Release/Write $out/opt/
    install -m444 -D scribbleres/Intro.svg $out/opt/
    install -m444 -D scribbleres/fonts/DroidSansFallback.ttf $out/opt/
    ln -s ${roboto}/share/fonts/truetype/Roboto-Regular.ttf $out/opt/Roboto-Regular.ttf

    ln -s ../opt/Write $out/bin/Write

    for i in 16 24 48 64 96 128 256 512; do
      mkdir -p $out/share/icons/hicolor/''${i}x''${i}/apps
      magick scribbleres/write_512.png -resize ''${i}x''${i} $out/share/icons/hicolor/''${i}x''${i}/apps/styluslabs-write.png
    done

    install -Dm444 scribbleres/linux/Write.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/Write.desktop \
        --replace-fail 'Exec=/opt/Write/Write' 'Exec=Write' \
        --replace-fail 'Icon=Write144x144' 'Icon=styluslabs-write'
  '';

  enableParallelBuilding = true;

  meta = {
    homepage = "https://styluslabs.com/";
    description = "Cross-platform application for handwritten notes";
    license = with lib.licenses; [
      mit
      zlib
      agpl3Only
    ];
    platforms = lib.platforms.linux;
    mainProgram = "Write";
  };
}
