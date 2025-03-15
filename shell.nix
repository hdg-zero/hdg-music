{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "youtube-music-downloader";
  buildInputs = [
    pkgs.ffmpeg
    pkgs.yt-dlp
  ];

  shellHook = ''
    echo "Environnement Nix prêt !"
  '';
}