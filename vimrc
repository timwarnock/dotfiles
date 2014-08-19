"
" ~/.vimrc
"

set tabstop=4
set shiftwidth=4
set softtabstop=4
set nu
set modeline " /* vim: set ts=4 sw=4 expandtab : */
set wrap
set nolist
set textwidth=0
set expandtab " :set et   :set et!   :retab
set ai  " set noai
set cindent
set cinkeys-=0#
set indentkeys-=0#
set copyindent
set preserveindent


" use ; for : mode
nnoremap ; :

" ctags
set tags+=tags;$HOME
map <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR>
map <C-]> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>

set encoding=utf-8
set fillchars+=stl:\ ,stlnc:\
let g:Powerline_symbols = 'fancy'
set t_Co=256
let g:solarized_termcolors=256
syntax on
colorscheme elflord
"colorscheme railscast
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

" backspace
set backspace=2
set t_kb=

" statusline
set laststatus=2
set statusline=  
 set statusline+=%-3.3n\                      " buffer number
 set statusline+=%h%m%r%w                     " flags
 set statusline+=[%{strlen(&ft)?&ft:'none'},  " filetype
 set statusline+=%{strlen(&fenc)?&fenc:&enc}, " encoding
 set statusline+=%{&fileformat}]\             " file format
 set statusline+=%F\                          " file name
 set statusline+=%=                           " right align
set statusline+=%-12.([%b\=0x%B]%)\           " current char
set statusline+=%-10.(c%cv%v%)\               " column offset
set statusline+=%-12.(%l/%L%)\ %<%P          " line offset

" change the status line based on mode
hi StatusLine term=reverse ctermbg=7 ctermfg=8
if version >= 700
  au InsertEnter * hi StatusLine term=reverse ctermbg=7 ctermfg=12
  au InsertLeave * hi StatusLine term=reverse ctermbg=7 ctermfg=8
endif

" screen title
if &term == "screen"
  let &titlestring = "vim(" . expand("%:t") . ")"
  set t_ts=k 
  set t_fs=\
  set title
endif
autocmd TabEnter,WinEnter,BufReadPost,FileReadPost,BufNewFile * let &titlestring = 'vim(' . expand("%:t") . ')'

