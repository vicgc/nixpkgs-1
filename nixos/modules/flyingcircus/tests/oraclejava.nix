import ../../../tests/make-test.nix ({ ... }:
{
  name = "oraclejava";
  # This test does *not* really install or test java, but causes the
  # dependencies to be built.

  nodes = {
    master =
      { pkgs, config, ... }:
      {


        virtualisation.memorySize = 512;
        environment.systemPackages = with pkgs; [
          alsaLib
          atk
          cairo
          ffmpeg
          fontconfig
          freetype
          gdk_pixbuf
          glib
          gnome.gtk
          gnome.pango
          libav_0_8
          libxml2
          libxslt
          mesa_noglu
          xorg.libXxf86vm
        ];
      };
  };

  testScript = ''
    startAll;
  '';
})
