# This resource is incompatible with `busybox`.
{ buildGoPackage, fetchgitLocal, dockerTools, lib, docker, bash, cacert, jq,
  runCommand, coreutils, findutils, utillinux, gawk, gnused, gnugrep, iproute, gnutar,
  buildSlugs }:
let
  check = buildGoPackage {
    name = "concourse-docker-image-resource-check";
    goPackagePath = "github.com/concourse/docker-image-resource";
    subPackages = [ "cmd/check" "cmd/print-metadata" "vendor/github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cmd"];

    src = lib.cleanSourceWith {
      filter = name: type:
        !lib.hasSuffix ".nix" name
        || (type == "directory" && baseNameOf name == "ci");
      src = lib.cleanSource ./.;
    };
  };

  resources = runCommand "cp-resources-to-opt" { }  ''
    mkdir -p $out/opt/resource
    cd $out/opt/resource
    cp -r ${check}/bin/. ./.
    cp -r ${./assets}/. ./.
    patchShebangs .

    mkdir -p $out/bin
    cd $out/bin
    cp ${check}/bin/cmd ./docker-credential-ecr-login
  '';

  slug = dockerTools.buildImage {
    name = "concourse-docker-image-resource";
    tag = "latest";
    contents = [ coreutils findutils gawk gnused gnugrep utillinux iproute cacert
                 resources jq docker bash gnutar ];
  };
in buildSlugs [{
  name = "concourse-docker-image-resource";
  inherit slug;
}]
