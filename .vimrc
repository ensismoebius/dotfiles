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
