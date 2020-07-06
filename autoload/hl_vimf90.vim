scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:SPEED_MOST_IMPORTANT = 1
let s:SPEED_DEFAULT = 2

let s:EXCEPT_ETERNAL_LOOP_COUNT = 30

let s:last_cursor_moved = reltime()

function! hl_vimf90#enable()
  let ft = (exists('b:hl_vimf90_allow_ft') && '' != b:hl_vimf90_allow_ft) ?
        \ b:hl_vimf90_allow_ft : '*'
  packadd matchit
  augroup hl_vimf90
    au!
    exec 'au FileType' ft 'call hl_vimf90#enable_buffer()'
  augroup END
  doautoall hl_vimf90 FileType
endfunction

function! hl_vimf90#disable()
  augroup hl_vimf90
    au!
    au User * call hl_vimf90#hide()
  augroup END
  doautoall hl_vimf90 User
  au! hl_vimf90 User *
endfunction

function! hl_vimf90#enable_buffer()
  call hl_vimf90#disable_buffer()
  augroup hl_vimf90
    if 0 < b:hl_vimf90_cursor_wait
      au CursorMoved,CursorHold <buffer> call hl_vimf90#do_highlight_lazy()
    else
      au CursorMoved <buffer> call hl_vimf90#do_highlight()
    endif
  augroup END
  call hl_vimf90#do_highlight()
endfunction

function! hl_vimf90#disable_buffer()
  augroup hl_vimf90
    au! CursorMoved <buffer>
    au! CursorHold <buffer>
  augroup END
  call hl_vimf90#hide()
endfunction

function! hl_vimf90#hide()
  if exists('b:hl_vimf90_current_match_id')
    call matchdelete(b:hl_vimf90_current_match_id)
    unlet b:hl_vimf90_current_match_id
  endif
endfunction

function! hl_vimf90#do_highlight_lazy()
  let dt = str2float(reltimestr(reltime(s:last_cursor_moved)))
  echo "hl_vimf90: ".string(dt)
  if b:hl_vimf90_cursor_wait < dt
    call hl_vimf90#do_highlight()
  endif
  let s:last_cursor_moved = reltime()
endfunction

function! hl_vimf90#do_highlight()
    if !exists('b:match_words')
        return
    endif

    call hl_vimf90#hide()

    let l = getline('.')
    if b:hl_vimf90_speed_level <= s:SPEED_MOST_IMPORTANT
        if l =~ '[(){}]'
            return
        endif
    endif
    let char = l[col('.')-1]

    if b:hl_vimf90_speed_level <= s:SPEED_DEFAULT
        if char !~ '\w'
            return
        endif
    endif

    if foldclosed(line('.')) != -1
        return
    endif

    let restore_eventignore = &eventignore
    try
        set ei=all

        let wsv = winsaveview()
        let lcs = []

        let i = 0
        while 1
            if (i > s:EXCEPT_ETERNAL_LOOP_COUNT)
                let lcs = []
                break
            endif
            normal %
            let lc = {'line': line('.'), 'col': col('.')}
            if len(lcs) > 0 && lc.line == lcs[0].line && lc.col == lcs[0].col
                break
            endif
            call add(lcs, lc)
            let i = i+1
        endwhile

        "" temporary bug fix. when visual mode, Ctrl-v is not good...
        if s:is_visualmode()
            normal! gv
        endif

        if len(lcs) > 1
            let lcre = ''
            call map(lcs, '"\\%" . v:val.line . "l" . "\\%" . v:val.col . "c"')
            let lcre = join(lcs, '\|')
            let mw = split(b:match_words, ',\|:')
            let mw = filter(mw, 'v:val !~ "^[(){}[\\]]$"')
            let mwre = '\%(' . join(mw, '\|') . '\)'
            let mwre = substitute(mwre, "'", "''", 'g')
            " final \& part of the regexp is a hack to improve html
            let pattern = '.*\%(' . lcre . '\).*\&' . mwre . '\&\%(<\_[^>]\+>\|.*\)'
            let b:hl_vimf90_current_match_id =
                  \ matchadd(b:hl_vimf90_hl_groupname, pattern, b:hl_vimf90_hl_priority)
        endif
        call winrestview(wsv)
    finally
        execute("set eventignore=" . restore_eventignore)
    endtry
endfun


function! s:is_visualmode()
    let mode = mode()
    if (mode == 'v' || mode == 'V' || mode == 'CTRL-V')
        return 1
    endif
    return 0
endfun


let &cpo = s:save_cpo
unlet s:save_cpo
