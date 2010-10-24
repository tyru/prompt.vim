" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Load Once {{{
if exists('g:loaded_prompt') && g:loaded_prompt
    finish
endif
let g:loaded_prompt = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" Global Variables {{{
if !exists('g:prompt_debug')
    let g:prompt_debug = 0
endif
if !exists('g:prompt_prompt')
    let g:prompt_prompt = '> '
endif
" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
