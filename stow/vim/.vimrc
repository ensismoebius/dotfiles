" Automatically install vim-plug if not present
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

" Plugins
Plug 'dracula/vim'

call plug#end()

colorscheme dracula

set number
set relativenumber
set cursorline

" Always show the status line
set laststatus=2

" A more informative status line
set statusline=
set statusline+=%#PmenuSel#\ %{toupper(mode())[0]}\ %*         " Mode indicator (N, I, V)
set statusline+=%#StatusLine#\ %f\ %m%r                       " File path, modified/readonly flags
set statusline+=%=                                           " Right-align the following
set statusline+=%#PmenuSel#\ %y\ %*                           " Filetype
set statusline+=%#StatusLine#\ %l:%c\ [%p%%]                  " Line, column, and percentage
