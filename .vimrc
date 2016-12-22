"" Vundle config
filetype off  " required for Vundle

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
" call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'
Plugin 'tpope/vim-fugitive.git'
Plugin 'scrooloose/nerdtree'
Plugin 'mxw/vim-jsx'
Plugin 'scooloose/syntastic'

" all of yourPlugins must be added before the following line
call vundle#end() "required
filetype plugin indent on "required

set nocompatible		" choose no compatibility with legacy vi, required for Vundle
syntax enable
set encoding=utf-8
set showcmd			" display incomplete commands
set number      " show line numbers
filetype plugin indent on

" colorschemes
colorscheme neodark

"" Whitespace
set nowrap 			" don't wrap lines
set tabstop=2 shiftwidth=2	" a tab is two spaces (or set this to 4)
set expandtab			" use spaces, not tabs (optional)
set backspace=indent,eol,start	" backspace through everything in insert mode

"" Searching
set hlsearch			" highlight matches
set incsearch			" incremental searching
set ignorecase			" searches are case insensitive...
set smartcase			" ... unless they contain at least one capital letter

"" Linting
"" Manually invoke lint syntax check with :SyntasticCheck
let g:jsx_ext_required=0
let g:syntastic_check_on_open=1
let g:syntastic_enable_signs=1
let g:syntastic_auto_jump=0
let g:syntastic_auto_loc_list=0
let g:syntastic_javascript_checkers=['eslint']

" CtrlP
set runtimepath^=~/.vim/bundle/ctrlp.vim

" The Silver Searcher
if executable('ag')
  " Use ag over grep
  set grepprg=ag\ --nogroup\ --nocolor

  " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'

  " ag is fast enough that CtrlP doesn't need to cache
  let g:ctrlp_use_caching = 0
endif

"" Change to repos directory
cd /Users/label-triad/repos
