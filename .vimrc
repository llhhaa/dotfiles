"Environment tools:
" " Homebrew packages (not necessarily deps for Vim):
" """ ripgrep
" """ task
" """ ctags
" """ ruby
" " Fonts
" """ Adobe Source Code Pro
" """ Fira Mono

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
Plug 'coderifous/textobj-word-column.vim'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'itspriddle/vim-marked'
Plug 'github/copilot.vim'
" Plug 'janko-m/vim-test'

" languages
Plug 'sheerun/vim-polyglot'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-rake'
Plug 'ngmy/vim-rubocop'
Plug 'tpope/vim-bundler'
Plug 'tpope/vim-apathy'
Plug 'mechatroner/rainbow_csv'
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Colorschemes
Plug 'owickstrom/vim-colors-paramount'
Plug 'romainl/apprentice'

call plug#end()

"" {{{{ General Settings }}}}
filetype plugin indent on
syntax enable
set re=0
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
au FocusGained,BufEnter * checktime "like gVim, prompt if file changed

" { CoC }
" https://pragmaticpineapple.com/ultimate-vim-typescript-setup/
set hidden
set nobackup
set nowritebackup
set noswapfile
set cmdheight=2
set updatetime=300
set shortmess+=c

" needed so vim gets the mouse in tmux
set ttymouse=xterm2
set mouse=a

" smart line joining in comments
if v:version > 703 || v:version == 703 && has('patch541')
  set formatoptions+=j
endif

" long line highlighting
" highlight ColorColumn ctermbg=gray
set colorcolumn=120

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
" highlight Comment cterm=italic gui=italic

"" {{{{ netrw }}}}
let g:netrw_banner = 0      " hide banner

"" {{{{ FZF }}}}
" let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6, 'highlight': 'Todo', 'rounded': v:false } }
" Customize fzf colors to match your color scheme
" - fzf#wrap translates this to a set of `--color` options
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }


" { CoC }
" https://pragmaticpineapple.com/ultimate-vim-typescript-setup/
" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("nvim-0.5.0") || has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: There's always complete item selected by default, you may want to enable
" no select by `"suggest.noselect": true` in your configuration file.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice.
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

let g:coc_global_extensions = ['coc-tsserver']

" END COC

" Ruby/Rails settings
autocmd FileType ruby,eruby let g:rubycomplete_buffer_loading = 1 
autocmd FileType ruby,eruby let g:rubycomplete_classes_in_global = 1
autocmd FileType ruby,eruby let g:rubycomplete_rails = 1
let g:vimrubocop_rubocop_cmd = 'bundle exec rubocop '

"" {{{{ Keymappings }}}}
map <Space> <leader>
"moving pane manipulation over to space-w, easier to use on 40% keyboards
noremap <Leader>w <C-w>

noremap <Leader>e :e **/*
noremap <Leader>h :cd ~/repos/<Cr>
" noremap <Leader>p :cd %:p:h<Cr>
noremap <Leader>r :s/:\(\w\+\)\(\s*\)=>\s*/\1:\2/g<Cr>
"copy and paste from keyboard
noremap <Leader>y "+y
noremap <Leader>p "+p
noremap <Leader>P "+P
noremap <Leader>v viw"0p

" Vim Terminal
" tnoremap <Esc> <C-W>N
" tnoremap <C-W><Esc> <Esc>
" set notimeout ttimeout timeoutlen=100

" Scripts
noremap gC :call ToggleVimrc()<Cr>
noremap <Leader>= :call Whitespace()<Cr>
xnoremap <Leader>* :<C-u>call <SID>VSetSearch('/')<CR>/<C-R>=@/<CR><CR>
xnoremap <Leader># :<C-u>call <SID>VSetSearch('?')<CR>?<C-R>=@/<CR><CR>

noremap <Leader>s f"r:;x

" External
"" FZF
noremap <Leader>f :GFiles<Cr>
noremap <Leader>F :Files<Cr>
noremap <Leader>b :Buffers<CR>
noremap <Leader>h :History<CR>
noremap <Leader>/ :Rg<CR>
" noremap <Leader>l :BLines<CR>
" noremap <Leader>L :Lines<CR>
" noremap <Leader>' :Marks<CR>

noremap <Leader>g :grep\<space>
noremap <Leader>G :tabnew +grep\<space>

" grep  word under cursor
noremap <Leader>l :grep<space><C-r><C-w><Cr> :copen<Cr>
noremap <Leader>L :tabnew +grep<space><C-r><C-w><Cr> :copen<Cr>

" go to file line in GitHub
noremap <Leader>B :'<,'>GBrowse!<Cr>

" Open alternate file in below split
noremap <Leader>S :sp<Cr>:A<Cr><C-w>J

" Copilot
noremap <Leader>c :Copilot panel

"" {{{{ Functions }}}}
command! DiffRuby vert new | set bt=nofile | set syntax=ruby | r ++edit # | 0d_
	 	\ | diffthis | wincmd p | diffthis

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

" switch to vimrc depending on context
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

" Visual-Star
function! s:VSetSearch(cmdtype)
  let temp = @s
  norm! gv"sy
  let @/ = '\V' . substitute(escape(@s, a:cmdtype.'\'), '\n', '\\n', 'g')
  let @s = temp
endfunction

"" {{{{ Plugin-specific settings }}}}
" {{{ ripgrep }}}
"  use ripgrep instead of grep
if executable('rg')
  set grepprg=rg\ --vimgrep\ --no-heading\ --smart-case\ --ignore-file\ ~/.rgignore
  set grepformat=%f:%l:%c:%m,%f:%l:%m
endif

"" {{{{ Last Call }}}}
" set path+=**
set suffixesadd=.html.erb
