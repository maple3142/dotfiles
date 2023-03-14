set mouse=a " Hold shift while selecting to have normal selecting behavior
set tabstop=4 shiftwidth=4 expandtab
set number
set belloff=all
syntax on
set t_u7= " Fix automatically entering replace mode in Windows Terminal
set virtualedit=onemore
set autoindent
set incsearch
filetype plugin indent on
" map Ctrl-C to yank 
vmap <C-c> y 

" https://chromium.googlesource.com/apps/libapps/+/master/hterm/etc/osc52.vim
source ~/.vim/osc52.vim
augroup YankWithOSC52
    autocmd!
    autocmd TextYankPost * if v:event.operator is 'y' && v:event.regname is '' | call SendViaOSC52(getreg('"')) | endif
augroup END

