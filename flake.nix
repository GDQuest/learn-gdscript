{
  description = "Interactive GDScript learning tool by GDQuest";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      version = "1.5.2";
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      learn-gdscript = pkgs.stdenvNoCC.mkDerivation {
        pname = "learn-gdscript";
        inherit version;
        src = pkgs.fetchurl {
          url = "https://github.com/GDQuest/learn-gdscript/releases/download/${version}/learn-gdscript-${version}-linux.zip";
          hash = "sha256-AvP37Kfiuhhx7K44EGRlo/pu9L+STj6O/3Y+VERCxMI=";
        };
        icon = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/GDQuest/learn-gdscript/main/icon.png";
          hash = "sha256-3U0OMEn+uvxsTvU89qC+xesqce9OhbNXtccUAkI0Lqo=";
        };
        nativeBuildInputs = [ pkgs.unzip pkgs.autoPatchelfHook pkgs.makeWrapper ];
        buildInputs = with pkgs; [
          libGL libx11 libxcursor libxinerama libxrandr
          libxrender libxext libxi alsa-lib libpulseaudio
          stdenv.cc.cc.lib udev
        ];
        unpackPhase = "unzip $src";
        installPhase = ''
          mkdir -p $out/bin $out/share/learn-gdscript $out/share/applications $out/share/pixmaps
          cp learn_to_code.x86_64 learn_to_code.pck $out/share/learn-gdscript/
          cp $icon $out/share/pixmaps/learn-gdscript.png
          chmod +x $out/share/learn-gdscript/learn_to_code.x86_64
          makeWrapper $out/share/learn-gdscript/learn_to_code.x86_64 $out/bin/learn-gdscript \
            --chdir "$out/share/learn-gdscript" \
            --prefix LD_LIBRARY_PATH : "${pkgs.alsa-lib}/lib:${pkgs.libpulseaudio}/lib:${pkgs.udev}/lib"
          cat > $out/share/applications/learn-gdscript.desktop << EOF
          [Desktop Entry]
          Name=Learn GDScript
          Comment=Interactive GDScript learning tool by GDQuest
          Exec=$out/bin/learn-gdscript
          Icon=$out/share/pixmaps/learn-gdscript.png
          Type=Application
          Categories=Education;Development;
          EOF
        '';
        meta = with pkgs.lib; {
          description = "Interactive GDScript learning tool by GDQuest";
          homepage = "https://github.com/GDQuest/learn-gdscript";
          license = licenses.mit;
          platforms = [ "x86_64-linux" ];
          mainProgram = "learn-gdscript";
        };
      };
    in {
      packages.${system} = {
        default = learn-gdscript;
        learn-gdscript = learn-gdscript;
      };
      apps.${system}.default = {
        type = "app";
        program = "${learn-gdscript}/bin/learn-gdscript";
      };
    };
}
