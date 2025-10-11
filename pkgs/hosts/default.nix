{ stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "hosts";
  version = "3.16.24";

  src = fetchFromGitHub {
    owner = "StevenBlack";
    repo = "hosts";
    rev = finalAttrs.version;
    hash = "sha256-LL91oKfSC1TV+bFwFFqnrDnbDnn+FukaFEQ8Ma4BJjo=";
  };

  buildPhase = ''
    runHook preBuild
    cat << EOF > hosts.zone
    \$ORIGIN  .
    @        SOA  @ rpz.nevi.network 0 86400 7200 2592000 86400
    @        NS   localhost
    EOF
    awk '$1 == "0.0.0.0" { print $2, "CNAME", "." }' hosts >> hosts.zone
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 -t $out hosts.zone
    runHook postInstall
  '';
})
