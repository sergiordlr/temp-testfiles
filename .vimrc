set formatoptions-=c
set formatoptions-=r
set formatoptions-=o
set noerrorbells visualbell t_vb=

let mapleader = ','

let g:loaded_youcompleteme = 1

let g:go_mod_fmt_autosave = 0

let g:go_imports_autosave = 0
let g:go_fmt_autosave = 0
let g:go_fmt_command = 'gofmt'
let g:go_fmt_options = '-s'

set nofixeol
set noeol
set nofixendofline
set background=dark
let g:go_auto_type_info = 1

" GoImplements defaults to locationlist; quickfix focuses the cursor properly
let g:go_list_type_commands = {'GoImplements': 'quickfix'}

" ,d opens the definition in a new tab
au FileType go nmap <Leader>d <Plug>(go-def-tab)

" Open quickfix selection in a new tab without affecting the original tab.
" Closes quickfix first, jumps to the entry to get the destination,
" restores the original buffer/view, then opens the destination in a new tab.
function! QfOpenInTab()
    let l:line = line('.')
    let l:buf = bufnr('%')
    cclose
    lclose
    let l:origview = winsaveview()
    let l:origbuf = bufnr('%')
    execute 'cc ' . l:line
    let l:destfile = expand('%:p')
    let l:destline = line('.')
    let l:destcol = col('.')
    execute 'buffer ' . l:origbuf
    call winrestview(l:origview)
    execute 'tabedit +' . l:destline . ' ' . fnameescape(l:destfile)
    execute 'normal! ' . l:destcol . '|'
endfunction

autocmd FileType qf nnoremap <buffer> <CR> :call QfOpenInTab()<CR>

" ,i — go to interface implementation with Ctrl-T support.
" GoImplements doesn't push to the tag stack, so we do it manually.
" Ctrl-T (GoDefPop) reads the native tag stack on vim-go master.
let g:go_implements_pending = 0

function! GoToImplementation()
    let pos = getcurpos()
    let item = {'bufnr': bufnr(), 'from': [bufnr(), pos[1], pos[2], 0], 'tagname': expand('<cword>')}
    call settagstack(win_getid(), {'items': [item]}, 'a')
    let g:go_implements_pending = 1
    GoImplements
endfunction

" Refocus quickfix after GoImplements. vim-go's async LSP handler
" restores focus to the original window (go/lsp.vim:214); the timer
" fires after that restore, so copen moves the cursor into the list.
autocmd FileType qf if g:go_implements_pending | let g:go_implements_pending = 0 | call timer_start(1, {-> execute('copen')}) | endif

autocmd FileType go nmap <Leader>i :call GoToImplementation()<CR>
