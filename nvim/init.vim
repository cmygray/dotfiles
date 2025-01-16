" Plugins
call plug#begin('~/.config/nvim/plugged')
  Plug 'wakatime/vim-wakatime'
  Plug 'github/copilot.vim'
  Plug 'CopilotC-Nvim/CopilotChat.nvim', { 'branch': 'main' }
  Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && npx --yes yarn install' }
  Plug 'rest-nvim/rest.nvim', { 'tag': '0.2' }
  Plug 'vimwiki/vimwiki'

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
  Plug 'nanotee/zoxide.vim'
  Plug 'kevinhwang91/nvim-ufo'
  Plug 'kevinhwang91/nvim-bqf'
  Plug 'chrisbra/csv.vim'

  " Languages and frameworks
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'jparise/vim-graphql'
  Plug 'rust-lang/rust.vim'
  Plug 'eliba2/vim-node-inspect'

  " Dependencies
  Plug 'nvim-lua/plenary.nvim'
  Plug 'nvim-telescope/telescope-live-grep-args.nvim'
  Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }
  Plug 'kevinhwang91/promise-async'

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

let g:mkdp_theme = 'dark'

" Keymaps
vnoremap // y/<C-R>"<CR>N

map <space> <leader>

nnoremap Y y$

map ,, :e $MYVIMRC<cr>
map ,,, :source $MYVIMRC<cr>

  " Movement in insert mode
  inoremap <C-h> <C-o>h
  inoremap <C-l> <C-o>a
  inoremap <C-j> <C-o>j
  inoremap <C-k> <C-o>k

  " Copy to clipboard
  vnoremap <C-c> "+y

  " Buffers
  nnoremap <silent> <C-w>d :bp<CR>:bd#<CR>
  nnoremap <silent> <C-w>D :%bd\|e#<CR>
  nnoremap <silent> <PageUp>   :bprevious!<CR>
  nnoremap <silent> <PageDown> :bnext!<CR>

" Command maps
  " Missed Capital Input
  command W w
  command Wq wq
  command WQ wq
  command Wqa wqa
  command WQA wqa
  command WQa wqa

  command Q q
  command Qa qa
  command QA qa

  command Bd bd
  command BD bd

  " Aliassed commands
  command TN tabnew
  command TC tabclose

command! -nargs=0 Cwd :let @+ = expand('%:p')

command Rest :lua require('rest-nvim').run()<CR>

for module in uniq(sort(globpath(&rtp, 'modules/*.vim', 0, 1)))
    execute "source " . module
endfor
