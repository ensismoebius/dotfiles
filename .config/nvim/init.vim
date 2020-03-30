" Plugins section
call plug#begin()

Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'zchee/deoplete-clang'

Plug 'Shougo/neoinclude.vim'
Plug 'Shougo/neosnippet'
Plug 'Shougo/neosnippet-snippets'

Plug 'scrooloose/nerdtree'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'scrooloose/nerdcommenter'

Plug 'vim-syntastic/syntastic'

Plug 'vim-airline/vim-airline' 

"Plug 'jreybert/vimagit'
Plug 'tpope/vim-fugitive'

Plug 'sbdchd/neoformat'

Plug 'kyoz/purify'

Plug 'junegunn/fzf.vim'
Plug 'mileszs/ack.vim'

Plug 'ryanoasis/vim-devicons'
Plug 'easymotion/vim-easymotion'

call plug#end()

" Behavior section
filetype plugin indent on
syntax on
set number
set relativenumber
set incsearch

let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
"let g:airline_left_sep = '»'
"let g:airline_left_sep = '▶'
"let g:airline_right_sep = '«'
"let g:airline_right_sep = '◀'
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*



" Enable alignment
let g:neoformat_basic_format_align = 1
" Enable trimmming of trailing whitespace
let g:neoformat_basic_format_trim = 1
let b:neoformat_basic_format_retab = 0
let g:neoformat_only_msg_on_error = 1




let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_c_checkers = ['gcc']
let g:syntastic_cpp_checkers = ['gcc']
let g:syntastic_vim_checkers = ['vim']


let g:deoplete#enable_at_startup = 1



" Keybindings
nmap <C-n> :NERDTreeToggle<CR>


