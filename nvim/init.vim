" Plugins
call plug#begin('~/.config/nvim/plugged')
  Plug 'wakatime/vim-wakatime'
  Plug 'github/copilot.vim'
  Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn' }
  Plug 'rest-nvim/rest.nvim', { 'tag': '0.2' }

  " Theme
  Plug 'arcticicestudio/nord-vim'
  Plug 'kyazdani42/nvim-web-devicons'
  Plug 'itchyny/lightline.vim'

  " Git, GitHub
  Plug 'tpope/vim-fugitive'
  Plug 'airblade/vim-gitgutter'
  Plug 'sindrets/diffview.nvim'
  Plug 'pwntester/octo.nvim'
  Plug 'akinsho/git-conflict.nvim', { 'tag': '*' }
  Plug 'rhysd/conflict-marker.vim'

  " Editor
  Plug 'tpope/vim-surround'
  Plug 'nvim-telescope/telescope.nvim'
  Plug 'windwp/nvim-autopairs'
  Plug 'chaoren/vim-wordmotion'
  Plug 'stevearc/qf_helper.nvim'
  Plug 'stevearc/oil.nvim'
  Plug 'lalitmee/browse.nvim'

  " Languages and frameworks
  Plug 'sheerun/vim-polyglot'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'jparise/vim-graphql'
  Plug 'rust-lang/rust.vim'
  Plug 'eliba2/vim-node-inspect'

  " Dependencies
  Plug 'nvim-lua/plenary.nvim'
  Plug 'nvim-telescope/telescope-live-grep-args.nvim'
  Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }

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
set expandtab
set signcolumn=yes " vim-gitgutter

let g:mkdp_theme = 'light'

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

  " Buffers
  nnoremap <silent> <C-w>d :bp<CR>:bd#<CR>
  nnoremap <silent> <C-w>D :%bd\|e#<CR>
  nnoremap <silent> <PageUp>   :bprevious!<CR>
  nnoremap <silent> <PageDown> :bnext!<CR>

" Command maps
command W w
command Wq wq
command WQ wq
command Qa qa
command QA qa
command Bd bd
command BD bd

command Rest :lua require('rest-nvim').run()<CR>

for module in uniq(sort(globpath(&rtp, 'modules/*.vim', 0, 1)))
    execute "source " . module
endfor
