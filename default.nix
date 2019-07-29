{ buildGoPackage, fetchgitLocal, dockerTools, lib, docker, bash, busybox, cacert, jq, runCommand }:
let
  check = buildGoPackage {
    name = "concourse-docker-image-resource-check";
    goPackagePath = "github.com/concourse/docker-image-resource";
    subPackages = [ "cmd/check" "cmd/print-metadata" "vendor/github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cmd"];

    src = lib.cleanSourceWith {
      filter = name: type: !lib.hasSuffix ".nix" name;
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

  image = dockerTools.buildLayeredImage {
    name = "concourse-docker-image-resource";
    tag = "latest";
    contents = [ busybox cacert resources jq docker bash ];
  };
in image
