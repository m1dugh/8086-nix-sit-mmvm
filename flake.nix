{
  description = "A nix flake for 8086 emulator project";

  outputs = {
  self,
  nixpkgs,
  ...
  }: 
  let supportedSystems = ["x86_64-linux"];
    inherit (nixpkgs) lib;
    forAllSystems = lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems(system: import nixpkgs {
        inherit system;
    });
  in {
    
    packages = forAllSystems(system: 
    let pkgs = nixpkgsFor.${system};
    in {
        setuptools = 
        let fixedMakefileInc = "${self}/nix-fix.inc";
        in pkgs.stdenv.mkDerivation {

            src = pkgs.fetchurl {
                url = "http://www.fd.ise.shibaura-it.ac.jp/downloads/setuptools.tar.gz";
                hash = "sha256-TBpypBGL6KYS4kwGwohEdEyCTNNeQIF41EOgfZHdlj4=";
            };

            name = "setuptools";

            buildPhase = "echo test";

            installPhase = ''
                mkdir -p $out/
                cp -R ./minix2/ $out/minix2/
                cp -R ./mmvm/ $out/mmvm/
                cp -R ./Makefile $out/Makefile
                cp -R ${fixedMakefileInc} $out/Makefile.inc
            '';
        };

        mmvm = pkgs.stdenv.mkDerivation {
            name = "mmvm";
            src = self.packages.${system}.setuptools;

            propagatedBuildInputs = with pkgs; [
                gcc
                gnumake
                makeWrapper
                stdenv.cc.cc.lib
            ];

            buildPhase = ''
                make
            '';

            installPhase = ''
                mkdir -p $out/bin
                install -m 755 ./mmvm/mmvm $out/bin/mmvm
            '';

            postFixup = ''
                wrapProgram $out/bin/mmvm \
                    --set LD_LIBRARY_PATH ${lib.makeLibraryPath (with pkgs; [stdenv.cc.cc.lib])}
            '';
        };

        minix2-env = 
        let inherit (self.packages.${system}) mmvm;
        in pkgs.stdenv.mkDerivation {
            name = "minix2-env";
            src = self.packages.${system}.setuptools;

            nativeBuildInputs = [
                mmvm
            ];

            buildPhase = ''
                pushd ./minix2
                make
                popd
            '';

            installPhase = ''
                mkdir -p $out/
                cp -R ./minix2/local/core/minix2/* $out/
            '';
        };

        minix2 = 
        let exports = [
            "usr/bin/cc"
            "usr/bin/nm"
            "usr/bin/strip"
            "usr/bin/ar"
            "usr/bin/crc"
            "usr/lib/as"
            "usr/lib/ld"
            "usr/lib/cv"
        ]; 
        prefix = "m2";
        inherit (self.packages.${system}) mmvm minix2-env;
        in pkgs.stdenv.mkDerivation {

            name = "minix2";
            src = self;

            nativeBuildInputs = [
                mmvm
                minix2-env
            ];

            installPhase = ''
                mkdir -p $out/bin/
                root=${minix2-env}
                ln -s ${mmvm}/bin/mmvm $out/bin/mmvm
                for path in ${lib.concatStringsSep " " exports}; do
                    final_path="$out/bin/${prefix}''${path##*/}"; # IDE debug "
                    echo '#!/usr/bin/env bash' > $final_path;
                    echo 'opts=""' >> $final_path;
                    echo 'if [ $# -ge 1 ] && [ $1 = "--m" ];then opts="-m"; fi' >> $final_path;
                    echo "${mmvm}/bin/mmvm \$opts -r ${minix2-env} ${minix2-env}/$path \"\$@\"" >> $final_path; # IDE debug "
                    chmod 755 $final_path;
                done;
            '';
        };

        default = self.packages.${system}.minix2;
    });

    apps = 
    let programs = [
        "m2cc"
        "mmvm"
        "m2crc"
        "m2strip"
        "m2ar"
        "m2nm"
    ];
    forAllPrograms = lib.genAttrs programs;
    in forAllSystems(system: 
    let inherit (self.packages.${system}) minix2;
    in forAllPrograms(program: {
        type = "app";
        program = "${minix2}/bin/${program}";
    }));
  };
}
