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
call plug#begin('~/.vim/plugged')
"feature extension
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-commentary'
Plug 'kana/vim-textobj-user'
Plug 'kana/vim-textobj-entire'

"syntax & linting
Plug 'pangloss/vim-javascript'
Plug 'mxw/vim-jsx'
Plug 'leafgarland/typescript-vim'
"Plug 'scrooloose/syntastic'
"Plug 'mtscout6/syntastic-local-eslint.vim' " use project eslint
"Plug 'unblevable/quick-scope' " cool but distracting

"misc
Plug 'keitanakamura/neodark.vim'
Plug 'wikitopian/hardmode'
call plug#end()

"my plugin :)
"set rtp+=~/.vim/bundle/vim-rctoggle

"fzf
" "set rtp+=/usr/local/opt/fzf " mac/homebrew
"set rtp+=~/.fzf " linux/git

"" {{{{ General Settings }}}}
filetype plugin indent on
syntax enable
set encoding=utf-8
set history=1000
set nocompatible		" no compatibility with legacy vi, required for Vundle
set number      " show line numbers
set ruler
set scrolloff=1 " keep one line displayed above/below cursor
set sessionoptions-=options " don't keep options in sessions
set showcmd			" display incomplete commands
set sidescrolloff=5 " keep 5 cols to the left/right of cursor
set tabpagemax=50
set ttimeout
set ttimeoutlen=100
set viminfo^=! " keep capitalized global variables (for plugins)
set wildignore +=**/node_modules/**
set wildmenu
"set relativenumber
au FocusGained,BufEnter * checktime "like gVim, prompt if file changed
if v:version > 703 || v:version == 703 && has('patch541')
  set formatoptions+=j " smart line joining in comments
endif


"" {{{{ Whitespace }}}}
set autoindent " use indent from prev line when starting new line
set smarttab " use shiftwidth (value used in >> cmd) when tabbing
set nowrap
set tabstop=2 shiftwidth=2
set expandtab	" use spaces, not tabs (optional)
set backspace=indent,eol,start	" backspace through everything in insert mode
set listchars=tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+


"" {{{{ Folding }}}}
set foldmethod=indent
set foldcolumn=0


"" {{{{ Searching }}}}
set hlsearch			" highlight matches
set incsearch			" incremental searching
set ignorecase		" searches are case insensitive...
set smartcase			" ... unless they contain at least one capital letter


"" {{{{ statusline, tabline }}}}
set laststatus=2  " always display statusline
set statusline=   " clear out for reload
set statusline=%3.3n " buffer number
set statusline+=\ %F " full file path
set statusline+=\ %h%m%r%w " status flags
set statusline+=\ %#warningmsg# " highlight switch
"set statusline+=\ %{SyntasticStatuslineFlag()}
set statusline+=\ %* " highlight exit
set guitablabel=    " clear for reload
set guitablabel=%{GuiTabLabel()}


"" {{{{ colorschemes }}}}
"let g:neodark#use_256color = 1 " default: 0
colorscheme neodark
set t_Co=256


"" {{{{ netrw }}}}
let g:netrw_banner = 0 " hide banner
"let g:netrw_liststyle = 3 " tree list (causes buffer bug)


"" {{{{ Linting }}}}
" (manual invoke w/:SyntasticCheck)
let g:syntastic_mode_map = { 'mode': 'active',
                            \ 'active_filetypes': ['javascript'],
                            \ 'passive_filetypes': [] }
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


"" {{{{ Keymappings }}}}
"moving pane manipulation over to space-w, easier to use on 40% keyboards
map <Space> <leader>
noremap <Leader>r <C-r>
noremap <Leader>w <C-w>
noremap <Leader>/ :noh<Cr>
noremap <Leader>h :cd ~/repos/<Cr>
noremap <Leader>p :cd %:p:h<Cr>

" Scripts
noremap gC :call ToggleVimrc()<Cr>
noremap <Leader>= :call Whitespace()<Cr>
noremap <Leader>o :call OpenBrackets()<Cr>
xnoremap <Leader>* :<C-u>call <SID>VSetSearch('/')<CR>/<C-R>=@/<CR><CR>
xnoremap <Leader># :<C-u>call <SID>VSetSearch('?')<CR>?<C-R>=@/<CR><CR>

" External
noremap <Leader>F :tabnew +FZF<Cr>
noremap <Leader>G :tabnew +grep\<space>
"noremap gO :!open -a Adobe\ Photoshop\ CS5 <cfile><CR>


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

" {{{ HardMode }}}
"autocmd VimEnter,BufNewFile,BufReadPost * silent! call HardMode() " call on start


"" {{{{ Last Call }}}}
set path+=** " use ** by default for filepath commands
"cd ~/repos " Change to repos directory
