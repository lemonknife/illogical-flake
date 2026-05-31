inputs:

{ config, lib, pkgs, ... }:

let
  cfg = config.programs.illogical-impulse;

  # Custom packages
  customPkgs = import ../pkgs { inherit pkgs; };

  # Python environment for quickshell wallpaper analysis
  pythonEnv = pkgs.python3.withPackages (ps: [
    ps.build
    ps.cffi
    ps.click
    ps."dbus-python"
    ps."kde-material-you-colors"
    ps.libsass
    ps.loguru
    ps."material-color-utilities"
    ps.materialyoucolor
    ps.numpy
    ps.pillow
    ps.psutil
    ps.pycairo
    ps.pygobject3
    ps.pywayland
    ps.setproctitle
    ps."setuptools-scm"
    ps.tqdm
    ps.wheel
    ps."pyproject-hooks"
    ps.opencv4
  ]);

  patchedPapirus = pkgs.papirus-icon-theme.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      echo "Applying Illogical Impulse patches to Papirus..."

      # 1. 移除对 breeze 的继承，替换为 Adwaita (避免找不到基础图标)
      for theme in $out/share/icons/Papirus*; do
        if [ -f "$theme/index.theme" ]; then
          sed -i 's/Inherits=breeze-dark,/Inherits=Adwaita,/g' "$theme/index.theme"
          sed -i 's/Inherits=breeze-light,/Inherits=Adwaita,/g' "$theme/index.theme"
          sed -i 's/Inherits=breeze,/Inherits=Adwaita,/g' "$theme/index.theme"
        fi
      done

      # 2. 修复 Wayland/部分文件管理器下缺失的文件夹图标
      for size_dir in $out/share/icons/Papirus*/*/places; do
        if [ -d "$size_dir" ] && [ -f "$size_dir/folder.svg" ]; then
          if [ ! -e "$size_dir/inode-directory.svg" ]; then
            ln -sf folder.svg "$size_dir/inode-directory.svg"
          fi
        fi
      done
    '';
  });
in
{
  # Export pythonEnv for use in other modules
  options.programs.illogical-impulse.internal.pythonEnv = lib.mkOption {
    type = lib.types.package;
    internal = true;
    default = pythonEnv;
  };

  config = lib.mkIf cfg.enable {
    # User packages for Illogical Impulse
    home.packages = with pkgs; [
      # Core utilities
      cava
      lxqt.pavucontrol-qt
      wireplumber
      libdbusmenu-gtk3
      playerctl
      brightnessctl
      ddcutil
      axel
      bc
      cliphist
      curl
      rsync
      wget
      libqalculate
      ripgrep
      jq
      yq-go
      inetutils
      songrec

      # GUI applications
      foot
      fuzzel
      matugen
      mpv
      mpvpaper
      swappy
      wf-recorder
      hyprshot
      wlogout

      # System utilities
      xdg-user-dirs
      tesseract
      slurp
      upower
      wtype
      ydotool
      glib
      swww
      translate-shell
      hyprpicker
      imagemagick
      ffmpeg
      gnome-settings-daemon  # Provides gsettings
      libnotify  # Provides notify-send
      easyeffects
      grim
      xorg.xlsclients

      # Wayland/Hyprland specific
      hyprlock
      hypridle
      hyprsunset
      wayland-protocols
      wl-clipboard

      # Development libraries
      libsoup_3
      libportal-gtk4
      gobject-introspection
      sassc
      # opencv is included in pythonEnv, no need to include it separately

      # Themes and icons
      adw-gtk3
      customPkgs.illogical-impulse-oneui4-icons
      customPkgs.breeze-plus
      patchedPapirus            # Primary icon theme
      adwaita-icon-theme  # GNOME fallback icons
      hicolor-icon-theme  # Base icon theme (required by most themes)
      gnome-icon-theme  # Additional GNOME icon coverage
      kdePackages.breeze-icons  # KDE Breeze icons (required by Papirus inheritance)
      inputs.darkly.packages.${pkgs.stdenv.hostPlatform.system}.darkly-qt5
      inputs.darkly.packages.${pkgs.stdenv.hostPlatform.system}.darkly-qt6

      # Python with required packages for wallpaper analysis
      pythonEnv
      eza  # Modern ls replacement

      # Minimal Qt/KDE packages (only what's needed for functionality)
      gnome-keyring  # Keyring support
      kdePackages.bluedevil  # Bluetooth management (for kcm_bluetooth)
      kdePackages.plasma-nm  # Network management (for kcm_networkmanagement)
      kdePackages.polkit-kde-agent-1  # Polkit authentication agent
      kdePackages.kdialog  # Dialog prompts
      kdePackages.kirigami
      kdePackages.kconfig

      # Additional Qt support
      libsForQt5.qtgraphicaleffects
      libsForQt5.qtsvg
      # for quickshell key store
      libsecret
    ] ++ lib.optionals cfg.dotfiles.fish.enable [
      fish
    ] ++ lib.optionals cfg.dotfiles.kitty.enable [
      kitty
    ] ++ lib.optionals cfg.dotfiles.starship.enable [
      starship
    ];
  };
}
