:set number
":set relativenumber
:set autoindent
:set expandtab
:set tabstop =4
:set shiftwidth =4
:set smarttab
:set softtabstop =4
:set mouse =a

call plug#begin()

Plug 'tpope/vim-fugitive'                   " Git integration in to nvim
Plug 'Yggdroot/indentLine'                  " Line Indentations
Plug 'farmergreg/vim-lastplace'             " Continue from where you left last time
Plug 'raimondi/delimitmate'                 " Provides insert mode auto-completion for special-characters
Plug 'tpope/vim-markdown'                   " Markdown runtime files
Plug 'tpope/vim-surround'                   " Change paranthesis and quotes into other forms quickly
Plug 'scrooloose/nerdtree'                  " File navigator
Plug 'vim-scripts/indentpython.vim'         " Indentation script for python
Plug 'alvan/vim-closetag'                   " Makes a close tag for html quickly
Plug 'luochen1990/rainbow'                  " Provides different colors to different paranthesis
Plug 'airblade/vim-gitgutter'               " Shows git diffs in the sign columns
Plug 'lilydjwg/colorizer'                   " Provides color for the #rrggbb or #rgb color format in files
Plug 'vim-airline/vim-airline'              " Powerline Theme / Status line
Plug 'vim-airline/vim-airline-themes'       " Themes for vim-airline
Plug 'rafi/awesome-vim-colorschemes'        " Change colorschemes on the fly for vim and nvim
Plug 'ryanoasis/vim-devicons'               " Icons
Plug 'SirVer/ultisnips'                     " Code completion using snippets from vim-snippets and custom snippets
Plug 'honza/vim-snippets'                   " Provides snippets for ultisnip
Plug 'neoclide/coc.nvim'                    " Code suggestions and completion

call plug#end()

nnoremap <C-f> :NERDTreeFocus<CR>
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <A-h> :vsplit<CR>
nnoremap <A-k> :split<CR>
" inoremap <silent><expr> <tab> coc#refresh()
" inoremap <silent><expr> <tab> coc#pum#visible() ? coc#pum#confirm() : "\<tab>" 
colorscheme molokai

set guicursor=a:hor20

let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_theme='molokai'

let g:indentLine_fileTypeExclude = ["help", "nerdtree", "diff"]
let g:indentLine_fileTypeExclude = ["help", "nerdtree", "diff", "markdown"]
let g:indentLine_bufTypeExclude = ["help", "terminal"]
let g:indentLine_showFirstIndentLevel = 1
let g:indentLine_indentLevel = 7
let g:indentLine_char_list = ['|', '¦', '┆', '┊']

" use <tab> to trigger completion and navigate to the next complete item
function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

inoremap <silent><expr> <Tab>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
