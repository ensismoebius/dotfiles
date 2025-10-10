# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#            _
#    _______| |__  _ __ ___
#   |_  / __| '_ \| '__/ __|
#  _ / /\__ \ | | | | | (__
# (_)___|___/_| |_|_|  \___|
#
# -----------------------------------------------------
# ML4W zshrc loader
# -----------------------------------------------------

# DON'T CHANGE THIS FILE

# You can define your custom configuration by adding
# files in ~/.config/zshrc
# or by creating a folder ~/.config/zshrc/custom
# with copies of files from ~/.config/zshrc
# -----------------------------------------------------

# -----------------------------------------------------
# Load Zsh Plugins
# -----------------------------------------------------

source /home/ensismoebius/.config/hypr/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
source /home/ensismoebius/.config/hypr/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh

# -----------------------------------------------------
# Load single customization file (if exists)
# -----------------------------------------------------

ZSH_THEME="powerlevel10k/powerlevel10k"

if [ -f ~/.zshrc_custom ]; then
    source ~/.zshrc_custom
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

