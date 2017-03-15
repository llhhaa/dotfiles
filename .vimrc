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


"" {{{{ Vundle }}}}
filetype off " required for Vundle
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
" call vundle#begin('~/some/path/here')
Plugin 'gmarik/Vundle.vim' " let Vundle manage Vundle, required

"feature extension
Plugin 'tpope/vim-fugitive.git'
Plugin 'tpope/vim-commentary'
Plugin 'kana/vim-textobj-user'
Plugin 'kana/vim-textobj-entire'

"syntax & linting
Plugin 'pangloss/vim-javascript'
Plugin 'mxw/vim-jsx'
Plugin 'scooloose/syntastic'
Plugin 'mtscout6/syntastic-local-eslint.vim' " use project eslint

"misc
Plugin 'wikitopian/hardmode'
"Plugin 'scrooloose/nerdtree'

" all Vundle plugins must be added before the following line
call vundle#end() "required
filetype plugin indent on "required

"my plugin :)
"set rtp+=~/.vim/bundle/vim-rctoggle

"fzf
set rtp+=/usr/local/opt/fzf


"" {{{{ General Settings }}}}
set nocompatible		" no compatibility with legacy vi, required for Vundle
syntax enable
set encoding=utf-8
set showcmd			" display incomplete commands
set number      " show line numbers
set relativenumber
set wildmenu
set wildignore +=**/node_modules/**
filetype plugin indent on
au FocusGained,BufEnter * checktime "like gVim, prompt if file changed


"" {{{{ Whitespace }}}}
set nowrap
set tabstop=2 shiftwidth=2
set expandtab			" use spaces, not tabs (optional)
set backspace=indent,eol,start	" backspace through everything in insert mode

" Whitespace cleanup
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
set statusline+=\ %{SyntasticStatuslineFlag()}
set statusline+=\ %* " highlight exit

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
set guitablabel=    " clear for reload
set guitablabel=%{GuiTabLabel()}


"" {{{{ colorschemes }}}}
let g:neodark#use_256color = 1 " default: 0
colorscheme neodark


"" {{{{ netrw }}}}
let g:netrw_banner = 0 " hide banner
"let g:netrw_liststyle = 3 " tree list
"if that doesn't resolve netrw issue, try this
"autocmd FileType netrw setl bufhidden=wipe


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
"noremap <Leader>a <C-a>
noremap <Leader>r <C-r>
noremap <Leader>w <C-w>
"noremap <Leader>x <C-x>
noremap <Leader>F :tabnew +FZF<Cr>
noremap <Leader>G :tabnew +grep\<space>
noremap <Leader>= :call Whitespace()<Cr>
noremap <Leader>/ :noh<Cr>
noremap <Leader>p :cd %:p:h<Cr>
noremap <Leader>h :cd ~/repos/<Cr>
xnoremap <Leader>* :<C-u>call <SID>VSetSearch('/')<CR>/<C-R>=@/<CR><CR>
xnoremap <Leader># :<C-u>call <SID>VSetSearch('?')<CR>?<C-R>=@/<CR><CR>
noremap gC :call ToggleVimrc()<Cr>
noremap gO :!open -a Adobe\ Photoshop\ CS5 <cfile><CR>

function! ToggleVimrc()
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

function! OpenBrackets()
  "/}\|]/e
endfunction

function! s:VSetSearch(cmdtype)
  let temp = @s
  norm! gv"sy
  let @/ = '\V' . substitute(escape(@s, a:cmdtype.'\'), '\n', '\\n', 'g')
  let @s = temp
endfunction

"" {{{{ Plugin-specific settings }}}}

"" {{{{ ripgrep }}}}
"  use ripgrep instead of grep
if executable('rg')
  set grepprg=rg\ --vimgrep\ --no-heading\ --smart-case
  set grepformat=%f:%l:%c:%m,%f:%l:%m
endif


"" HardMode
"autocmd VimEnter,BufNewFile,BufReadPost * silent! call HardMode() " call on start


"" {{{{ Last Call }}}}
set path+=** " use ** by default for filepath commands
cd ~/repos " Change to repos directory
