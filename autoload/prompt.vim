" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Document {{{
"==================================================
" Name: prompt.vim
" Version: 0.0.0
" Author:  tyru <tyru.exe@gmail.com>
" Last Change: 2009-12-20.
"
" Description:
"   Prompt with Vimperator-like keybind.
"
" Change Log: {{{
" }}}
" Usage: {{{
"   Commands: {{{
"   }}}
"   Mappings: {{{
"   }}}
"   Global Variables: {{{
"   }}}
" }}}
"==================================================
" }}}

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


" Validation functions {{{
func! s:no_validate(val)
    return 1
endfunc
func! s:is_int(val)
    return a:val =~# '^'.'0\+'.'$'
    \   || str2float(a:val) != 0
endfunc
func! s:is_num(val)
    return s:is_int(a:val)
    \   || a:val =~# '^'.'0\+'.'\.'.'0\+'.'$'
    \   || str2float(a:val) != 0
endfunc
func! s:is_str(val)
    return type(a:val) == type("")
endfunc
func! s:is_dict(val)
    return type(a:val) == type({})
endfunc
func! s:is_list(val)
    return type(a:val) == type([])
endfunc
func! s:is_function(val)
    return type(a:val) == type(function('tr'))
endfunc
func! s:is_menuoptbuftype(val)
    return a:val =~#
    \       '^'.'\(allcmdline\|cmdline\|'.
    \       'buffer\|allbuffer\|window\)'.'$'
endfunc
" }}}

" Candidates generator functions {{{
"   len(a:seq) must NOT be 0, maybe.
func! s:gen_seq_str(seq, idx)
    let div  = (a:idx + 1) / len(a:seq)
    let quot = (a:idx + 1) % len(a:seq)
    if div < 1 || (div == 1 && quot == 0)
        if quot == 0
            " NOTE: "abc"[-1] is ''. [1,2,3][-1] is 3, though...
            let quot = len(a:seq)
        endif
        return a:seq[quot - 1]
    else
        return a:seq[quot - 1] . s:gen_seq_str(a:seq, div - 1)
    endif
endfunc
func! s:generate_alpha(idx)
    return s:gen_seq_str("abcdefghijklmnopqrstuvwxyz", a:idx)
endfunc
func! s:generate_asdf(idx)
    return s:gen_seq_str("asdfghjkl;", a:idx)
endfunc
func! s:generate_num(idx)
    return a:idx + 1
endfunc
" }}}


" Scope Variables {{{
let s:debug_errmsg = []

" Options
let s:opt_info = {
\   'speed': {'arg_type': 'num'},
\   'echo': {'arg_type': 'str'},
\   'newline': {'arg_type': 'str'},
\   'default': {'arg_type': 'str'},
\   'require': {'arg_type': 'dict'},
\   'until': {'arg_type': 'str'},
\   'while': {'arg_type': 'str'},
\   'menu': {
\       'arg_type': ['list', 'dict'],
\       'add': {'menualpha': 1}
\   },
\   'onechar': {'arg_type': 'bool'},
\   'escape': {'arg_type': 'bool'},
\   'clear': {'arg_type': 'bool'},
\   'clearfirst': {'arg_type': 'bool'},
\   'argv': {'arg_type': 'bool'},
\   'line': {'arg_type': 'bool'},
\   'tty': {'arg_type': 'bool'},
\   'yes': {'arg_type': 'bool'},
\   'yesno': {'arg_type': 'bool'},
\   'YES': {'arg_type': 'bool'},
\   'YESNO': {'arg_type': 'bool'},
\   'number': {'arg_type': 'bool'},
\   'integer': {'arg_type': 'bool'},
\
\   'execute': {'arg_type': 'str'},
\   'menuarray': {'arg_type': 'function'},
\   'menualpha': {
\       'arg_type': 'bool',
\       'alias_of': {
\           'menuarray': function('<SID>generate_alpha')
\       }
\   },
\   'menuasdf': {
\       'arg_type': 'bool',
\       'alias_of': {
\           'menuarray': function('<SID>generate_asdf')
\       }
\   },
\   'menunum': {
\       'arg_type': 'bool',
\       'alias_of': {
\           'menuarray': function('<SID>generate_num')
\       }
\   },
\   'menuoptbuftype': {
\       'arg_type':
\           'custom:' .
\           string(function('<SID>is_menuoptbuftype'))
\   }
\}
" Aliases
call extend(s:opt_info, {
\   's': s:opt_info.speed,
\   'e': s:opt_info.echo,
\   'nl': s:opt_info.newline,
\   'd': s:opt_info.default,
\   'r': s:opt_info.require,
\   'u': s:opt_info.until,
\   'failif': s:opt_info.until,
\   'w': s:opt_info.while,
\   'okayif': s:opt_info.while,
\   'm': s:opt_info.menu,
\   '1': s:opt_info.onechar,
\   'x': s:opt_info.escape,
\   'c': s:opt_info.clear,
\   'f': s:opt_info.clearfirst,
\   'a': s:opt_info.argv,
\   'l': s:opt_info.line,
\   't': s:opt_info.tty,
\   'y': s:opt_info.yes,
\   'yn': s:opt_info.yesno,
\   'Y': s:opt_info.YES,
\   'YN': s:opt_info.YESNO,
\   'num': s:opt_info.number,
\   'i': s:opt_info.integer,
\}, 'error')

let s:validate_fn = {
\   'str': function('<SID>no_validate'),
\   'int': function('<SID>is_int'),
\   'num': function('<SID>is_num'),
\   'bool': function('<SID>no_validate'),
\   'dict': function('<SID>is_dict'),
\   'list': function('<SID>is_list'),
\   'function': function('<SID>is_function'),
\}
" }}}
" Global Variables {{{
if !exists('g:prompt_debug')
    let g:prompt_debug = 0
endif
" }}}

" Functions {{{

" Utility functions
" Debug {{{
if g:prompt_debug
    func! s:debug(cmd, ...)
        if a:cmd ==# 'on'
            let g:prompt_debug = 1
        elseif a:cmd ==# 'off'
            let g:prompt_debug = 0
        elseif a:cmd ==# 'list'
            for i in s:debug_errmsg
                echo i
            endfor
        elseif a:cmd ==# 'eval'
            redraw
            execute join(a:000, ' ')
        endif
    endfunc

    com! -nargs=+ PromptDebug
        \ call s:debug(<f-args>)
endif

" s:debugmsg {{{
func! s:debugmsg(msg)
    if g:prompt_debug
        call s:warn(a:msg)
    endif
endfunc
func! s:debugmsgf(fmt, ...)
    call s:debugmsg(call('printf', [a:fmt] + a:000))
endfunc
" }}}

" }}}
" s:warn {{{
func! s:warn(msg)
    echohl WarningMsg
    echomsg a:msg
    echohl None

    call add(s:debug_errmsg, a:msg)
endfunc
" }}}
" s:warnf {{{
func! s:warnf(fmt, ...)
    call s:warn(call('printf', [a:fmt] + a:000))
endfunc
" }}}
" s:getc {{{
func! s:getc(...)
    return nr2char(call('getchar', a:000))
endfunc
" }}}


" Objects.
" s:Object {{{
let s:Object = {}

func! s:Object.init() dict
    call s:debugmsg("s:Object.init()...")
endfunc

func! s:Object.clone() dict
    return deepcopy(self)
endfunc

func! s:Object.call(Fn, args) dict
    return call(a:Fn, a:args, self)
endfunc
let s:Object.apply = s:Object.call
" }}}
" s:Queue {{{
let s:Queue = s:Object.clone()

" s:Queue.init {{{
func! s:Queue.init() dict
    call s:debugmsg("s:Queue.init()...")
    call self.call(s:Object.init, [])

    let self.queue = []
endfunc
" }}}
" s:Queue.push {{{
func! s:Queue.push(val) dict
    call add(self.queue, a:val)
endfunc
" }}}
" s:Queue.execute {{{
func! s:Queue.execute(command)
    execute a:command remove(self.queue, 0)
endfunc
" }}}
" s:Queue.execute_all {{{
func! s:Queue.execute_all(command)
    for i in self.queue
        execute a:command i
    endfor
    let self.queue = []
endfunc
" }}}
" s:Queue.join_execute {{{
func! s:Queue.join_execute(command) dict
    let code = a:command
    for idx in range(0, len(self.queue) - 1)
        let code .= printf(' self.queue[%d]', idx)
    endfor
    execute code
    let self.queue = []
endfunc
" }}}
" s:Queue.map {{{
func! s:Queue.map(expr) dict
    return map(self.queue, a:expr)
endfunc
" }}}
" }}}
" s:Prompt {{{
let s:Prompt = s:Queue.clone()

" s:Prompt.init {{{
func! s:Prompt.init(msg, options) dict
    call s:debugmsg("s:Prompt.init()...")
    call self.call(s:Queue.init, [])

    let self.msg = a:msg
    let self.options = a:options
endfunc
" }}}
" s:Prompt.dispatch {{{
func! s:Prompt.dispatch() dict
    call s:Prompt.create_message_buffer()

    if has_key(self.options, 'menu')
        return self.run_menu(self.options.menu)
    endif
endfunc
" }}}
" s:Prompt.create_message_buffer() {{{
func! s:Prompt.create_message_buffer()
    if self.options.menuoptbuftype ==# 'allcmdline'
        " nop.
    else
        " TODO
    endif
endfunc
" }}}
" s:Prompt.run_menu {{{
func! s:Prompt.run_menu(list) dict
    let cur_input = ''
    let choice = self.filter_candidates(a:list, cur_input)

    while 1
        " Show candidates.
        call self.push(self.get_msg())
        for k in sort(keys(choice))
            call self.push(printf("\n%s. %s", k, choice[k]))
        endfor
        call s:debugmsgf('filtered by %s: choice = %s', cur_input, string(choice))

        " Show prompt.
        call self.push("\n> ")
        redraw
        call self.join_execute('echon')

        " Get input.
        let c = s:getc()
        if c == "\<ESC>"
            " throw 'pressed_esc'
            return self.options.default
        endif
        if c == "\<CR>"
            if cur_input == ''
                return self.options.default
            elseif has_key(choice, cur_input)
                let value = choice[cur_input]
                if s:is_dict(value) || s:is_list(value)
                    return self.run_menu(value)
                else
                    return value
                endif
            else
                call s:warn('bad choice.')
                continue
            endif
        endif

        if has_key(choice, cur_input . c)
            let choice = self.filter_candidates(a:list, cur_input . c)
            if len(choice) == 1
                let [value] = values(choice)
                if s:is_dict(value) || s:is_list(value)
                    return self.run_menu(value)
                else
                    return value
                endif
            else
                let cur_input .= c
            endif
        else
            call s:warn('bad choice.')
        endif
    endwhile
endfunc
" }}}
" s:Prompt.get_msg {{{
func! s:Prompt.get_msg() dict
    if has_key(self.options, 'menu')
        return self.msg "\n"
    else
        return self.msg
    endif
endfunc
" }}}
" s:Prompt.filter_candidates {{{
func! s:Prompt.filter_candidates(list, cur_input) dict
    let choice = {}
    for idx in range(0, len(a:list) - 1)
        let key = self.options.menuarray(idx) . ""
        let choice[key] = a:list[idx]
    endfor
    call s:debugmsgf('a:cur_input = %s, choice = %s', a:cur_input, string(choice))
    return a:cur_input == '' ? choice : filter(choice, 'stridx(v:key, a:cur_input) == 0')
endfunc
" }}}
" }}}


" s:match_info {{{
func! s:match_info(opt_name, opt_val)
    if s:is_str(a:opt_name)
        if stridx(a:opt_name, 'custom:') == 0
            let fn_str = substitute(a:opt_name, '^custom:', '', '')
            return eval(fn_str)(a:opt_val)
        else
            call s:debugmsgf("a:opt_name = %s, ".
            \                "a:opt_val = %s, ".
            \                "s:validate_fn[a:opt_name] = %s",
            \                string(a:opt_name),
            \                string(a:opt_val),
            \                string(s:validate_fn[a:opt_name]))
            return s:validate_fn[a:opt_name](a:opt_val)
        endif
    elseif s:is_list(a:opt_name)
        if len(a:opt_name) == 1
            return s:match_info(a:opt_name[0], a:opt_val)
        else
            return s:match_info(a:opt_name[0], a:opt_val)
            \   || s:match_info(a:opt_name[1:], a:opt_val)
        endif
    else
        throw 'internal_error'
    endif
endfunc
" }}}
" s:validate_options {{{
func! s:validate_options(options)
    for k in keys(a:options)
        call s:debugmsgf("k = %s, v = %s", string(k), string(a:options[k]))

        if !has_key(s:opt_info, k)
            throw 'unknown_option'
        elseif !s:match_info(s:opt_info[k].arg_type, a:options[k])
            throw printf('invalid_type: {%s:%s}', string(k), string(a:options[k]))
        endif
    endfor
endfunc
" }}}
" s:add_default_options {{{
func! s:add_default_options(options)
    return extend(copy(a:options), {
    \   'speed': '0.075',
    \   'default': '',
    \   'menualpha': 1,
    \   'menuoptbuftype': 'allcmdline',
    \}, 'keep')
endfunc
" }}}
" s:filter_options {{{
func! s:filter_options(options)
    let options = {}
    let expanded_options = {}    " not to override arguments specified by user.
    for k in keys(a:options)
        let options[k] = a:options[k]

        if has_key(s:opt_info[k], 'add')
            call extend(expanded_options, s:filter_options(s:opt_info[k].add), 'keep')
        elseif has_key(s:opt_info[k], 'alias_of')
            unlet options[k]
            call extend(expanded_options, s:filter_options(s:opt_info[k].alias_of), 'keep')
        endif
        unlet k
    endfor
    return extend(options, expanded_options, 'keep')
endfunc
" }}}

" prompt#prompt() {{{
func! prompt#prompt(msg, options)
    let options = {}
    for k in keys(a:options)
        " Remove '_' in option name.
        let options[substitute(k, '_', '', 'g')] = a:options[k]
        unlet k
    endfor

    let options = s:add_default_options(options)
    let options = s:filter_options(options)
    call s:validate_options(options)
    call s:debugmsg('options:' . string(options))

    call s:Prompt.init(a:msg, options)
    let value = s:Prompt.dispatch()
    if has_key(options, 'execute') && !empty(value)
        execute printf(options.execute, value)
        redraw
    endif
    return value
endfunc
" }}}

" }}}

" Commands {{{
" TODO
" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
