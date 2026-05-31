inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkOption types mkIf mkDefault;
  cfg = config.programs.illogical-impulse;

  # Use dotfiles from flake input
  dotfilesSource = inputs.dotfiles;

  # Custom packages
  customPkgs = import ../pkgs { inherit pkgs; };
  oneUIIconsPath = "${customPkgs.illogical-impulse-oneui4-icons}/share/icons";
in
{
  options.programs.illogical-impulse.dotfiles = {
    # 终端与 Shell
    fish.enable = mkEnableOption "fish config" // { default = true; };
    kitty.enable = mkEnableOption "kitty config" // { default = true; };
    starship.enable = mkEnableOption "starship config" // { default = true; };
    zshrc.enable = mkEnableOption "zshrc config" // { default = true; };
    foot.enable = mkEnableOption "foot config" // { default = true; };
    konsolerc.enable = mkEnableOption "konsolerc config" // { default = true; };

    # 桌面与核心组件 (Hyprland 生态拆分)
    hyprland.enable = mkEnableOption "hyprland base config" // { default = true; };
    hyprlock.enable = mkEnableOption "hyprlock config" // { default = true; };
    hypridle.enable = mkEnableOption "hypridle config" // { default = true; };
    
    quickshell.enable = mkEnableOption "quickshell config" // { default = true; };
    wlogout.enable = mkEnableOption "wlogout config" // { default = true; };
    fuzzel.enable = mkEnableOption "fuzzel config" // { default = true; };
    xdg-desktop-portal.enable = mkEnableOption "xdg-desktop-portal config" // { default = true; };

    # 主题、外观与字体
    fontconfig.enable = mkEnableOption "fontconfig" // { default = true; };
    kde-material-you-colors.enable = mkEnableOption "kde-material-you-colors" // { default = true; };
    kdeglobals.enable = mkEnableOption "kdeglobals" // { default = true; };
    Kvantum.enable = mkEnableOption "Kvantum" // { default = true; };
    matugen.enable = mkEnableOption "matugen config" // { default = true; };
    darklyrc.enable = mkEnableOption "darklyrc" // { default = true; };
    dolphinrc.enable = mkEnableOption "dolphinrc" // { default = true; };

    # 浏览器与其他应用
    chrome-flags.enable = mkEnableOption "chrome-flags" // { default = true; };
    thorium-flags.enable = mkEnableOption "thorium-flags" // { default = true; };
    code-flags.enable = mkEnableOption "code-flags" // { default = true; };
    mpv.enable = mkEnableOption "mpv config" // { default = true; };
  };

  options.programs.illogical-impulse.hyprland = {
    plugins = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Hyprland plugins to install and load via hl.plugin()";
    };
  };

  config = mkIf cfg.enable {
    # Shell programs
    programs.fish.enable = cfg.dotfiles.fish.enable;
    programs.starship.enable = cfg.dotfiles.starship.enable;

    # Install plugin .so files into the user environment
    home.packages = cfg.hyprland.plugins;

    # ==========================================
    # 核心重构：细粒度纯声明式配置映射
    # ==========================================
    xdg.configFile = {
      # 终端与 Shell
      "fish" = mkIf cfg.dotfiles.fish.enable { source = "${dotfilesSource}/dots/.config/fish"; };
      "kitty" = mkIf cfg.dotfiles.kitty.enable { source = "${dotfilesSource}/dots/.config/kitty"; };
      "starship.toml" = mkIf cfg.dotfiles.starship.enable { source = "${dotfilesSource}/dots/.config/starship.toml"; };
      "zshrc.d" = mkIf cfg.dotfiles.zshrc.enable { source = "${dotfilesSource}/dots/.config/zshrc.d"; };
      "foot" = mkIf cfg.dotfiles.foot.enable { source = "${dotfilesSource}/dots/.config/foot"; };
      "konsolerc" = mkIf cfg.dotfiles.konsolerc.enable { source = "${dotfilesSource}/dots/.config/konsolerc"; };

      # ------------------------------------------
      # Hyprland 生态精细化映射
      # ------------------------------------------
      
      # 1. Hypridle
      "hypr/hypridle.conf" = mkIf cfg.dotfiles.hypridle.enable { source = "${dotfilesSource}/dots/.config/hypr/hypridle.conf"; };
      
      # 2. Hyprlock
      "hypr/hyprlock.conf" = mkIf cfg.dotfiles.hyprlock.enable { source = "${dotfilesSource}/dots/.config/hypr/hyprlock.conf"; };
      "hypr/hyprlock" = mkIf cfg.dotfiles.hyprlock.enable { source = "${dotfilesSource}/dots/.config/hypr/hyprlock"; };

      # 3. Hyprland 根目录文件
      "hypr/hyprland.lua" = mkIf cfg.dotfiles.hyprland.enable { source = "${dotfilesSource}/dots/.config/hypr/hyprland.lua"; };

      # 4. Hyprland/custom 目录 (隔离出 env.lua 和 general.lua 以便动态生成)
      "hypr/custom/execs.lua" = mkIf cfg.dotfiles.hyprland.enable { source = "${dotfilesSource}/dots/.config/hypr/custom/execs.lua"; };
      "hypr/custom/keybinds.lua" = mkIf cfg.dotfiles.hyprland.enable { source = "${dotfilesSource}/dots/.config/hypr/custom/keybinds.lua"; };
      "hypr/custom/rules.lua" = mkIf cfg.dotfiles.hyprland.enable { source = "${dotfilesSource}/dots/.config/hypr/custom/rules.lua"; };
      "hypr/custom/scripts" = mkIf cfg.dotfiles.hyprland.enable { source = "${dotfilesSource}/dots/.config/hypr/custom/scripts"; };
      "hypr/custom/variables.lua" = mkIf cfg.dotfiles.hyprland.enable { source = "${dotfilesSource}/dots/.config/hypr/custom/variables.lua"; };

      # 动态覆盖: custom/env.lua
      "hypr/custom/env.lua" = mkIf cfg.dotfiles.hyprland.enable {
        text = ''
          -- Generated by illogical-flake Nix config. Do not edit manually.
          local home_dir = os.getenv("HOME") or ""
          local user     = os.getenv("USER") or ""

          hl.env("PATH",
            home_dir .. "/.nix-profile/bin" ..
            ":/etc/profiles/per-user/" .. user .. "/bin" ..
            ":" .. (os.getenv("PATH") or "/usr/local/bin:/usr/bin:/bin"))

          hl.env("XDG_DATA_DIRS",
            home_dir .. "/.local/share" ..
            ":" .. home_dir .. "/.nix-profile/share" ..
            ":/etc/profiles/per-user/" .. user .. "/share" ..
            ":/run/current-system/sw/share" ..
            ":" .. home_dir .. "/.local/share/flatpak/exports/share" ..
            ":/var/lib/flatpak/exports/share" ..
            ":/usr/local/share:/usr/share")

          hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
        '';
      };

      # 动态追加: custom/general.lua (读取上游配置并拼接插件列表)
      "hypr/custom/general.lua" = mkIf cfg.dotfiles.hyprland.enable {
        text = (builtins.readFile "${dotfilesSource}/dots/.config/hypr/custom/general.lua") + ''
          
          -- Hyprland plugins loaded declaratively by Nix
          ${lib.concatMapStrings (plugin: ''
          hl.plugin("${plugin}/lib/lib${plugin.pname}.so")
          '') cfg.hyprland.plugins}
        '';
      };

      # 5. Hyprland/hyprland 目录 (隔离出 shellOverrides)
      "hypr/hyprland/colors.lua" = mkIf cfg.dotfiles.hyprland.enable { source = "${dotfilesSource}/dots/.config/hypr/hyprland/colors.lua"; };
      "hypr/hyprland/env.lua" = mkIf cfg.dotfiles.hyprland.enable { source = "${dotfilesSource}/dots/.config/hypr/hyprland/env.lua"; };
      "hypr/hyprland/execs.lua" = mkIf cfg.dotfiles.hyprland.enable { source = "${dotfilesSource}/dots/.config/hypr/hyprland/execs.lua"; };
      "hypr/hyprland/general.lua" = mkIf cfg.dotfiles.hyprland.enable { source = "${dotfilesSource}/dots/.config/hypr/hyprland/general.lua"; };
      "hypr/hyprland/keybinds.lua" = mkIf cfg.dotfiles.hyprland.enable { source = "${dotfilesSource}/dots/.config/hypr/hyprland/keybinds.lua"; };
      "hypr/hyprland/lib" = mkIf cfg.dotfiles.hyprland.enable { source = "${dotfilesSource}/dots/.config/hypr/hyprland/lib"; };
      "hypr/hyprland/rules.lua" = mkIf cfg.dotfiles.hyprland.enable { source = "${dotfilesSource}/dots/.config/hypr/hyprland/rules.lua"; };
      "hypr/hyprland/scripts" = mkIf cfg.dotfiles.hyprland.enable { source = "${dotfilesSource}/dots/.config/hypr/hyprland/scripts"; };
      "hypr/hyprland/services" = mkIf cfg.dotfiles.hyprland.enable { source = "${dotfilesSource}/dots/.config/hypr/hyprland/services"; };
      "hypr/hyprland/variables.lua" = mkIf cfg.dotfiles.hyprland.enable { source = "${dotfilesSource}/dots/.config/hypr/hyprland/variables.lua"; };

      # 动态占位: shellOverrides/main.lua
      "hypr/hyprland/shellOverrides/main.lua" = mkIf cfg.dotfiles.hyprland.enable {
        text = "-- Empty placeholder created by Nix\n";
      };

      # ------------------------------------------
      # 其他桌面组件与配置
      # ------------------------------------------
      "quickshell/ii" = mkIf cfg.dotfiles.quickshell.enable { source = "${dotfilesSource}/dots/.config/quickshell/ii"; };
      "wlogout" = mkIf cfg.dotfiles.wlogout.enable { source = "${dotfilesSource}/dots/.config/wlogout"; };
      "fuzzel" = mkIf cfg.dotfiles.fuzzel.enable { source = "${dotfilesSource}/dots/.config/fuzzel"; };
      "xdg-desktop-portal" = mkIf cfg.dotfiles.xdg-desktop-portal.enable { source = "${dotfilesSource}/dots/.config/xdg-desktop-portal"; };
      "fontconfig" = mkIf cfg.dotfiles.fontconfig.enable { source = "${dotfilesSource}/dots/.config/fontconfig"; };
      "kde-material-you-colors" = mkIf cfg.dotfiles.kde-material-you-colors.enable { source = "${dotfilesSource}/dots/.config/kde-material-you-colors"; };
      "kdeglobals" = mkIf cfg.dotfiles.kdeglobals.enable { source = "${dotfilesSource}/dots/.config/kdeglobals"; };
      "Kvantum" = mkIf cfg.dotfiles.Kvantum.enable { source = "${dotfilesSource}/dots/.config/Kvantum"; };
      "matugen" = mkIf cfg.dotfiles.matugen.enable { source = "${dotfilesSource}/dots/.config/matugen"; };
      "darklyrc" = mkIf cfg.dotfiles.darklyrc.enable { source = "${dotfilesSource}/dots/.config/darklyrc"; };
      "dolphinrc" = mkIf cfg.dotfiles.dolphinrc.enable { source = "${dotfilesSource}/dots/.config/dolphinrc"; };
      "chrome-flags.conf" = mkIf cfg.dotfiles.chrome-flags.enable { source = "${dotfilesSource}/dots/.config/chrome-flags.conf"; };
      "thorium-flags.conf" = mkIf cfg.dotfiles.thorium-flags.enable { source = "${dotfilesSource}/dots/.config/thorium-flags.conf"; };
      "code-flags.conf" = mkIf cfg.dotfiles.code-flags.enable { source = "${dotfilesSource}/dots/.config/code-flags.conf"; };
      "mpv" = mkIf cfg.dotfiles.mpv.enable { source = "${dotfilesSource}/dots/.config/mpv"; };
    };

    xdg.dataFile = {
      "icons/hicolor/scalable/apps/illogical-impulse.svg".source = 
        "${dotfilesSource}/dots/.local/share/icons/illogical-impulse.svg";

      "konsole/Profile 1.profile" = mkIf cfg.dotfiles.konsolerc.enable {
        source = "${dotfilesSource}/dots/.local/share/konsole/Profile 1.profile";
      };
    };

    # Fake venv at the path upstream expects: ~/.local/state/quickshell/.venv
    home.file = {
      ".local/state/quickshell/.venv/bin/activate".text = ''
        # Generated by illogical-flake - provides the Nix Python env as a fake venv
        export VIRTUAL_ENV="${cfg.internal.pythonEnv}"
        export PATH="${cfg.internal.pythonEnv}/bin:$PATH"
        deactivate() { return 0; }
      '';
      ".local/state/quickshell/.venv/bin/python".source =
        "${cfg.internal.pythonEnv}/bin/python";
      ".local/state/quickshell/.venv/bin/python3".source =
        "${cfg.internal.pythonEnv}/bin/python3";
      ".local/state/quickshell/.venv/pyvenv.cfg".text = ''
        home = ${cfg.internal.pythonEnv}/bin
        include-system-site-packages = false
        version = 3.12.0
      '';
    };

    # Configure icon theme for GTK and Qt applications
    gtk = {
      enable = mkDefault true;
      iconTheme = {
        name = mkDefault "OneUI-dark";
        package = mkDefault customPkgs.illogical-impulse-oneui4-icons;
      };
    };

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        icon-theme = mkDefault "OneUI-dark";
      };
    };
  };
}
