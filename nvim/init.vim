" Plugins
call plug#begin('~/.vim/plugged')
  " Theme
  Plug 'arcticicestudio/nord-vim'
  Plug 'kyazdani42/nvim-web-devicons'
  Plug 'vim-airline/vim-airline'

  " Git, GitHub
  Plug 'tpope/vim-fugitive'
  Plug 'airblade/vim-gitgutter'
  Plug 'sindrets/diffview.nvim'
  Plug 'pwntester/octo.nvim'
  Plug 'akinsho/git-conflict.nvim'

  " Editor
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-vinegar'
  Plug 'folke/todo-comments.nvim'
  Plug 'nvim-telescope/telescope.nvim'

  " Languages and frameworks
  Plug 'sheerun/vim-polyglot'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'rust-lang/rust.vim'
  Plug 'kubejm/jest.nvim'

  " Dependencies
  Plug 'nvim-lua/plenary.nvim'
  Plug 'nvim-telescope/telescope-live-grep-args.nvim'

  " Deprecated
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
call plug#end()

" General
colorscheme nord
set encoding=utf-8
set guifont=JetBrains\ Mono:h14
set title
set nu
set nuw=3
set wildmenu
set wildmode=full
set scrolloff=5
set lazyredraw
set laststatus=2
set hidden
set foldmethod=marker foldlevel=0
set hlsearch
set incsearch
set showmatch
set showcmd
set autoindent
set smartindent
set shiftwidth=2
set tabstop=2
set softtabstop=2
set expandtab smarttab
set signcolumn=yes " vim-gitgutter

let g:airline#extensions#tabline#enabled = 1

let g:netrw_localrmdir = 'rm -r'

" Keymaps
map <space> <leader>

nnoremap Y y$

map ,, :e $MYVIMRC<cr>
map ,,, :source $MYVIMRC<cr>

  " Movement in insert mode
  inoremap <C-h> <C-o>h
  inoremap <C-l> <C-o>a
  inoremap <C-j> <C-o>j
  inoremap <C-k> <C-o>k

  " [WIP] jump to test file
  nmap gt :execute 'find' '**/' . expand('%:t:r') . '.spec.ts'<cr>

" Command maps
command Wq wq
command WQ wq
command Qa qa
command QA qa

for module in uniq(sort(globpath(&rtp, 'modules/*.vim', 0, 1)))
    execute "source " . module
endfor

