{
  callPackage,
  stdenv,
  fetchFromGitLab,
  perl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "isc-dhcp";
  version = "4.4.3";

  src = fetchFromGitLab {
    domain = "gitlab.isc.org";
    owner = "isc-projects";
    repo = "dhcp";
    tag = "v4_4_3";
    hash = "sha256-ElyesVfWeIXh/rW7PRjWmqNyvTx2D4fWi/emTZkC9i4=";
  };

  enableParallelBuilding = true;
  nativeBuildInputs = [ perl ];

  passthru.image = callPackage ./image.nix { };
})
