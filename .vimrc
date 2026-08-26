call plug#begin('~/.vim/plugged')
Plug 'junegunn/fzf'
Plug 'junegunn/vim-easy-align'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'ghifarit53/tokyonight-vim'
Plug 'morhetz/gruvbox'
Plug 'itchyny/lightline.vim'
Plug 'lifepillar/vim-mucomplete'
Plug 'vim-scripts/SearchComplete'
Plug 'michaeljsmith/vim-indent-object'
Plug 'andymass/matchup.vim'
Plug 'psliwka/vim-smoothie'
Plug 'romainl/vim-cool'
Plug 'sheerun/vim-polyglot' " Add vim-polyglot
Plug 'tomasr/molokai'
Plug 'Konfekt/vim-alias'
call plug#end()

syntax on
set nocompatible
set encoding=utf-8
set completeopt+=menuone mouse=a
set number laststatus=2
set expandtab tabstop=4 shiftwidth=4
set ignorecase smartcase incsearch hlsearch
set list listchars=tab:▸\ ,trail:·,extends:›,precedes:‹,nbsp:␣
set background=dark t_Co=256 term=xterm-256color termguicolors 
set sc nowrap noswapfile nosmd hidden splitright splitbelow belloff=all
autocmd FileType c,cpp,cs,java setlocal commentstring=//\ %s
let g:netrw_dirhistmax = 0
"colorscheme tokyonight
"let g:lightline = { 'colorscheme' : 'tokyonight' }

if has('gui_running')
    set guioptions=
    set guifont=Menlo:h18
    set cursorline
    set termguicolors
    let g:tokyonight_style = 'night' " available: night, storm
    let g:tokyonight_enable_italic = 1
    colorscheme tokyonight

    let g:lightline = { 'colorscheme' : 'tokyonight' }
else
    "set cursorline
    "highlight CursorLine term=bold ctermbg=red ctermfg=black
endif

let mapleader = " "
no <leader>y "*y
no <leader>p "*p
nm <leader>q :qa!<cr>
nm <leader>v :e $MYVIMRC<cr>
nm <leader>s :%s/\s\+$//g<cr>
nm <leader><leader> :FZF<cr>
no! <c-a> <HOME>
no! <c-e> <END>


" Define user alias
cnoreabbrev W!! write !sudo tee > /dev/null %<CR>
