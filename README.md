# l-abel-dotfiles
not just dotfiles!

## Automated Setup

`bin/dotf run` provisions the machine from `config/config.yml` via a small Ruby step runner. It bootstraps Homebrew/mise/Ruby/gum, then runs each step in `lib/dotfiles/steps/` in topo-sorted order, skipping any that are already complete (including symlinking the tracked dotfiles into `~`).

`bin/test` runs the Minitest suite under `test/`.

See [`docs/setup.md`](docs/setup.md) for the full layout, the step contract, and how to add a new step.

## vim
#### Highlights:

Whitespace cleanup method, additionally preserves one line at the end of the file:

```
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
```

.vimrc toggle method, which does the following:
* if .vimrc is not open, open it in a :$tabnew (tab at end of tab list)
* if .vimrc is open, switchbuf over to it (currently follows your switchbuf setting)
* if current buffer is .vimrc, close it

I currently have it bound to gC

```
function! ToggleVimrc()
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
endfunction
```

## tmux
A basic setup inspired by Brian P. Hogan's *tmux 2*.
