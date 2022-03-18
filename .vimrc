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

" WSL yank support
let s:clip = '/mnt/c/Windows/System32/clip.exe'  " change this path according to your mount point
if executable(s:clip)
    augroup WSLYank
        autocmd!
        autocmd TextYankPost * if v:event.operator ==# 'y' | call system('cat |' . s:clip, @0) | endif
    augroup END
endif

