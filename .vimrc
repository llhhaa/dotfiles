"" Vundle
filetype off " required for Vundle

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
" call vundle#begin('~/some/path/here')

Plugin 'gmarik/Vundle.vim' " let Vundle manage Vundle, required
Plugin 'tpope/vim-fugitive.git'
"Plugin 'scrooloose/nerdtree'
Plugin 'pangloss/vim-javascript'
Plugin 'mxw/vim-jsx'
Plugin 'scooloose/syntastic'
Plugin 'wikitopian/hardmode'
Plugin 'mtscout6/syntastic-local-eslint.vim' " use project eslint

" all Plugins must be added before the following line
call vundle#end() "required
filetype plugin indent on "required

set nocompatible		" no compatibility with legacy vi, required for Vundle
syntax enable
set encoding=utf-8
set showcmd			" display incomplete commands
set number      " show line numbers
filetype plugin indent on

"" colorschemes
let g:neodark#use_256color = 1 " default: 0
colorscheme neodark

"" Whitespace
set nowrap
set tabstop=2 shiftwidth=2
set expandtab			" use spaces, not tabs (optional)
set backspace=indent,eol,start	" backspace through everything in insert mode

" whitespace cleanup function
function! Whitespace()
  if !&binary && &filetype != 'diff'
    normal mz
    normal Hmy
    %s/\s\+$//e
    normal 'yz<CR>
    normal `z
    echo "Whitespace cleanup complete."
  endif
endfunction

"" Folding
set foldmethod=indent
set foldcolumn=5

"" Searching
set hlsearch			" highlight matches
set incsearch			" incremental searching
set ignorecase		" searches are case insensitive...
set smartcase			" ... unless they contain at least one capital letter

"" Linting (manual invoke w/:SyntasticCheck)
let g:syntastic_mode_map = { 'mode': 'active',
                            \ 'active_filetypes': ['javascript'],
                            \ 'passive_filetypes': [] }

"" statusline
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:jsx_ext_required = 0
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 0
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 0
" attempted fix for nvm/vim/eslint path issue
" currently resolved with 'local eslint plugin'
" may need to revisit depending on project
" let g:syntastic_javascript_eslint_exec = '~/.nvm/versions/node/v4.2.1/bin/eslint'
let g:syntastic_javascript_checkers = ['eslint']

""Keymappings
"moving pane manipulation over to space-w, easier to use on 40% keyboards
map <Space> <leader>
noremap <Leader>w <C-w>
noremap <Leader>= :call Whitespace()

"" CtrlP
" don't know how to use this yet
set runtimepath^=~/.vim/bundle/ctrlp.vim

"" The Silver Searcher
if executable('ag')
  set grepprg=ag\ --nogroup\ --nocolor " Use ag over grep
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""' " Use ag in CtrlP (respects .gitignore)
  let g:ctrlp_use_caching = 0 " CtrlP doesn't need to cache w/ag
endif

"" HardMode
"autocmd VimEnter,BufNewFile,BufReadPost * silent! call HardMode() " call on start

"" Change to repos directory
cd /Users/label-triad/repos
