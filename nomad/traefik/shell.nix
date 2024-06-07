let
  config = {
    allowUnfree = true;
  };
  pkgs = import <nixpkgs> { inherit config; };
in
with pkgs;
stdenv.mkDerivation rec {
    name = "traefik-on-nomad";
    env = buildEnv {
      name = name;
      paths = buildInputs;
    };
    buildInputs = [
      consul
      nomad
    ];

    shellHook = ''
      export NOMAD_ADDR=http://127.0.0.1:4646
    '';
}

