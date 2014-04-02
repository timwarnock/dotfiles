"
" ~/.vimrc
"

set tabstop=4
set nu
set modeline
set nolist
set nowrap
set textwidth=0
" set noautoindent

syntax on
colors elflord
set showmatch
set hlsearch
hi search guibg=LightBlue 
hi LineNr ctermfg=darkgrey ctermbg=black
" :noh to turn off highlighted matches

" tab shortcuts ^j and ^k
nmap <C-k> :tabn<cr>
nmap <C-j> :tabp<cr>

" enable mouse
set mouse=a
set ttymouse=xterm2

set backspace=2
set t_kb=

" screen title
if &term == "screen"
  let &titlestring = "vim(" . expand("%:t") . ")"
  set t_ts=k 
  set t_fs=\
  "set t_fs=]1;
  "set t_fs=
  set title
endif
autocmd TabEnter,WinEnter,BufReadPost,FileReadPost,BufNewFile * let &titlestring = 'vim(' . expand("%:t") . ')'

