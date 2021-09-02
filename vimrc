"General
set nocompatible
set modelines=10
set backspace=2
set tabpagemax=100
set encoding=utf-8

"Whitespace
set wrap
"set tabstop=2 shiftwidth=2 softtabstop=2
set cursorline
set expandtab
set modeline
set autoindent
set smartindent
set nojoinspaces
set tabstop=2
set softtabstop=2
set shiftwidth=2
set laststatus=2
set number
set ruler


"set cursorline
"set cursorcolumn

" change the mapleader from | to ,
let mapleader=","

" Quickly edit/reload the vimrc file
nmap <silent> <leader>ev :e $MYVIMRC<CR>
nmap <silent> <leader>sv :so $MYVIMRC<CR>
set runtimepath^=~/.vim/bundle/ctrlp.vim
nmap <leader>T :CtrlPBufTag<CR>
nmap <leader><leader>T :CtrlPBufTagAll<CR>

"Colors
syntax on
set t_Co=256

"Lines
set number
if exists('+colorcolumn')
    "set colorcolumn=101
    "au BufWinEnter * let w:m1=matchadd('ColorColumn', '\%<91v.\%>81v', -1)
    "au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>90v.\+', -1)
else
    "au BufWinEnter * let w:m1=matchadd('ErrorMsg', '\%<82v.\%>81v', -1)
    "au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>90v.\+', -1)
endif

"Searching
set hlsearch
set ignorecase
set smartcase

"Formatting
set list
set listchars=tab:>>
" set listchars+=trail:·

"Miscellaneous
set autoread
set clipboard=unnamed
set mouse=a
set wildmenu
set wildmode=longest,list

"
"Custom key mappings
"

" Tab usage
nnoremap <silent> <Leader>t :tabnew<CR>
nnoremap <silent> g{ :execute 'silent! tabmove ' . (tabpagenr()-2)<CR>
nnoremap <silent> g} :execute 'silent! tabmove ' . tabpagenr()<CR>

"Easier shortcut for previous tab
nnoremap gr gT

"Make Y yank act like D
nnoremap Y y$

"Make Home toggle between soft BOL and hard BOL
function! HomeKey()
    let pos = getpos('.')
    call search('^', 'bc')
    let bol = searchpos('\s*\S', 'cne')

    if pos[1] == bol[0] && pos[2] != bol[1]
        let pos[2] = bol[1]
        call setpos('.', pos)
    endif
endfunction
map <silent> <Home> :call HomeKey()<CR>

" Open blank line beneath
" nnoremap ,o o<Esc>S

" Enable spell check
nnoremap ,s :setlocal spell spelllang=en_us<CR>

" Set paste mode (no reformatting)
nnoremap ,v :set paste!<CR>

"Clear current search highlighting
" nnoremap <silent> ,/ :let @/=""<CR>

" Build script
" map ,, :w<CR>:!date<CR>:!./build<CR>:!./build/buildapp<CR><CR>

" Remove trailing spaces
" nnoremap ,<Space> :%s/[ \t]+$//g<CR>

"Open file under cursor in new tab
nnoremap gf <c-w>gf

" Folding and unfolding
map ,f :set foldmethod=indent<cr>zM
map ,F :set foldmethod=manual<cr>zR

" statusline
set statusline=%{fugitive#statusline()}

" switch to upper/lower window quickly
map <C-J> <C-W>j
map <C-K> <C-W>k
" switch to upper/lower window quickly
map <C-L> <C-W>l
map <C-H> <C-W>h

" visual shifting (does not exit Visual mode)
vnoremap < <gv
vnoremap > >gv


"
" NERDTree configuration
"

" Increase window size to 35 columns
let NERDTreeWinSize=35

" Tlist uses right window
let Tlist_Use_Right_Window = 1

nmap <Leader>nt :NERDTreeTabsToggle<CR>
nmap <Leader>tt :TbarToggle<CR>


highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()

set statusline=\ "
set statusline+=%1*%-25.80f%*\ " file name minimum 25, maxiumum 80 (right justified)
set statusline+=%2*
set statusline+=%h "help file flag
set statusline+=%r "read only flag
set statusline+=%m "modified flag
set statusline+=%w "preview flag
set statusline+=%*\ "
set statusline+=%3*[
set statusline+=%{strlen(&ft)?&ft:'none'} " filetype
set statusline+=]%*\ "
set statusline+=%4*%{fugitive#statusline()}%*\ " Fugitive
" set statusline+=%5*%{Rvm#statusline()}%*\ " RVM
" set statusline+=%6*%{SyntasticStatuslineFlag()}%* " Syntastic Syntax Checking
set statusline+=%= " right align
set statusline+=%8*%-14.(%l,%c%V%)\ %<%P%* " offset

" Directory Specific tab size
" set tabstop=2
"autocmd BufNewFile,BufRead ~/code/jg*.{css,js,html} set expandtab tabstop=2 shiftwidth=2
"autocmd BufNewFile,BufRead ~/code/ossus*.{php} set expandtab tabstop=4 shiftwidth=4
"autocmd BufNewFile,BufRead ~/code/falcon*.{php} set tabstop=4 shiftwidth=4

" TMUX cursor
if exists('$TMUX')
    let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
    let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
    let &t_SI = "\<Esc>]50;CursorShape=0\x7"
    let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

" Highlight current line
hi CursorLine   cterm=NONE ctermbg=darkred ctermfg=white guibg=darkred guifg=white
hi CursorColumn cterm=NONE ctermbg=darkred ctermfg=white guibg=darkred guifg=white
nnoremap <Leader>c :set cursorline! cursorcolumn!<CR>

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

"set rtp+=~/.vim/bundle/Vundle.vim
"call vundle#begin()
call plug#begin('~/.vim/plugged')

" Let Vundle Manage Vundle, required
Plug 'powerline/powerline'
Plug 'majutsushi/tagbar'
Plug 'scrooloose/nerdtree'
Plug 'scrooloose/nerdcommenter'
Plug 'jistr/vim-nerdtree-tabs'
"Plugin 'csapprox' " -- already handled by submodule
Plug 'vim-scripts/ChocolateLiquor'
Plug 'tpope/vim-fugitive'
Plug 'tpope/gem-ctags'
Plug 'kien/ctrlp.vim'
Plug 'fatih/vim-go'
Plug 'saltstack/salt-vim'
" Plugin 'stephpy/vim-php-cs-fixer'
" Plugin 'Lokaltog/powerline', {'rtp': 'powerline/bindings/vim/'}
Plug 'chase/vim-ansible-yaml'
Plug 'avakhov/vim-yaml'
" Adding Support for Elixir
" Plugin 'elixir-editors/vim-elixir'
" Adding Support for python

"Plug 'sjl/vitality.vim'
"Plugin 'desert-warm-256'
" Add Support for Ruby
" Add Support for Node

call plug#end() " required

if &t_Co >= 256
    "colorscheme vividchalk
    colorscheme ChocolateLiquor
    "colorscheme desert-warm-256
endif

let g:Powerline_symbols = 'fancy'
filetype plugin indent on
set guifont=Inconsolata\ for\ Powerline:h15
"let g:Powerline_symbols = 'fancy'
set encoding=utf-8
set t_Co=256
set fillchars+=stl:\ ,stlnc:\
set term=xterm-256color
set termencoding=utf-8



" # backup file
set backup

" tell vim where to put its backup files
set backupdir=/tmp
"
" tell vim where to put swap files
set dir=/tmp
