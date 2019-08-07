"" {{{{ Intro }}}}
" TOC:

" Plugins
""" feature extension
""" syntax
""" misc
""" fzf

" Core Vim
""" general
""" whitespace
""" folding
""" searching
""" statusline
""" tabline

" Colorscheme (256 neodark)

" Netrw

" Linter Settings

" Keymappings

" Replace grep with ripgrep

" Last call (path+=**, cd to project)

" Homebrew packages (not necessarily deps for Vim):
""" ripgrep
""" task
""" ctags
""" ruby
""" fzf

" Fonts
""" Adobe Source Code Pro
""" Fira Mono

" Potential TODOs:
" use prettier to format javascript with gq[motion]
" [npm install -g prettier]
" autocmd FileType javascript set formatprg=prettier\ --stdin

"" {{{{ Vim-Plug }}}}

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
"feature extension
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-surround'
Plug 'kana/vim-textobj-user'
Plug 'kana/vim-textobj-entire'
Plug 'janko-m/vim-test'
Plug 'vimwiki/vimwiki'


"syntax & linting
Plug 'sheerun/vim-polyglot'
Plug 'w0rp/ale'
"Plug 'scrooloose/syntastic'
"Plug 'mtscout6/syntastic-local-eslint.vim' " use project eslint

" languages
Plug 'tpope/vim-rails'
Plug 'tpope/vim-bundler'
Plug 'tpope/vim-apathy'

" Colorschemes
" Plug 'keitanakamura/neodark.vim'
" Plug 'lifepillar/vim-solarized8'
" Plug 'morhetz/gruvbox'
" Plug 'owickstrom/vim-colors-paramount'
" Plug 'arcticicestudio/nord-vim'
" Plug 'chriskempson/base16-vim'
Plug 'romainl/apprentice'

" Groovy syntax highlighting
" autocmd BufRead,BufNewFile Jenkinsfile setf groovy
" autocmd BufRead,BufNewFile Jenkinsfile* setf groovy
" autocmd BufRead,BufNewFile *.jenkinsfile setf groovy
" autocmd BufRead,BufNewFile *.jenkinsfile setf groovy
" autocmd BufRead,BufNewFile *.gradle setf groovy

call plug#end()

"my plugin :)
"set rtp+=~/.vim/bundle/vim-rctoggle

"fzf
set rtp+=/usr/local/opt/fzf " mac/homebrew
"set rtp+=~/.fzf " linux/git

"" {{{{ General Settings }}}}
filetype plugin indent on
syntax enable
set encoding=utf-8
set history=1000
set nocompatible            " no compatibility with legacy vi, required for Vundle
set number                  " show line numbers
set ruler
set scrolloff=2             " lines displayed above/below cursor
set sessionoptions-=options " don't keep options in sessions
set showcmd		    " display incomplete commands
set sidescrolloff=5         " keep 5 cols to the left/right of cursor
set tabpagemax=50
set ttimeout
set ttimeoutlen=100
set viminfo^=!              " keep capitalized global variables (for plugins)
set wildignore +=**/node_modules/**
set wildmenu
"set relativenumber
au FocusGained,BufEnter * checktime "like gVim, prompt if file changed

" needed so vim gets the mouse in tmux
set ttymouse=xterm2
set mouse=a

if v:version > 703 || v:version == 703 && has('patch541')
  set formatoptions+=j " smart line joining in comments
endif

" long line highlighting
highlight ColorColumn ctermbg=gray
set colorcolumn=81


"" {{{{ Whitespace }}}}
set autoindent                  " use indent from prev line when starting new line
set nowrap
set tabstop=8                   " recommended default, use below settings for 'actual' tabsize
set softtabstop=2
set shiftwidth=2
set smarttab                    " use shiftwidth (value used in >> cmd) when tabbing
set expandtab	                " use spaces, not tabs (optional)
set backspace=indent,eol,start	" backspace through everything in insert mode
set listchars=tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+


"" {{{{ Folding }}}}
set foldmethod=indent
set foldcolumn=0


"" {{{{ Searching }}}}
set hlsearch    " highlight matches
set incsearch	" incremental searching
set ignorecase  " searches are case insensitive...
set smartcase	" ... unless they contain at least one capital letter


"" {{{{ statusline, tabline }}}}
set laststatus=2                " always display statusline
set statusline=                 " clear out for reload
set statusline=%3.3n            " buffer number
set statusline+=\ %F%M          " full file path + modified flag
set statusline+=\ %L/%l:%c      " linetotal/line:col
set statusline+=\ %h%m%r%w      " status flags
set statusline+=\ %#warningmsg# " highlight switch
"set statusline+=\ %{SyntasticStatuslineFlag()}
set statusline+=\ %*            " highlight exit
set guitablabel=                " clear for reload
set guitablabel=%{GuiTabLabel()}


"" {{{{ colorschemes }}}}
"let g:neodark#use_256color = 1 " default: 0
" set termguicolors             " for solarized
" set t_Co=256                  " for Terminal.app for certain colorschemes
set background=dark
colorscheme apprentice


"" {{{{ netrw }}}}
let g:netrw_banner = 0      " hide banner
"let g:netrw_liststyle = 3  " tree list (causes buffer bug)


"" {{{{ Linting }}}}
" (manual invoke w/:SyntasticCheck)
" let g:syntastic_mode_map = { 'mode': 'active',
"                             \ 'active_filetypes': ['javascript'],
"                             \ 'passive_filetypes': [] }
let g:jsx_ext_required = 0
" let g:syntastic_always_populate_loc_list = 1
" let g:syntastic_auto_loc_list = 0
" let g:syntastic_check_on_open = 0
" let g:syntastic_check_on_wq = 0
" attempted fix for nvm/vim/eslint path issue
" currently resolved with 'local eslint plugin'
" may need to revisit depending on project
" let g:syntastic_javascript_eslint_exec = '~/.nvm/versions/node/v4.2.1/bin/eslint'
" let g:syntastic_javascript_checkers = ['eslint']

let g:ale_linters = {'javascript': ['eslint']}

" Ruby/Rails settings
autocmd FileType ruby,eruby let g:rubycomplete_buffer_loading = 1 
autocmd FileType ruby,eruby let g:rubycomplete_classes_in_global = 1
autocmd FileType ruby,eruby let g:rubycomplete_rails = 1


"" {{{{ Commands }}}}
" cnoreabbrev fzf FZF


"" {{{{ Keymappings }}}}
map <Space> <leader>
noremap <Leader>/ :noh<Cr>
noremap <Leader>e :e **/*
noremap <Leader>h :cd ~/repos/<Cr>
noremap <Leader>p :cd %:p:h<Cr>
noremap <Leader>r :s/:\(\w\+\)\(\s*\)=>\s*/\1:\2/g<Cr>
"moving pane manipulation over to space-w, easier to use on 40% keyboards
noremap <Leader>w <C-w>

" Vim Terminal
" tnoremap <Esc> <C-W>N
" tnoremap <C-W><Esc> <Esc>
" set notimeout ttimeout timeoutlen=100

" Scripts
noremap gC :call ToggleVimrc()<Cr>
noremap <Leader>= :call Whitespace()<Cr>
noremap <Leader>o :call OpenBrackets()<Cr>
xnoremap <Leader>* :<C-u>call <SID>VSetSearch('/')<CR>/<C-R>=@/<CR><CR>
xnoremap <Leader># :<C-u>call <SID>VSetSearch('?')<CR>?<C-R>=@/<CR><CR>

" External
noremap <Leader>f :FZF<Cr>
noremap <Leader>F :tabnew +FZF<Cr>

noremap <Leader>g :grep\<space>
noremap <Leader>G :tabnew +grep\<space>

noremap <Leader>l :grep\<space><C-r><C-w><Cr> :copen<Cr>
noremap <Leader>L :tabnew +grep\<space><C-r><C-w><Cr> :copen<Cr>
"noremap gO :!open -a Adobe\ Photoshop\ CS5 <cfile><CR>

" Vim-Test
noremap <Leader>tt :TestNearest<Cr>
noremap <Leader>tf :TestFile<Cr>
noremap <Leader>ts :TestSuite<Cr>
noremap <Leader>tl :TestLast<Cr>
noremap <Leader>tv :TestVist<Cr>


"" {{{{ Functions }}}}
function! GuiTabLabel()
  let label = ''
  let bufnrlist = tabpagebuflist(v:lnum)

  " Add '+' if one of the buffers in the tab page is modified
  for bufnr in bufnrlist
    if getbufvar(bufnr, "&modified")
      let label = '+'
      break
    endif
  endfor

  " Append the number of windows in the tab page if more than one
  let wincount = tabpagewinnr(v:lnum, '$')
  if wincount > 1
    let label .= wincount
  endif
  if label != ''
    let label .= ' '
  endif

  " Append the buffer name
  return label . bufname(bufnrlist[tabpagewinnr(v:lnum) - 1])
endfunction

function! Whitespace() " whitespace and endline cleanup function
  if !&binary && &filetype != 'diff'
    normal mz
    normal Hmy
    $put _
    %s/\s\+$//e
    %s#\($\n\s*\)\+\%$##
    $put _
    normal 'yz<CR>
    normal `z
    echo "Whitespace cleanup complete."
  endif
endfunction
"" for regex breakdown: http://stackoverflow.com/q/7495932/

function! ToggleVimrc() " switch to vimrc depending on context
  let s:keep_sb = &switchbuf
  set switchbuf=useopen,usetab

  let buffernumber = bufnr("~/.vimrc") " -1 if doesn't exist
  let currenttab = tabpagenr() " store current buf as fallback
  let buffs_arr = []
  tabdo let buffs_arr += tabpagebuflist() " collect all buf#s

  " return to current page
  exec "tabnext ".currenttab

  let i = 0
  let bnr = 0
  for bnum in buffs_arr " iterate thru buf#s, look for match
      let i += 1
      if bnum == buffernumber
        let bnr = i
      endif
  endfor

  if bufnr("%") == buffernumber "if current buf, close
    tabclose
  elseif bnr > 0 " if match, switchbuf
    sb ~/.vimrc
  else           " else create buff
    $tabnew
    e $MYVIMRC
  endif

  let &switchbuf=s:keep_sb
  unlet s:keep_sb
endfunction

function! OpenBrackets() abort
  " TODO: make the start of insert mode indented
  " TODO: have it abort silently
  .s/\v(\{|\[)/\1\r/
  execute "normal! O"
  startinsert
endfunction

" Visual-Star
function! s:VSetSearch(cmdtype)
  let temp = @s
  norm! gv"sy
  let @/ = '\V' . substitute(escape(@s, a:cmdtype.'\'), '\n', '\\n', 'g')
  let @s = temp
endfunction


"" {{{{ Plugin-specific settings }}}}
" {{{ ripgrep }}}
"  use ripgrep (or silver searcher) instead of grep
if executable('rg')
  set grepprg=rg\ --vimgrep\ --no-heading\ --smart-case
  set grepformat=%f:%l:%c:%m,%f:%l:%m
elseif executable('ag')
  set grepprg=ag\ --vimgrep\ --ignore=\"**.min.js\"
  set grepformat=%f:%l:%c:%m,%f:%l:%m
endif

"" {{{{ Last Call }}}}
" set path+=**
