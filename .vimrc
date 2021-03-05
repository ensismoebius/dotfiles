"" IDE settings

" Activate syntax highlight
syntax on

" Auto indentation 
set autoindent

" Enables relative line numbering
set relativenumber

" Highlights the current line
set cursorline

" Color theme
colo molokai
let g:molokai_original = 1

" Shows a bar at the bottom of the editor with vim ariline
set laststatus=2
let g:airline#extensions#tabline#formatter = 'default'
let g:airline#extensions#tabline#enabled=1
let g:airline_powerline_fonts=1
let g:airline_statusline_ontop=0

"Enables line indentation indicator
let g:indentLine_enabled=1

" Enables fuzzy file finder
let g:ctrlp_custom_ignore = '\v[\/]\.(swp|zip)$'
let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files -co --exclude-standard']
let g:ctrlp_show_hidden = 1

" Nerd commenter
filetype plugin on
let g:NERDSpaceDelims = 1
let g:NERDDefaultAlign = 'left'
map cc <Plug>NERDCommenterInvert

"" Text editor settings

" Set proper encoding
set encoding=UTF-8

" Shares the clipboard with system
set clipboard=unnamedplus

" Better history size (default is 50)
set history=5000

" Highlights the terms in a search
set incsearch

" Shows an auto-completion menu at the bottom of the editor
set wildmenu

" Enables any buffer to be hidden (even modified)
set hidden

" Shows a confirmation, when needed
set confirm

" Enable correct mouse interaction
set mouse=a

" Changes the title of terminal to current file
set title

" Set default font
set guifont=DroidSansMono\ Nerd\ Font\ Mono:h12

" let g:ale_linters = {'python': ['flake8', 'pylint'], 'javascript': ['eslint']}
" let g:ale_completion_enabled = 0

" Better responses 
set updatetime=300


"" Shortcuts

" Maps q to quit vim
map q :q<CR>

" Toggles the indentation indicator
map <c-k>i : IndentLinesToggle<cr>

" Toggles nerdtree
map <c-n> :NERDTreeToggle<cr>

" Goto next buffer (ctrl + right)
nnoremap Oc :bn<cr>
" Goto previous buffer (ctrl + left)
nnoremap Od :bp<cr>
" Close current buffer and goto last one (ctrl + x)
nnoremap <c-x> :bp\|bd #<cr>

" Goto next buffer (insert mode)
inoremap Oc <esc>:bn<cr>i
" Goto previous buffer (insert mode)
inoremap Od <esc>:bp<cr>i
" Close current buffer and goto last one (insert mode)
inoremap <c-x> <esc>:bp\|bd #<cr>i
