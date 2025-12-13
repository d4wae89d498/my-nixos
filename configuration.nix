{ config, pkgs, lib, ... }:

{
  imports = [ <nixos-wsl/modules> ];

  # --- System configuration ---
  networking.hostName = "nix-altyk";
  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";

  wsl.enable = true;
  wsl.defaultUser = "bdc";

  system.stateVersion = "25.05";

  # --- System packages ---
  environment.systemPackages = with pkgs; [
    screen
    tmux
    htop
    gtop
    git
    curl
    wget
    ripgrep
    tree
    fzf
    (vim-full.customize {
      name = "vim";
      vimrcConfig.customRC = ''
        set number
        set colorcolumn=80
        set showcmd
        set cursorline
        set tabstop=4
        set shiftwidth=4
        set expandtab
        syntax on
        set belloff=all
        set mouse=a

        " Dark theme
        autocmd vimenter * ++nested colorscheme gruvbox
        set background=dark

        " NERDTree toggle
        nnoremap <C-b> :NERDTreeToggle<CR>

        " Windows copy from visual mode
        vnoremap <RightMouse> "+y

        " FZF keymaps in Vim
        nnoremap <leader>f :Files<CR>
        nnoremap <leader>fg :GFiles<CR>
        nnoremap <leader>fb :Buffers<CR>
        nnoremap <leader>fh :Helptags<CR>

        " --- Airline ---
        let g:airline_theme='gruvbox'
        let g:airline_powerline_fonts = 0

        " Windows trick for cursors
        set guicursor=
        let &t_SI = "\<ESC>[6 q"
        let &t_SR = "\<ESC>[4 q"
        let &t_EI = "\<ESC>[2 q"

        " Automatically run :tab sball on each file
        autocmd BufReadPost,BufNewFile * tab sball
      '';
      vimrcConfig.packages.myVimPackage = with pkgs.vimPlugins; {
        start = [
          nerdtree
          fzf-vim
          gruvbox
          vim-airline
          vim-airline-themes
        ];
        opt = [];
      };
    })
  ];

  # --- Bash configuration ---
  programs.bash.shellInit = ''
    [ -f /etc/bashrc ] && source /etc/bashrc

    export PS1="\[\e[0;32m\]\u@\h \w \$\[\e[m\] "

    [ -f ${pkgs.fzf}/share/fzf/key-bindings.bash ] && source ${pkgs.fzf}/share/fzf/key-bindings.bash
    [ -f ${pkgs.fzf}/share/fzf/completion.bash ] && source ${pkgs.fzf}/share/fzf/completion.bash

    bind '"\ef": "fzf-file-widget\n"'
  '';

  # --- User configuration ---
  users.users.bdc = {
    isNormalUser = true;
    shell = pkgs.bash;
  };

  # --- Screen configuration ---
  programs.screen = {
    enable = true;

    screenrc = ''
      # UTF-8
      defutf8 on
      startup_message off
      defscrollback 10000
      termcapinfo xterm* ti@:te@

      # Force login shell to inherit PATH & fzf
      shell -$SHELL
      shelltitle "$ |bash"

      # Bottom bar
      hardstatus alwayslastline
      backtick 1 2 2 bash -c "a=\$(uptime | awk \"{print \\\$10, \\\$11, \\\$12}\"); echo \"\$a\""
      backtick 2 2 2 bash -c "a=\$(free -g | grep Mem | awk \"{print \\\$3 \\\"/\\\" \\\$2}\"); echo \"\$a G\""
      hardstatus string "%{= KW} %H [%p] %{= Kw}CPU:%1` RAM:%2` |%{-} %-Lw%{= bW}%n%f %t%{-}%+Lw %=%C%a %Y-%M-%d"

      # Change process
      bindkey ^[[1;5C next      # Ctrl-Right
      bindkey ^[[1;5D prev      # Ctrl-Left

      # Fix CTRL A / E
      escape ^Bb               # Ctrl-B as prefix
      bind a stuff "^A"        # Ctrl-A A sends literal Ctrl-A
      bind e stuff "^E"        # Ctrl-A E sends literal Ctrl-E

    '';
  };
}
