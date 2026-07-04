{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {
  pname = "breeze-plus";
  version = "6.2.5";

  src = fetchFromGitHub {
    owner = "mjkim0727";
    repo = "breeze-plus";
    rev = "HEAD";
    hash = "sha256-HyXf0Bn6Z9tOy1jncFHqZctNdqW6GQIH8hYdhDsKPCQ=";
  };

  installPhase = ''
    mkdir -p $out/share/icons
    cp -r src/breeze-plus* $out/share/icons/
  '';

  meta = {
    description = "Breeze theme with additional icons ";
    homepage = "https://github.com/mjkim0727/breeze-plus";
    license = lib.licenses.lgpl21;
    platforms = lib.platforms.all;
  };
}
