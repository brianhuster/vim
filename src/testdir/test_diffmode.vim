" Tests for diff mode

source util/screendump.vim

func Test_diff_fold_sync()
  enew!
  let g:update_count = 0
  au DiffUpdated * let g:update_count += 1

  let l = range(50)
  call setline(1, l)
  diffthis
  let winone = win_getid()
  new
  let l[25] = 'diff'
  call setline(1, l)
  diffthis
  let wintwo = win_getid()
  " line 15 is inside the closed fold
  call assert_equal(19, foldclosedend(10))
  call win_gotoid(winone)
  call assert_equal(19, foldclosedend(10))
  " open the fold
  normal zv
  call assert_equal(-1, foldclosedend(10))
  " fold in other window must have opened too
  call win_gotoid(wintwo)
  call assert_equal(-1, foldclosedend(10))

  " cursor position is in sync
  normal 23G
  call win_gotoid(winone)
  call assert_equal(23, getcurpos()[1])

  " depending on how redraw is done DiffUpdated may be triggered once or twice
  call assert_inrange(1, 2, g:update_count)
  au! DiffUpdated

  windo diffoff
  close!
  set nomodified
endfunc

func Test_vert_split()
  set diffopt=filler
  call Common_vert_split()
  set diffopt&
endfunc

" Test for diff folding redraw after last diff is resolved
func Test_diff_fold_redraw()
  " Set up two files with a minimal case.
  call writefile(['Paragraph 1', '', 'Paragraph 2', '', 'Paragraph 3'], 'Xfile1')
  call writefile(['Paragraph 1', '', 'Paragraph 3'], 'Xfile2')

  " Open in diff mode.
  edit Xfile1
  vert diffsplit Xfile2

  " Go to the diff and apply :diffput to copy Paragraph 2 to Xfile2.
  wincmd l
  3
  diffput

  " Check that the folds in both windows are closed and extend from the first
  " line of the buffer to the last line of the buffer.
  call assert_equal(1, foldclosed(line("$")))
  wincmd h
  call assert_equal(1, foldclosed(line("$")))

  " Clean up.
  bwipe!
  bwipe!
  call delete('Xfile1')
  call delete('Xfile2')
endfunc

func Test_vert_split_internal()
  set diffopt=internal,filler
  call Common_vert_split()
  set diffopt&
endfunc

func Common_vert_split()
  " Disable the title to avoid xterm keeping the wrong one.
  set notitle noicon
  new
  let l = ['1 aa', '2 bb', '3 cc', '4 dd', '5 ee']
  call setline(1, l)
  w! Xtest
  normal dd
  $
  put
  normal kkrXoxxx
  w! Xtest2
  file Nop
  normal ggoyyyjjjozzzz
  set foldmethod=marker foldcolumn=4
  call assert_equal(0, &diff)
  call assert_equal('marker', &foldmethod)
  call assert_equal(4, &foldcolumn)
  call assert_equal(0, &scrollbind)
  call assert_equal(0, &cursorbind)
  call assert_equal(1, &wrap)

  vert diffsplit Xtest
  vert diffsplit Xtest2
  call assert_equal(1, &diff)
  call assert_equal('diff', &foldmethod)
  call assert_equal(2, &foldcolumn)
  call assert_equal(1, &scrollbind)
  call assert_equal(1, &cursorbind)
  call assert_equal(0, &wrap)

  let diff_fdm = &fdm
  let diff_fdc = &fdc
  " repeat entering diff mode here to see if this saves the wrong settings
  diffthis
  " jump to second window for a moment to have filler line appear at start of
  " first window
  wincmd w
  normal gg
  wincmd p
  normal gg
  call assert_equal(2, winline())
  normal j
  call assert_equal(4, winline())
  normal j
  call assert_equal(5, winline())
  normal j
  call assert_equal(6, winline())
  normal j
  call assert_equal(8, winline())
  normal j
  call assert_equal(9, winline())

  wincmd w
  normal gg
  call assert_equal(1, winline())
  normal j
  call assert_equal(2, winline())
  normal j
  call assert_equal(4, winline())
  normal j
  call assert_equal(5, winline())
  normal j
  call assert_equal(8, winline())

  wincmd w
  normal gg
  call assert_equal(2, winline())
  normal j
  call assert_equal(3, winline())
  normal j
  call assert_equal(4, winline())
  normal j
  call assert_equal(5, winline())
  normal j
  call assert_equal(6, winline())
  normal j
  call assert_equal(7, winline())
  normal j
  call assert_equal(8, winline())

  " Test diffoff
  diffoff!
  1wincmd w
  let &diff = 1
  let &fdm = diff_fdm
  let &fdc = diff_fdc
  4wincmd w
  diffoff!
  1wincmd w
  call assert_equal(0, &diff)
  call assert_equal('marker', &foldmethod)
  call assert_equal(4, &foldcolumn)
  call assert_equal(0, &scrollbind)
  call assert_equal(0, &cursorbind)
  call assert_equal(1, &wrap)

  wincmd w
  call assert_equal(0, &diff)
  call assert_equal('marker', &foldmethod)
  call assert_equal(4, &foldcolumn)
  call assert_equal(0, &scrollbind)
  call assert_equal(0, &cursorbind)
  call assert_equal(1, &wrap)

  wincmd w
  call assert_equal(0, &diff)
  call assert_equal('marker', &foldmethod)
  call assert_equal(4, &foldcolumn)
  call assert_equal(0, &scrollbind)
  call assert_equal(0, &cursorbind)
  call assert_equal(1, &wrap)

  call delete('Xtest')
  call delete('Xtest2')
  windo bw!
endfunc

func Test_filler_lines()
  " Test that diffing shows correct filler lines
  enew!
  put =range(4,10)
  1d _
  vnew
  put =range(1,10)
  1d _
  windo diffthis
  wincmd h
  call assert_equal(1, line('w0'))
  unlet! diff_fdm diff_fdc
  windo diffoff
  bwipe!
  enew!
endfunc

func Test_diffget_diffput()
  enew!
  let l = range(50)
  call setline(1, l)
  call assert_fails('diffget', 'E99:')
  diffthis
  call assert_fails('diffget', 'E100:')
  new
  let l[10] = 'one'
  let l[20] = 'two'
  let l[30] = 'three'
  let l[40] = 'four'
  call setline(1, l)
  diffthis
  call assert_equal('one', getline(11))
  11diffget
  call assert_equal('10', getline(11))
  21diffput
  wincmd w
  call assert_equal('two', getline(21))
  normal 31Gdo
  call assert_equal('three', getline(31))
  call assert_equal('40', getline(41))
  normal 41Gdp
  wincmd w
  call assert_equal('40', getline(41))
  new
  diffthis
  call assert_fails('diffget', 'E101:')

  windo diffoff
  %bwipe!
endfunc

" Test putting two changes from one buffer to another
func Test_diffput_two()
  new a
  let win_a = win_getid()
  call setline(1, range(1, 10))
  diffthis
  new b
  let win_b = win_getid()
  call setline(1, range(1, 10))
  8del
  5del
  diffthis
  call win_gotoid(win_a)
  %diffput
  call win_gotoid(win_b)
  call assert_equal(map(range(1, 10), 'string(v:val)'), getline(1, '$'))
  bwipe! a
  bwipe! b
endfunc

" Test for :diffget/:diffput with a range that is inside a diff chunk
func Test_diffget_diffput_range()
  call setline(1, range(1, 10))
  new
  call setline(1, range(11, 20))
  windo diffthis
  3,5diffget
  call assert_equal(['13', '14', '15'], getline(3, 5))
  call setline(1, range(1, 10))
  4,8diffput
  wincmd p
  call assert_equal(['13', '4', '5', '6', '7', '8', '19'], getline(3, 9))
  %bw!
endfunc

" Test :diffget/:diffput handling of added/deleted lines
func Test_diffget_diffput_deleted_lines()
  call setline(1, ['2','4','6'])
  diffthis
  new
  call setline(1, range(1,7))
  diffthis
  wincmd w

  3,3diffget " get nothing
  call assert_equal(['2', '4', '6'], getline(1, '$'))
  3,4diffget " get the last insertion past the end of file
  call assert_equal(['2', '4', '6', '7'], getline(1, '$'))
  0,1diffget " get the first insertion above first line
  call assert_equal(['1', '2', '4', '6', '7'], getline(1, '$'))

  " When using non-range diffget on the last line, it should get the
  " change above or at the line as usual, but if the only change is below the
  " last line, diffget should get that instead.
  1,$delete
  call setline(1, ['2','4','6'])
  diffupdate
  norm Gdo
  call assert_equal(['2', '4', '5', '6'], getline(1, '$'))
  norm Gdo
  call assert_equal(['2', '4', '5', '6', '7'], getline(1, '$'))

  " Test non-range diffput on last line with the same logic
  1,$delete
  call setline(1, ['2','4','6'])
  diffupdate
  norm Gdp
  wincmd w
  call assert_equal(['1', '2', '3', '4', '6', '7'], getline(1, '$'))
  wincmd w
  norm Gdp
  wincmd w
  call assert_equal(['1', '2', '3', '4', '6'], getline(1, '$'))
  call setline(1, range(1,7))
  diffupdate
  wincmd w

  " Test that 0,$+1 will get/put all changes from/to the other buffer
  1,$delete
  call setline(1, ['2','4','6'])
  diffupdate
  0,$+1diffget
  call assert_equal(['1', '2', '3', '4', '5', '6', '7'], getline(1, '$'))
  1,$delete
  call setline(1, ['2','4','6'])
  diffupdate
  0,$+1diffput
  wincmd w
  call assert_equal(['2', '4', '6'], getline(1, '$'))
  %bw!
endfunc

" Test for :diffget/:diffput with an empty buffer and a non-empty buffer
func Test_diffget_diffput_empty_buffer()
  %d _
  new
  call setline(1, 'one')
  windo diffthis
  diffget
  call assert_equal(['one'], getline(1, '$'))
  %d _
  diffput
  wincmd p
  call assert_equal([''], getline(1, '$'))
  %bw!
endfunc

" :diffput and :diffget completes names of buffers which
" are in diff mode and which are different than current buffer.
" No completion when the current window is not in diff mode.
func Test_diffget_diffput_completion()
  e            Xdiff1 | diffthis
  botright new Xdiff2
  botright new Xdiff3 | split | diffthis
  botright new Xdiff4 | diffthis

  wincmd t
  call assert_equal('Xdiff1', bufname('%'))
  call feedkeys(":diffput \<C-A>\<C-B>\"\<CR>", 'tx')
  call assert_equal('"diffput Xdiff3 Xdiff4', @:)
  call feedkeys(":diffget \<C-A>\<C-B>\"\<CR>", 'tx')
  call assert_equal('"diffget Xdiff3 Xdiff4', @:)
  call assert_equal(['Xdiff3', 'Xdiff4'], getcompletion('', 'diff_buffer'))

  " Xdiff2 is not in diff mode, so no completion for :diffput, :diffget
  wincmd j
  call assert_equal('Xdiff2', bufname('%'))
  call feedkeys(":diffput \<C-A>\<C-B>\"\<CR>", 'tx')
  call assert_equal('"diffput ', @:)
  call feedkeys(":diffget \<C-A>\<C-B>\"\<CR>", 'tx')
  call assert_equal('"diffget ', @:)
  call assert_equal([], getcompletion('', 'diff_buffer'))

  " Xdiff3 is split in 2 windows, only the top one is in diff mode.
  " So completion of :diffput :diffget only happens in the top window.
  wincmd j
  call assert_equal('Xdiff3', bufname('%'))
  call assert_equal(1, &diff)
  call feedkeys(":diffput \<C-A>\<C-B>\"\<CR>", 'tx')
  call assert_equal('"diffput Xdiff1 Xdiff4', @:)
  call feedkeys(":diffget \<C-A>\<C-B>\"\<CR>", 'tx')
  call assert_equal('"diffget Xdiff1 Xdiff4', @:)
  call assert_equal(['Xdiff1', 'Xdiff4'], getcompletion('', 'diff_buffer'))

  wincmd j
  call assert_equal('Xdiff3', bufname('%'))
  call assert_equal(0, &diff)
  call feedkeys(":diffput \<C-A>\<C-B>\"\<CR>", 'tx')
  call assert_equal('"diffput ', @:)
  call feedkeys(":diffget \<C-A>\<C-B>\"\<CR>", 'tx')
  call assert_equal('"diffget ', @:)
  call assert_equal([], getcompletion('', 'diff_buffer'))

  wincmd j
  call assert_equal('Xdiff4', bufname('%'))
  call feedkeys(":diffput \<C-A>\<C-B>\"\<CR>", 'tx')
  call assert_equal('"diffput Xdiff1 Xdiff3', @:)
  call feedkeys(":diffget \<C-A>\<C-B>\"\<CR>", 'tx')
  call assert_equal('"diffget Xdiff1 Xdiff3', @:)
  call assert_equal(['Xdiff1', 'Xdiff3'], getcompletion('', 'diff_buffer'))

  %bwipe
endfunc

func Test_dp_do_buffer()
  e! one
  let bn1=bufnr('%')
  let l = range(60)
  call setline(1, l)
  diffthis

  new two
  let l[10] = 'one'
  let l[20] = 'two'
  let l[30] = 'three'
  let l[40] = 'four'
  let l[50] = 'five'
  call setline(1, l)
  diffthis

  " dp and do with invalid buffer number.
  11
  call assert_fails('norm 99999dp', 'E102:')
  call assert_fails('norm 99999do', 'E102:')
  call assert_fails('diffput non_existing_buffer', 'E94:')
  call assert_fails('diffget non_existing_buffer', 'E94:')

  " dp and do with valid buffer number.
  call assert_equal('one', getline('.'))
  exe 'norm ' . bn1 . 'do'
  call assert_equal('10', getline('.'))
  21
  call assert_equal('two', getline('.'))
  diffget one
  call assert_equal('20', getline('.'))

  31
  exe 'norm ' . bn1 . 'dp'
  41
  diffput one
  wincmd w
  31
  call assert_equal('three', getline('.'))
  41
  call assert_equal('four', getline('.'))

  " dp and do with buffer number which is not in diff mode.
  new not_in_diff_mode
  let bn3=bufnr('%')
  wincmd w
  51
  call assert_fails('exe "norm" . bn3 . "dp"', 'E103:')
  call assert_fails('exe "norm" . bn3 . "do"', 'E103:')
  call assert_fails('diffput not_in_diff_mode', 'E94:')
  call assert_fails('diffget not_in_diff_mode', 'E94:')

  windo diffoff
  %bwipe!
endfunc

func Test_do_lastline()
  e! one
  call setline(1, ['1','2','3','4','5','6'])
  diffthis

  new two
  call setline(1, ['2','4','5'])
  diffthis

  1
  norm dp]c
  norm dp]c
  wincmd w
  call assert_equal(4, line('$'))
  norm G
  norm do
  call assert_equal(3, line('$'))

  windo diffoff
  %bwipe!
endfunc

func Test_diffoff()
  enew!
  call setline(1, ['Two', 'Three'])
  redraw
  let normattr = screenattr(1, 1)
  diffthis
  botright vert new
  call setline(1, ['One', '', 'Two', 'Three'])
  diffthis
  redraw
  call assert_notequal(normattr, 1->screenattr(1))
  diffoff!
  redraw
  call assert_equal(normattr, screenattr(1, 1))
  bwipe!
  bwipe!
endfunc

func Common_icase_test()
  edit one
  call setline(1, ['One', 'Two', 'Three', 'Four', 'Fi#vϵ', 'Si⃗x', 'Se⃗ve⃗n'])
  redraw
  let normattr = screenattr(1, 1)
  diffthis

  botright vert new two
  call setline(1, ['one', 'TWO', 'Three ', 'Four', 'fI=VΕ', 'SI⃗x', 'SEvE⃗n'])
  diffthis

  redraw
  call assert_equal(normattr, screenattr(1, 1))
  call assert_equal(normattr, screenattr(2, 1))
  call assert_notequal(normattr, screenattr(3, 1))
  call assert_equal(normattr, screenattr(4, 1))
  call assert_equal(normattr, screenattr(6, 2))
  call assert_notequal(normattr, screenattr(7, 2))

  let dtextattr = screenattr(5, 3)
  call assert_notequal(dtextattr, screenattr(5, 1))
  call assert_notequal(dtextattr, screenattr(5, 5))
  call assert_notequal(dtextattr, screenattr(7, 4))

  diffoff!
  %bwipe!
endfunc

func Test_diffopt_icase()
  set diffopt=icase,foldcolumn:0
  call Common_icase_test()
  set diffopt&
endfunc

func Test_diffopt_icase_internal()
  set diffopt=icase,foldcolumn:0,internal
  call Common_icase_test()
  set diffopt&
endfunc

func Common_iwhite_test()
  edit one
  " Difference in trailing spaces and amount of spaces should be ignored,
  " but not other space differences.
  call setline(1, ["One \t", 'Two', 'Three', 'one two', 'one two', 'Four'])
  redraw
  let normattr = screenattr(1, 1)
  diffthis

  botright vert new two
  call setline(1, ["One\t ", "Two\t ", 'Three', 'one   two', 'onetwo', ' Four'])
  diffthis

  redraw
  call assert_equal(normattr, screenattr(1, 1))
  call assert_equal(normattr, screenattr(2, 1))
  call assert_equal(normattr, screenattr(3, 1))
  call assert_equal(normattr, screenattr(4, 1))
  call assert_notequal(normattr, screenattr(5, 1))
  call assert_notequal(normattr, screenattr(6, 1))

  diffoff!
  %bwipe!
endfunc

func Test_diffopt_iwhite()
  set diffopt=iwhite,foldcolumn:0
  call Common_iwhite_test()
  set diffopt&
endfunc

func Test_diffopt_iwhite_internal()
  set diffopt=internal,iwhite,foldcolumn:0
  call Common_iwhite_test()
  set diffopt&
endfunc

func Test_diffopt_context()
  enew!
  call setline(1, ['1', '2', '3', '4', '5', '6', '7'])
  diffthis
  new
  call setline(1, ['1', '2', '3', '4', '5x', '6', '7'])
  diffthis

  set diffopt=context:2
  call assert_equal('+--  2 lines: 1', foldtextresult(1))
  set diffopt=internal,context:2
  call assert_equal('+--  2 lines: 1', foldtextresult(1))

  set diffopt=context:1
  call assert_equal('+--  3 lines: 1', foldtextresult(1))
  set diffopt=internal,context:1
  call assert_equal('+--  3 lines: 1', foldtextresult(1))

  diffoff!
  %bwipe!
  set diffopt&
endfunc

func Test_diffopt_horizontal()
  set diffopt=internal,horizontal
  diffsplit

  call assert_equal(&columns, winwidth(1))
  call assert_equal(&columns, winwidth(2))
  call assert_equal(&lines, winheight(1) + winheight(2) + 3)
  call assert_inrange(0, 1, winheight(1) - winheight(2))

  set diffopt&
  diffoff!
  %bwipe
endfunc

func Test_diffopt_vertical()
  set diffopt=internal,vertical
  diffsplit

  call assert_equal(&lines - 2, winheight(1))
  call assert_equal(&lines - 2, winheight(2))
  call assert_equal(&columns, winwidth(1) + winwidth(2) + 1)
  call assert_inrange(0, 1, winwidth(1) - winwidth(2))

  set diffopt&
  diffoff!
  %bwipe
endfunc

func Test_diffopt_hiddenoff()
  set diffopt=internal,filler,foldcolumn:0,hiddenoff
  e! one
  call setline(1, ['Two', 'Three'])
  redraw
  let normattr = screenattr(1, 1)
  diffthis
  botright vert new two
  call setline(1, ['One', 'Four'])
  diffthis
  redraw
  call assert_notequal(normattr, screenattr(1, 1))
  set hidden
  close
  redraw
  " should not diffing with hidden buffer two while 'hiddenoff' is enabled
  call assert_equal(normattr, screenattr(1, 1))

  bwipe!
  bwipe!
  set hidden& diffopt&
endfunc

func Test_diffoff_hidden()
  set diffopt=internal,filler,foldcolumn:0
  e! one
  call setline(1, ['Two', 'Three'])
  redraw
  let normattr = screenattr(1, 1)
  diffthis
  botright vert new two
  call setline(1, ['One', 'Four'])
  diffthis
  redraw
  call assert_notequal(normattr, screenattr(1, 1))
  set hidden
  close
  redraw
  " diffing with hidden buffer two
  call assert_notequal(normattr, screenattr(1, 1))
  diffoff
  redraw
  call assert_equal(normattr, screenattr(1, 1))
  diffthis
  redraw
  " still diffing with hidden buffer two
  call assert_notequal(normattr, screenattr(1, 1))
  diffoff!
  redraw
  call assert_equal(normattr, screenattr(1, 1))
  diffthis
  redraw
  " no longer diffing with hidden buffer two
  call assert_equal(normattr, screenattr(1, 1))

  bwipe!
  bwipe!
  set hidden& diffopt&
endfunc

func Test_setting_cursor()
  new Xtest1
  put =range(1,90)
  wq
  new Xtest2
  put =range(1,100)
  wq

  tabe Xtest2
  $
  diffsp Xtest1
  tabclose

  call delete('Xtest1')
  call delete('Xtest2')
endfunc

func Test_diff_move_to()
  new
  call setline(1, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  diffthis
  vnew
  call setline(1, [1, '2x', 3, 4, 4, 5, '6x', 7, '8x', 9, '10x'])
  diffthis
  norm ]c
  call assert_equal(2, line('.'))
  norm 3]c
  call assert_equal(9, line('.'))
  norm 10]c
  call assert_equal(11, line('.'))
  norm [c
  call assert_equal(9, line('.'))
  norm 2[c
  call assert_equal(5, line('.'))
  norm 10[c
  call assert_equal(2, line('.'))
  %bwipe!
endfunc

func Test_diffexpr()
  CheckExecutable diff

  func DiffExpr()
    " Prepend some text to check diff type detection
    call writefile(['warning', '  message'], v:fname_out)
    silent exe '!diff ' . v:fname_in . ' ' . v:fname_new . '>>' . v:fname_out
  endfunc
  set diffexpr=DiffExpr()
  set diffopt=foldcolumn:0

  enew!
  call setline(1, ['one', 'two', 'three'])
  redraw
  let normattr = screenattr(1, 1)
  diffthis

  botright vert new
  call setline(1, ['one', 'two', 'three.'])
  diffthis

  redraw
  call assert_equal(normattr, screenattr(1, 1))
  call assert_equal(normattr, screenattr(2, 1))
  call assert_notequal(normattr, screenattr(3, 1))
  diffoff!

  " Try using a non-existing function for 'diffexpr'.
  set diffexpr=NewDiffFunc()
  call assert_fails('windo diffthis', ['E117:', 'E97:'])
  diffoff!

  " Using a script-local function
  func s:NewDiffExpr()
  endfunc
  set diffexpr=s:NewDiffExpr()
  call assert_equal(expand('<SID>') .. 'NewDiffExpr()', &diffexpr)
  set diffexpr=<SID>NewDiffExpr()
  call assert_equal(expand('<SID>') .. 'NewDiffExpr()', &diffexpr)

  %bwipe!
  set diffexpr& diffopt&
  delfunc DiffExpr
  delfunc s:NewDiffExpr
endfunc

func Test_diffpatch()
  " The patch program on MS-Windows may fail or hang.
  CheckExecutable patch
  CheckUnix
  new
  insert
***************
*** 1,3 ****
  1
! 2
  3
--- 1,4 ----
  1
! 2x
  3
+ 4
.
  saveas! Xpatch
  bwipe!
  new
  call assert_fails('diffpatch Xpatch', 'E816:')

  for name in ['Xpatch', 'Xpatch$HOME', 'Xpa''tch']
    call setline(1, ['1', '2', '3'])
    if name != 'Xpatch'
      call rename('Xpatch', name)
    endif
    exe 'diffpatch ' . escape(name, '$')
    call assert_equal(['1', '2x', '3', '4'], getline(1, '$'))
    if name != 'Xpatch'
      call rename(name, 'Xpatch')
    endif
    bwipe!
  endfor

  call delete('Xpatch')
  bwipe!
endfunc

" FIXME: test fails, the Xresult file can't be read
func No_Test_diffpatch_restricted()
  let lines =<< trim END
    call assert_fails('diffpatch NoSuchDiff', 'E145:')

    call writefile(v:errors, 'Xresult')
    qa!
  END
  call writefile(lines, 'Xrestricted', 'D')
  if RunVim([], [], '-Z --clean -S Xrestricted')
    call assert_equal([], readfile('Xresult'))
  endif
  call delete('Xresult')
endfunc

func Test_diff_too_many_buffers()
  for i in range(1, 8)
    exe "new Xtest" . i
    diffthis
  endfor
  new Xtest9
  call assert_fails('diffthis', 'E96:')
  %bwipe!
endfunc

func Test_diff_nomodifiable()
  new
  call setline(1, [1, 2, 3, 4])
  setl nomodifiable
  diffthis
  vnew
  call setline(1, ['1x', 2, 3, 3, 4])
  diffthis
  call assert_fails('norm dp', 'E793:')
  setl nomodifiable
  call assert_fails('norm do', 'E21:')
  %bwipe!
endfunc

func Test_diff_hlID()
  new
  call setline(1, [1, 2, 3, 'Yz', 'a dxxg',])
  diffthis
  vnew
  call setline(1, ['1x', 2, 'x', 3, 'yx', 'abc defg'])
  diffthis
  redraw

  call diff_hlID(-1, 1)->synIDattr("name")->assert_equal("")

  call diff_hlID(1, 1)->synIDattr("name")->assert_equal("DiffChange")
  call diff_hlID(1, 2)->synIDattr("name")->assert_equal("DiffText")
  call diff_hlID(2, 1)->synIDattr("name")->assert_equal("")
  call diff_hlID(3, 1)->synIDattr("name")->assert_equal("DiffAdd")
  eval 4->diff_hlID(1)->synIDattr("name")->assert_equal("")
  call diff_hlID(5, 1)->synIDattr("name")->assert_equal("DiffText")
  call diff_hlID(5, 2)->synIDattr("name")->assert_equal("DiffText")

  set diffopt+=icase " test that caching is invalidated by diffopt change
  call diff_hlID(5, 1)->synIDattr("name")->assert_equal("DiffChange")
  set diffopt-=icase
  call diff_hlID(5, 1)->synIDattr("name")->assert_equal("DiffText")

  call diff_hlID(6, 1)->synIDattr("name")->assert_equal("DiffChange")
  call diff_hlID(6, 2)->synIDattr("name")->assert_equal("DiffText")
  call diff_hlID(6, 4)->synIDattr("name")->assert_equal("DiffText")
  call diff_hlID(6, 7)->synIDattr("name")->assert_equal("DiffText")
  call diff_hlID(6, 8)->synIDattr("name")->assert_equal("DiffChange")
  set diffopt+=inline:char
  call diff_hlID(6, 1)->synIDattr("name")->assert_equal("DiffChange")
  call diff_hlID(6, 2)->synIDattr("name")->assert_equal("DiffTextAdd")
  call diff_hlID(6, 4)->synIDattr("name")->assert_equal("DiffChange")
  call diff_hlID(6, 7)->synIDattr("name")->assert_equal("DiffText")
  call diff_hlID(6, 8)->synIDattr("name")->assert_equal("DiffChange")
  set diffopt-=inline:char

  wincmd w
  call assert_equal(synIDattr(diff_hlID(1, 1), "name"), "DiffChange")
  call assert_equal(synIDattr(diff_hlID(2, 1), "name"), "")
  call assert_equal(synIDattr(diff_hlID(3, 1), "name"), "")

  %bwipe!
endfunc

func Test_diff_filler()
  new
  call setline(1, [1, 2, 3, 'x', 4])
  diffthis
  vnew
  call setline(1, [1, 2, 'y', 'y', 3, 4])
  diffthis
  redraw

  call assert_equal([0, 0, 0, 0, 0, 0, 0, 1, 0], map(range(-1, 7), 'v:val->diff_filler()'))
  wincmd w
  call assert_equal([0, 0, 0, 0, 2, 0, 0, 0], map(range(-1, 6), 'diff_filler(v:val)'))

  %bwipe!
endfunc

func Test_diff_lastline()
  enew!
  only!
  call setline(1, ['This is a ', 'line with five ', 'rows'])
  diffthis
  botright vert new
  call setline(1, ['This is', 'a line with ', 'four rows'])
  diffthis
  1
  call feedkeys("Je a\<CR>", 'tx')
  call feedkeys("Je a\<CR>", 'tx')
  let w1lines = winline()
  wincmd w
  $
  let w2lines = winline()
  call assert_equal(w2lines, w1lines)
  bwipe!
  bwipe!
endfunc

func WriteDiffFiles(buf, list1, list2)
  call writefile(a:list1, 'Xdifile1')
  call writefile(a:list2, 'Xdifile2')
  if a:buf
    call term_sendkeys(a:buf, ":checktime\<CR>")
  endif
endfunc

func WriteDiffFiles3(buf, list1, list2, list3)
  call writefile(a:list1, 'Xdifile1')
  call writefile(a:list2, 'Xdifile2')
  call writefile(a:list3, 'Xdifile3')
  if a:buf
    call term_sendkeys(a:buf, ":checktime\<CR>")
  endif
endfunc

" Verify a screendump with both the internal and external diff.
func VerifyBoth(buf, dumpfile, extra)
  CheckScreendump

  " trailing : for leaving the cursor on the command line
  for cmd in [":set diffopt=filler" . a:extra . "\<CR>:", ":set diffopt+=internal\<CR>:"]
    call term_sendkeys(a:buf, cmd)
    if VerifyScreenDump(a:buf, a:dumpfile, {}, cmd =~ 'internal' ? 'internal' : 'external')
      " don't let the next iteration overwrite the "failed" file.
      return
    endif
  endfor

  " also test unified diff
  call term_sendkeys(a:buf, ":call SetupUnified()\<CR>:")
  call term_sendkeys(a:buf, ":redraw!\<CR>:")
  call VerifyScreenDump(a:buf, a:dumpfile, {}, 'unified')
  call term_sendkeys(a:buf, ":call StopUnified()\<CR>:")
endfunc

" Verify a screendump with the internal diff only.
func VerifyInternal(buf, dumpfile, extra)
  CheckScreendump

  call term_sendkeys(a:buf, ":diffupdate!\<CR>")
  " trailing : for leaving the cursor on the command line
  call term_sendkeys(a:buf, ":set diffopt=internal,filler" . a:extra . "\<CR>:")
  call VerifyScreenDump(a:buf, a:dumpfile, {})
endfunc

func Test_diff_screen()
  if has('osxdarwin') && system('diff --version') =~ '^Apple diff'
    throw 'Skipped: unified diff does not work properly on this macOS version'
  endif

  let g:test_is_flaky = 1
  CheckScreendump
  CheckFeature menu

  let lines =<< trim END
      func UnifiedDiffExpr()
        " Prepend some text to check diff type detection
        call writefile(['warning', '  message'], v:fname_out)
        silent exe '!diff -U0 ' .. v:fname_in .. ' ' .. v:fname_new .. '>>' .. v:fname_out
      endfunc
      func SetupUnified()
        set diffexpr=UnifiedDiffExpr()
        diffupdate
      endfunc
      func StopUnified()
        set diffexpr=
      endfunc
  END
  call writefile(lines, 'XdiffSetup', 'D')

  " clean up already existing swap files, just in case
  call delete('.Xdifile1.swp')
  call delete('.Xdifile2.swp')

  " Test 1: Add a line in beginning of file 2
  call WriteDiffFiles(0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  let buf = RunVimInTerminal('-d -S XdiffSetup Xdifile1 Xdifile2', {})
  " Set autoread mode, so that Vim won't complain once we re-write the test
  " files
  call term_sendkeys(buf, ":set autoread\<CR>\<c-w>w:set autoread\<CR>\<c-w>w")

  call VerifyBoth(buf, 'Test_diff_01', '')

  " Test 2: Add a line in beginning of file 1
  call WriteDiffFiles(buf, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  call VerifyBoth(buf, 'Test_diff_02', '')

  " Test 3: Add a line at the end of file 2
  call WriteDiffFiles(buf, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
  call VerifyBoth(buf, 'Test_diff_03', '')

  " Test 4: Add a line at the end of file 1
  call WriteDiffFiles(buf, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  call VerifyBoth(buf, 'Test_diff_04', '')

  " Test 5: Add a line in the middle of file 2, remove on at the end of file 1
  call WriteDiffFiles(buf, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], [1, 2, 3, 4, 4, 5, 6, 7, 8, 9, 10])
  call VerifyBoth(buf, 'Test_diff_05', '')

  " Test 6: Add a line in the middle of file 1, remove on at the end of file 2
  call WriteDiffFiles(buf, [1, 2, 3, 4, 4, 5, 6, 7, 8, 9, 10], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
  call VerifyBoth(buf, 'Test_diff_06', '')

  " Variants on test 6 with different context settings
  call term_sendkeys(buf, ":set diffopt+=context:2\<cr>")
  call VerifyScreenDump(buf, 'Test_diff_06.2', {})
  call term_sendkeys(buf, ":set diffopt-=context:2\<cr>")
  call term_sendkeys(buf, ":set diffopt+=context:1\<cr>")
  call VerifyScreenDump(buf, 'Test_diff_06.1', {})
  call term_sendkeys(buf, ":set diffopt-=context:1\<cr>")
  call term_sendkeys(buf, ":set diffopt+=context:0\<cr>")
  call VerifyScreenDump(buf, 'Test_diff_06.0', {})
  call term_sendkeys(buf, ":set diffopt-=context:0\<cr>")

  " Test 7 - 9: Test normal/patience/histogram diff algorithm
  call WriteDiffFiles(buf, ['#include <stdio.h>', '', '// Frobs foo heartily', 'int frobnitz(int foo)', '{',
      \ '    int i;', '    for(i = 0; i < 10; i++)', '    {', '        printf("Your answer is: ");',
      \ '        printf("%d\n", foo);', '    }', '}', '', 'int fact(int n)', '{', '    if(n > 1)', '    {',
      \ '        return fact(n-1) * n;', '    }', '    return 1;', '}', '', 'int main(int argc, char **argv)',
      \ '{', '    frobnitz(fact(10));', '}'],
      \ ['#include <stdio.h>', '', 'int fib(int n)', '{', '    if(n > 2)', '    {',
      \ '        return fib(n-1) + fib(n-2);', '    }', '    return 1;', '}', '', '// Frobs foo heartily',
      \ 'int frobnitz(int foo)', '{', '    int i;', '    for(i = 0; i < 10; i++)', '    {',
      \ '        printf("%d\n", foo);', '    }', '}', '',
      \ 'int main(int argc, char **argv)', '{', '    frobnitz(fib(10));', '}'])
  call term_sendkeys(buf, ":diffupdate!\<cr>")
  call term_sendkeys(buf, ":set diffopt+=internal\<cr>")
  call VerifyScreenDump(buf, 'Test_diff_07', {})

  call term_sendkeys(buf, ":set diffopt+=algorithm:patience\<cr>")
  call VerifyScreenDump(buf, 'Test_diff_08', {})

  call term_sendkeys(buf, ":set diffopt+=algorithm:histogram\<cr>")
  call VerifyScreenDump(buf, 'Test_diff_09', {})

  " Test 10-11: normal/indent-heuristic
  call term_sendkeys(buf, ":set diffopt&vim\<cr>")
  call WriteDiffFiles(buf, ['', '  def finalize(values)', '', '    values.each do |v|', '      v.finalize', '    end'],
      \ ['', '  def finalize(values)', '', '    values.each do |v|', '      v.prepare', '    end', '',
      \ '    values.each do |v|', '      v.finalize', '    end'])
  call term_sendkeys(buf, ":diffupdate!\<cr>")
  call term_sendkeys(buf, ":set diffopt+=internal\<cr>")
  call VerifyScreenDump(buf, 'Test_diff_10', {})

  " Leave trailing : at commandline!
  call term_sendkeys(buf, ":set diffopt+=indent-heuristic\<cr>:\<cr>")
  call VerifyScreenDump(buf, 'Test_diff_11', {}, 'one')
  " shouldn't matter, if indent-algorithm comes before or after the algorithm
  call term_sendkeys(buf, ":set diffopt&\<cr>")
  call term_sendkeys(buf, ":set diffopt+=indent-heuristic,algorithm:patience\<cr>:\<cr>")
  call VerifyScreenDump(buf, 'Test_diff_11', {}, 'two')
  call term_sendkeys(buf, ":set diffopt&\<cr>")
  call term_sendkeys(buf, ":set diffopt+=algorithm:patience,indent-heuristic\<cr>:\<cr>")
  call VerifyScreenDump(buf, 'Test_diff_11', {}, 'three')

  " Test 12: diff the same file
  call WriteDiffFiles(buf, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  call VerifyBoth(buf, 'Test_diff_12', '')

  " Test 13: diff an empty file
  call WriteDiffFiles(buf, [], [])
  call VerifyBoth(buf, 'Test_diff_13', '')

  " Test 14: test diffopt+=icase
  call WriteDiffFiles(buf, ['a', 'b', 'cd'], ['A', 'b', 'cDe'])
  call VerifyBoth(buf, 'Test_diff_14', " diffopt+=filler diffopt+=icase")

  " Test 15-16: test diffopt+=iwhite
  call WriteDiffFiles(buf, ['int main()', '{', '   printf("Hello, World!");', '   return 0;', '}'],
      \ ['int main()', '{', '   if (0)', '   {', '      printf("Hello, World!");', '      return 0;', '   }', '}'])
  call term_sendkeys(buf, ":diffupdate!\<cr>")
  call term_sendkeys(buf, ":set diffopt&vim diffopt+=filler diffopt+=iwhite\<cr>")
  call VerifyScreenDump(buf, 'Test_diff_15', {})
  call term_sendkeys(buf, ":set diffopt+=internal\<cr>")
  call VerifyScreenDump(buf, 'Test_diff_16', {})

  " Test 17: test diffopt+=iblank
  call WriteDiffFiles(buf, ['a', ' ', 'cd', 'ef', 'xxx'], ['a', 'cd', '', 'ef', 'yyy'])
  call VerifyInternal(buf, 'Test_diff_17', " diffopt+=iblank")

  " Test 18: test diffopt+=iblank,iwhite / iwhiteall / iwhiteeol
  call VerifyInternal(buf, 'Test_diff_18', " diffopt+=iblank,iwhite")
  call VerifyInternal(buf, 'Test_diff_18', " diffopt+=iblank,iwhiteall")
  call VerifyInternal(buf, 'Test_diff_18', " diffopt+=iblank,iwhiteeol")

  " Test 19: test diffopt+=iwhiteeol
  call WriteDiffFiles(buf, ['a ', 'x', 'cd', 'ef', 'xx  xx', 'foo', 'bar'], ['a', 'x', 'c d', ' ef', 'xx xx', 'foo', '', 'bar'])
  call VerifyInternal(buf, 'Test_diff_19', " diffopt+=iwhiteeol")

  " Test 20: test diffopt+=iwhiteall
  call VerifyInternal(buf, 'Test_diff_20', " diffopt+=iwhiteall")

  " Test 21: Delete all lines
  call WriteDiffFiles(buf, [0], [])
  call VerifyBoth(buf, "Test_diff_21", "")

  " Test 22: Add line to empty file
  call WriteDiffFiles(buf, [], [0])
  call VerifyBoth(buf, "Test_diff_22", "")

  call WriteDiffFiles(buf, ['?a', '?b', '?c'], ['!b'])
  call VerifyInternal(buf, 'Test_diff_23', " diffopt+=linematch:30")

  call WriteDiffFiles(buf, ['',
      \ 'common line',
      \ 'common line',
      \ '',
      \ 'DEFabc',
      \ 'xyz',
      \ 'xyz',
      \ 'xyz',
      \ 'DEFabc',
      \ 'DEFabc',
      \ 'DEFabc',
      \ 'common line',
      \ 'common line',
      \ 'DEF',
      \ 'common line',
      \ 'DEF',
      \ 'something' ],
      \ ['',
      \ 'common line',
      \ 'common line',
      \ '',
      \ 'ABCabc',
      \ 'ABCabc',
      \ 'ABCabc',
      \ 'ABCabc',
      \ 'common line',
      \ 'common line',
      \ 'common line',
      \ 'something'])
  call VerifyInternal(buf, 'Test_diff_24', " diffopt+=linematch:30")


  " clean up
  call StopVimInTerminal(buf)
  call delete('Xdifile1')
  call delete('Xdifile2')
endfunc

func Test_diff_with_scroll_and_change()
  CheckScreendump

  let lines =<< trim END
	call setline(1, range(1, 15))
	vnew
	call setline(1, range(9, 15))
	windo diffthis
	wincmd h
	exe "normal Gl5\<C-E>"
  END
  call writefile(lines, 'Xtest_scroll_change', 'D')
  let buf = RunVimInTerminal('-S Xtest_scroll_change', {})

  call VerifyScreenDump(buf, 'Test_diff_scroll_change_01', {})

  call term_sendkeys(buf, "ax\<Esc>")
  call VerifyScreenDump(buf, 'Test_diff_scroll_change_02', {})

  call term_sendkeys(buf, "\<C-W>lay\<Esc>")
  call VerifyScreenDump(buf, 'Test_diff_scroll_change_03', {})

  " clean up
  call StopVimInTerminal(buf)
endfunc

func Test_diff_with_cursorline()
  CheckScreendump

  call writefile([
	\ 'hi CursorLine ctermbg=red ctermfg=white',
	\ 'set cursorline',
	\ 'call setline(1, ["foo","foo","foo","bar"])',
	\ 'vnew',
	\ 'call setline(1, ["bee","foo","foo","baz"])',
	\ 'windo diffthis',
	\ '2wincmd w',
	\ ], 'Xtest_diff_cursorline', 'D')
  let buf = RunVimInTerminal('-S Xtest_diff_cursorline', {})

  call VerifyScreenDump(buf, 'Test_diff_with_cursorline_01', {})
  call term_sendkeys(buf, "j")
  call VerifyScreenDump(buf, 'Test_diff_with_cursorline_02', {})
  call term_sendkeys(buf, "j")
  call VerifyScreenDump(buf, 'Test_diff_with_cursorline_03', {})

  " clean up
  call StopVimInTerminal(buf)
endfunc

func Test_diff_with_cursorline_number()
  CheckScreendump

  let lines =<< trim END
      hi CursorLine ctermbg=red ctermfg=white
      hi CursorLineNr ctermbg=white ctermfg=black cterm=underline
      set cursorline number
      call setline(1, ["baz", "foo", "foo", "bar"])
      2
      vnew
      call setline(1, ["foo", "foo", "bar"])
      windo diffthis
      1wincmd w
  END
  call writefile(lines, 'Xtest_diff_cursorline_number', 'D')
  let buf = RunVimInTerminal('-S Xtest_diff_cursorline_number', {})

  call VerifyScreenDump(buf, 'Test_diff_with_cursorline_number_01', {})
  call term_sendkeys(buf, ":set cursorlineopt=number\r")
  call VerifyScreenDump(buf, 'Test_diff_with_cursorline_number_02', {})

  " clean up
  call StopVimInTerminal(buf)
endfunc

func Test_diff_with_cursorline_breakindent()
  CheckScreendump

  let lines =<< trim END
    hi CursorLine ctermbg=red ctermfg=white
    set noequalalways wrap diffopt=followwrap cursorline breakindent
    50vnew
    call setline(1, ['  ', '  ', '  ', '  '])
    exe "norm! 20Afoo\<Esc>j20Afoo\<Esc>j20Afoo\<Esc>j20Abar\<Esc>"
    vnew
    call setline(1, ['  ', '  ', '  ', '  '])
    exe "norm! 20Abee\<Esc>j20Afoo\<Esc>j20Afoo\<Esc>j20Abaz\<Esc>"
    windo diffthis
    2wincmd w
  END
  call writefile(lines, 'Xtest_diff_cursorline_breakindent', 'D')
  let buf = RunVimInTerminal('-S Xtest_diff_cursorline_breakindent', {})

  call term_sendkeys(buf, "gg0")
  call VerifyScreenDump(buf, 'Test_diff_with_cul_bri_01', {})
  call term_sendkeys(buf, "j")
  call VerifyScreenDump(buf, 'Test_diff_with_cul_bri_02', {})
  call term_sendkeys(buf, "j")
  call VerifyScreenDump(buf, 'Test_diff_with_cul_bri_03', {})
  call term_sendkeys(buf, "j")
  call VerifyScreenDump(buf, 'Test_diff_with_cul_bri_04', {})

  " clean up
  call StopVimInTerminal(buf)
endfunc

func Test_diff_breakindent_after_filler()
  CheckScreendump

  let lines =<< trim END
    set laststatus=0 diffopt+=followwrap breakindent breakindentopt=min:0
    call setline(1, ['a', '  ' .. repeat('c', 50)])
    vnew
    call setline(1, ['a', 'b', '  ' .. repeat('c', 50)])
    windo diffthis
    norm! G$
  END
  call writefile(lines, 'Xtest_diff_breakindent_after_filler', 'D')
  let buf = RunVimInTerminal('-S Xtest_diff_breakindent_after_filler', #{rows: 8, cols: 45})
  call VerifyScreenDump(buf, 'Test_diff_breakindent_after_filler', {})

  " clean up
  call StopVimInTerminal(buf)
endfunc

func Test_diff_with_syntax()
  CheckScreendump

  let lines =<< trim END
	void doNothing() {
	   int x = 0;
	   char *s = "hello";
	   return 5;
	}
  END
  call writefile(lines, 'Xprogram1.c', 'D')
  let lines =<< trim END
	void doSomething() {
	   int x = 0;
	   char *s = "there";
	   return 5;
	}
  END
  call writefile(lines, 'Xprogram2.c', 'D')

  let lines =<< trim END
	edit Xprogram1.c
	diffsplit Xprogram2.c
  END
  call writefile(lines, 'Xtest_diff_syntax', 'D')
  let buf = RunVimInTerminal('-S Xtest_diff_syntax', {})

  call VerifyScreenDump(buf, 'Test_diff_syntax_1', {})

  " clean up
  call StopVimInTerminal(buf)
endfunc

func Test_diff_of_diff()
  CheckScreendump
  CheckFeature rightleft

  call writefile([
	\ 'call setline(1, ["aa","bb","cc","@@ -3,2 +5,7 @@","dd","ee","ff"])',
	\ 'vnew',
	\ 'call setline(1, ["aa","bb","cc"])',
	\ 'windo diffthis',
	\ '1wincmd w',
	\ 'setlocal number',
	\ ], 'Xtest_diff_diff', 'D')
  let buf = RunVimInTerminal('-S Xtest_diff_diff', {})

  call VerifyScreenDump(buf, 'Test_diff_of_diff_01', {})

  call term_sendkeys(buf, ":set rightleft\<cr>")
  call VerifyScreenDump(buf, 'Test_diff_of_diff_02', {})

  " clean up
  call StopVimInTerminal(buf)
endfunc

func CloseoffSetup()
  enew
  call setline(1, ['one', 'two', 'three'])
  diffthis
  new
  call setline(1, ['one', 'tow', 'three'])
  diffthis
  call assert_equal(1, &diff)
  bw!
endfunc

func Test_diff_closeoff()
  " "closeoff" included by default: last diff win gets 'diff' reset'
  call CloseoffSetup()
  call assert_equal(0, &diff)
  enew!

  " "closeoff" excluded: last diff win keeps 'diff' set'
  set diffopt-=closeoff
  call CloseoffSetup()
  call assert_equal(1, &diff)
  diffoff!
  enew!
endfunc

func Test_diff_followwrap()
  new
  set diffopt+=followwrap
  set wrap
  diffthis
  call assert_equal(1, &wrap)
  diffoff
  set nowrap
  diffthis
  call assert_equal(0, &wrap)
  diffoff
  set diffopt&
  bwipe!
endfunc

func Test_diff_maintains_change_mark()
  func DiffMaintainsChangeMark()
    enew!
    call setline(1, ['a', 'b', 'c', 'd'])
    diffthis
    new
    call setline(1, ['a', 'b', 'c', 'e'])
    " Set '[ and '] marks
    2,3yank
    call assert_equal([2, 3], [line("'["), line("']")])
    " Verify they aren't affected by the implicit diff
    diffthis
    call assert_equal([2, 3], [line("'["), line("']")])
    " Verify they aren't affected by an explicit diff
    diffupdate
    call assert_equal([2, 3], [line("'["), line("']")])
    bwipe!
    bwipe!
  endfunc

  set diffopt-=internal
  call DiffMaintainsChangeMark()
  set diffopt+=internal
  call DiffMaintainsChangeMark()

  set diffopt&
  delfunc DiffMaintainsChangeMark
endfunc

" Test for 'patchexpr'
func Test_patchexpr()
  let g:patch_args = []
  func TPatch()
    call add(g:patch_args, readfile(v:fname_in))
    call add(g:patch_args, readfile(v:fname_diff))
    call writefile(['output file'], v:fname_out)
  endfunc
  set patchexpr=TPatch()

  call writefile(['input file'], 'Xinput', 'D')
  call writefile(['diff file'], 'Xdiff', 'D')
  %bwipe!
  edit Xinput
  diffpatch Xdiff
  call assert_equal('output file', getline(1))
  call assert_equal('Xinput.new', bufname())
  call assert_equal(2, winnr('$'))
  call assert_true(&diff)

  " Using a script-local function
  func s:NewPatchExpr()
  endfunc
  set patchexpr=s:NewPatchExpr()
  call assert_equal(expand('<SID>') .. 'NewPatchExpr()', &patchexpr)
  set patchexpr=<SID>NewPatchExpr()
  call assert_equal(expand('<SID>') .. 'NewPatchExpr()', &patchexpr)

  set patchexpr&
  delfunc TPatch
  delfunc s:NewPatchExpr
  %bwipe!
endfunc

func Test_diff_rnu()
  CheckScreendump

  let content =<< trim END
    call setline(1, ['a', 'a', 'a', 'y', 'b', 'b', 'b', 'b', 'b'])
    vnew
    call setline(1, ['a', 'a', 'a', 'x', 'x', 'x', 'b', 'b', 'b', 'b', 'b'])
    windo diffthis
    setlocal number rnu foldcolumn=0
  END
  call writefile(content, 'Xtest_diff_rnu', 'D')
  let buf = RunVimInTerminal('-S Xtest_diff_rnu', {})

  call VerifyScreenDump(buf, 'Test_diff_rnu_01', {})

  call term_sendkeys(buf, "j")
  call VerifyScreenDump(buf, 'Test_diff_rnu_02', {})
  call term_sendkeys(buf, "j")
  call VerifyScreenDump(buf, 'Test_diff_rnu_03', {})

  " clean up
  call StopVimInTerminal(buf)
endfunc

func Test_diff_multilineconceal()
  new
  diffthis

  new
  call matchadd('Conceal', 'a\nb', 9, -1, {'conceal': 'Y'})
  set cole=2 cocu=n
  call setline(1, ["a", "b"])
  diffthis
  redraw
endfunc

func Test_diff_and_scroll()
  " this was causing an ml_get error
  set ls=2
  for i in range(winheight(0) * 2)
    call setline(i, i < winheight(0) - 10 ? i : i + 10)
  endfor
  vnew
  for i in range(winheight(0)*2 + 10)
    call setline(i, i < winheight(0) - 10 ? 0 : i)
  endfor
  diffthis
  wincmd p
  diffthis
  execute 'normal ' . winheight(0) . "\<C-d>"

  bwipe!
  bwipe!
  set ls&
endfunc

func Test_diff_filler_cursorcolumn()
  CheckScreendump

  let content =<< trim END
    call setline(1, ['aa', 'bb', 'cc'])
    vnew
    call setline(1, ['aa', 'cc'])
    windo diffthis
    wincmd p
    setlocal cursorcolumn foldcolumn=0
    norm! gg0
    redraw!
  END
  call writefile(content, 'Xtest_diff_cuc', 'D')
  let buf = RunVimInTerminal('-S Xtest_diff_cuc', {})

  call VerifyScreenDump(buf, 'Test_diff_cuc_01', {})

  call term_sendkeys(buf, "l")
  call term_sendkeys(buf, "\<C-l>")
  call VerifyScreenDump(buf, 'Test_diff_cuc_02', {})
  call term_sendkeys(buf, "0j")
  call term_sendkeys(buf, "\<C-l>")
  call VerifyScreenDump(buf, 'Test_diff_cuc_03', {})
  call term_sendkeys(buf, "l")
  call term_sendkeys(buf, "\<C-l>")
  call VerifyScreenDump(buf, 'Test_diff_cuc_04', {})

  " clean up
  call StopVimInTerminal(buf)
endfunc

" Test for adding/removing lines inside diff chunks, between diff chunks
" and before diff chunks
func Test_diff_modify_chunks()
  enew!
  let w2_id = win_getid()
  call setline(1, ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'])
  new
  let w1_id = win_getid()
  call setline(1, ['a', '2', '3', 'd', 'e', 'f', '7', '8', 'i'])
  windo diffthis

  " remove a line between two diff chunks and create a new diff chunk
  call win_gotoid(w2_id)
  5d
  call win_gotoid(w1_id)
  call diff_hlID(5, 1)->synIDattr('name')->assert_equal('DiffAdd')

  " add a line between two diff chunks
  call win_gotoid(w2_id)
  normal! 4Goe
  call win_gotoid(w1_id)
  call diff_hlID(4, 1)->synIDattr('name')->assert_equal('')
  call diff_hlID(5, 1)->synIDattr('name')->assert_equal('')

  " remove all the lines in a diff chunk.
  call win_gotoid(w2_id)
  7,8d
  call win_gotoid(w1_id)
  let hl = range(1, 9)->map({_, lnum -> diff_hlID(lnum, 1)->synIDattr('name')})
  call assert_equal(['', 'DiffText', 'DiffText', '', '', '', 'DiffAdd',
        \ 'DiffAdd', ''], hl)

  " remove lines from one diff chunk to just before the next diff chunk
  call win_gotoid(w2_id)
  call setline(1, ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'])
  2,6d
  call win_gotoid(w1_id)
  let hl = range(1, 9)->map({_, lnum -> diff_hlID(lnum, 1)->synIDattr('name')})
  call assert_equal(['', 'DiffText', 'DiffText', 'DiffAdd', 'DiffAdd',
        \ 'DiffAdd', 'DiffAdd', 'DiffAdd', ''], hl)

  " remove lines just before the top of a diff chunk
  call win_gotoid(w2_id)
  call setline(1, ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'])
  5,6d
  call win_gotoid(w1_id)
  let hl = range(1, 9)->map({_, lnum -> diff_hlID(lnum, 1)->synIDattr('name')})
  call assert_equal(['', 'DiffText', 'DiffText', '', 'DiffText', 'DiffText',
        \ 'DiffAdd', 'DiffAdd', ''], hl)

  " remove line after the end of a diff chunk
  call win_gotoid(w2_id)
  call setline(1, ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'])
  4d
  call win_gotoid(w1_id)
  let hl = range(1, 9)->map({_, lnum -> diff_hlID(lnum, 1)->synIDattr('name')})
  call assert_equal(['', 'DiffText', 'DiffText', 'DiffAdd', '', '', 'DiffText',
        \ 'DiffText', ''], hl)

  " remove lines starting from the end of one diff chunk and ending inside
  " another diff chunk
  call win_gotoid(w2_id)
  call setline(1, ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'])
  4,7d
  call win_gotoid(w1_id)
  let hl = range(1, 9)->map({_, lnum -> diff_hlID(lnum, 1)->synIDattr('name')})
  call assert_equal(['', 'DiffText', 'DiffText', 'DiffText', 'DiffAdd',
        \ 'DiffAdd', 'DiffAdd', 'DiffAdd', ''], hl)

  " removing the only remaining diff chunk should make the files equal
  call win_gotoid(w2_id)
  call setline(1, ['a', '2', '3', 'x', 'd', 'e', 'f', 'x', '7', '8', 'i'])
  8d
  let hl = range(1, 10)->map({_, lnum -> diff_hlID(lnum, 1)->synIDattr('name')})
  call assert_equal(['', '', '', 'DiffAdd', '', '', '', '', '', ''], hl)
  call win_gotoid(w2_id)
  4d
  call win_gotoid(w1_id)
  let hl = range(1, 9)->map({_, lnum -> diff_hlID(lnum, 1)->synIDattr('name')})
  call assert_equal(['', '', '', '', '', '', '', '', ''], hl)

  %bw!
endfunc

func Test_diff_binary()
  CheckScreendump

  let content =<< trim END
    call setline(1, ['a', 'b', "c\n", 'd', 'e', 'f', 'g'])
    vnew
    call setline(1, ['A', 'b', 'c', 'd', 'E', 'f', 'g'])
    windo diffthis
    wincmd p
    norm! gg0
    redraw!
  END
  call writefile(content, 'Xtest_diff_bin', 'D')
  let buf = RunVimInTerminal('-S Xtest_diff_bin', {})

  " Test using internal diff
  call VerifyScreenDump(buf, 'Test_diff_bin_01', {})

  " Test using internal diff and case folding
  call term_sendkeys(buf, ":set diffopt+=icase\<cr>")
  call term_sendkeys(buf, "\<C-l>")
  call VerifyScreenDump(buf, 'Test_diff_bin_02', {})
  " Test using external diff
  call term_sendkeys(buf, ":set diffopt=filler\<cr>")
  call term_sendkeys(buf, "\<C-l>")
  call VerifyScreenDump(buf, 'Test_diff_bin_03', {})
  " Test using external diff and case folding
  call term_sendkeys(buf, ":set diffopt=filler,icase\<cr>")
  call term_sendkeys(buf, "\<C-l>")
  call VerifyScreenDump(buf, 'Test_diff_bin_04', {})

  " clean up
  call StopVimInTerminal(buf)
  set diffopt&vim
endfunc

" Test for using the 'zi' command to invert 'foldenable' in diff windows (test
" for the issue fixed by patch 6.2.317)
func Test_diff_foldinvert()
  %bw!
  edit Xdoffile1
  new Xdoffile2
  new Xdoffile3
  windo diffthis
  " open a non-diff window
  botright new
  1wincmd w
  call assert_true(getwinvar(1, '&foldenable'))
  call assert_true(getwinvar(2, '&foldenable'))
  call assert_true(getwinvar(3, '&foldenable'))
  normal zi
  call assert_false(getwinvar(1, '&foldenable'))
  call assert_false(getwinvar(2, '&foldenable'))
  call assert_false(getwinvar(3, '&foldenable'))
  normal zi
  call assert_true(getwinvar(1, '&foldenable'))
  call assert_true(getwinvar(2, '&foldenable'))
  call assert_true(getwinvar(3, '&foldenable'))

  " If the current window has 'noscrollbind', then 'zi' should not change
  " 'foldenable' in other windows.
  1wincmd w
  set noscrollbind
  normal zi
  call assert_false(getwinvar(1, '&foldenable'))
  call assert_true(getwinvar(2, '&foldenable'))
  call assert_true(getwinvar(3, '&foldenable'))

  " 'zi' should not change the 'foldenable' for windows with 'noscrollbind'
  1wincmd w
  set scrollbind
  normal zi
  call setwinvar(2, '&scrollbind', v:false)
  normal zi
  call assert_false(getwinvar(1, '&foldenable'))
  call assert_true(getwinvar(2, '&foldenable'))
  call assert_false(getwinvar(3, '&foldenable'))

  %bw!
  set scrollbind&
endfunc

" This was scrolling for 'cursorbind' but 'scrollbind' is more important
func Test_diff_scroll()
  CheckScreendump

  let left =<< trim END
      line 1
      line 2
      line 3
      line 4

      // Common block
      // one
      // containing
      // four lines

      // Common block
      // two
      // containing
      // four lines
  END
  call writefile(left, 'Xleft', 'D')
  let right =<< trim END
      line 1
      line 2
      line 3
      line 4

      Lorem
      ipsum
      dolor
      sit
      amet,
      consectetur
      adipiscing
      elit.
      Etiam
      luctus
      lectus
      sodales,
      dictum

      // Common block
      // one
      // containing
      // four lines

      Vestibulum
      tincidunt
      aliquet
      nulla.

      // Common block
      // two
      // containing
      // four lines
  END
  call writefile(right, 'Xright', 'D')
  let buf = RunVimInTerminal('-d Xleft Xright', {'rows': 12})
  call term_sendkeys(buf, "\<C-W>\<C-W>jjjj")
  call VerifyScreenDump(buf, 'Test_diff_scroll_1', {})
  call term_sendkeys(buf, "j")
  call VerifyScreenDump(buf, 'Test_diff_scroll_2', {})

  call StopVimInTerminal(buf)
endfunc

" This was scrolling too many lines.
func Test_diff_scroll_wrap_on()
  20new
  40vsplit
  call setline(1, map(range(1, 9), 'repeat(v:val, 200)'))
  setlocal number diff so=0
  redraw
  normal! jj
  call assert_equal(1, winsaveview().topline)
  normal! j
  call assert_equal(2, winsaveview().topline)

  bwipe!
  bwipe!
endfunc

func Test_diff_scroll_many_filler()
  20new
  vnew
  call setline(1, range(1, 40))
  diffthis
  setlocal scrolloff=0
  wincmd p
  call setline(1, range(1, 20)->reverse() + ['###']->repeat(41) + range(21, 40)->reverse())
  diffthis
  setlocal scrolloff=0
  wincmd p
  redraw

  " Note: need a redraw after each scroll, otherwise the test always passes.
  for _ in range(2)
    normal! G
    redraw
    call assert_equal(40, winsaveview().topline)
    call assert_equal(19, winsaveview().topfill)
    exe "normal! \<C-B>"
    redraw
    call assert_equal(22, winsaveview().topline)
    call assert_equal(0, winsaveview().topfill)
    exe "normal! \<C-B>"
    redraw
    call assert_equal(4, winsaveview().topline)
    call assert_equal(0, winsaveview().topfill)
    exe "normal! \<C-B>"
    redraw
    call assert_equal(1, winsaveview().topline)
    call assert_equal(0, winsaveview().topfill)
    set smoothscroll
  endfor

  set smoothscroll&
  %bwipe!
endfunc

" This was trying to update diffs for a buffer being closed
func Test_diff_only()
  silent! lfile
  set diff
  lopen
  norm o
  silent! norm o

  set nodiff
  %bwipe!
endfunc

" This was causing invalid diff block values
" FIXME: somehow this causes a valgrind error when run directly but not when
" run as a test.
func Test_diff_manipulations()
  set diff
  split 0
  sil! norm RdoobdeuRdoobdeuRdoobdeu

  set nodiff
  %bwipe!
endfunc

" This was causing the line number in the diff block to go below one.
" FIXME: somehow this causes a valgrind error when run directly but not when
" run as a test.
func Test_diff_put_and_undo()
  set diff
  next 0
  split 00
  sil! norm o0gguudpo0ggJuudp

  bwipe!
  bwipe!
  set nodiff
endfunc

" Test for the diff() function
def Test_diff_func()
  # string is added/removed/modified at the beginning
  assert_equal("@@ -0,0 +1 @@\n+abc\n",
               diff(['def'], ['abc', 'def'], {output: 'unified'}))
  assert_equal([{from_idx: 0, from_count: 0, to_idx: 0, to_count: 1}],
               diff(['def'], ['abc', 'def'], {output: 'indices'}))
  assert_equal("@@ -1 +0,0 @@\n-abc\n",
               diff(['abc', 'def'], ['def'], {output: 'unified'}))
  assert_equal([{from_idx: 0, from_count: 1, to_idx: 0, to_count: 0}],
               diff(['abc', 'def'], ['def'], {output: 'indices'}))
  assert_equal("@@ -1 +1 @@\n-abc\n+abx\n",
               diff(['abc', 'def'], ['abx', 'def'], {output: 'unified'}))
  assert_equal([{from_idx: 0, from_count: 1, to_idx: 0, to_count: 1}],
               diff(['abc', 'def'], ['abx', 'def'], {output: 'indices'}))

  # string is added/removed/modified at the end
  assert_equal("@@ -1,0 +2 @@\n+def\n",
               diff(['abc'], ['abc', 'def'], {output: 'unified'}))
  assert_equal([{from_idx: 1, from_count: 0, to_idx: 1, to_count: 1}],
               diff(['abc'], ['abc', 'def'], {output: 'indices'}))
  assert_equal("@@ -2 +1,0 @@\n-def\n",
               diff(['abc', 'def'], ['abc'], {output: 'unified'}))
  assert_equal([{from_idx: 1, from_count: 1, to_idx: 1, to_count: 0}],
               diff(['abc', 'def'], ['abc'], {output: 'indices'}))
  assert_equal("@@ -2 +2 @@\n-def\n+xef\n",
               diff(['abc', 'def'], ['abc', 'xef'], {output: 'unified'}))
  assert_equal([{from_idx: 1, from_count: 1, to_idx: 1, to_count: 1}],
               diff(['abc', 'def'], ['abc', 'xef'], {output: 'indices'}))

  # string is added/removed/modified in the middle
  assert_equal("@@ -2,0 +3 @@\n+xxx\n",
               diff(['111', '222', '333'], ['111', '222', 'xxx', '333'], {output: 'unified'}))
  assert_equal([{from_idx: 2, from_count: 0, to_idx: 2, to_count: 1}],
               diff(['111', '222', '333'], ['111', '222', 'xxx', '333'], {output: 'indices'}))
  assert_equal("@@ -3 +2,0 @@\n-333\n",
               diff(['111', '222', '333', '444'], ['111', '222', '444'], {output: 'unified'}))
  assert_equal([{from_idx: 2, from_count: 1, to_idx: 2, to_count: 0}],
               diff(['111', '222', '333', '444'], ['111', '222', '444'], {output: 'indices'}))
  assert_equal("@@ -3 +3 @@\n-333\n+xxx\n",
               diff(['111', '222', '333', '444'], ['111', '222', 'xxx', '444'], {output: 'unified'}))
  assert_equal([{from_idx: 2, from_count: 1, to_idx: 2, to_count: 1}],
               diff(['111', '222', '333', '444'], ['111', '222', 'xxx', '444'], {output: 'indices'}))

  # new strings are added to an empty List
  assert_equal("@@ -0,0 +1,2 @@\n+abc\n+def\n",
               diff([], ['abc', 'def'], {output: 'unified'}))
  assert_equal([{from_idx: 0, from_count: 0, to_idx: 0, to_count: 2}],
               diff([], ['abc', 'def'], {output: 'indices'}))

  # all the strings are removed from a List
  assert_equal("@@ -1,2 +0,0 @@\n-abc\n-def\n",
               diff(['abc', 'def'], [], {output: 'unified'}))
  assert_equal([{from_idx: 0, from_count: 2, to_idx: 0, to_count: 0}],
               diff(['abc', 'def'], [], {output: 'indices'}))

  # First character is added/removed/different
  assert_equal("@@ -1 +1 @@\n-abc\n+bc\n",
               diff(['abc'], ['bc'], {output: 'unified'}))
  assert_equal([{from_idx: 0, from_count: 1, to_idx: 0, to_count: 1}],
               diff(['abc'], ['bc'], {output: 'indices'}))
  assert_equal("@@ -1 +1 @@\n-bc\n+abc\n",
               diff(['bc'], ['abc'], {output: 'unified'}))
  assert_equal([{from_idx: 0, from_count: 1, to_idx: 0, to_count: 1}],
               diff(['bc'], ['abc'], {output: 'indices'}))
  assert_equal("@@ -1 +1 @@\n-abc\n+xbc\n",
               diff(['abc'], ['xbc'], {output: 'unified'}))
  assert_equal([{from_idx: 0, from_count: 1, to_idx: 0, to_count: 1}],
               diff(['abc'], ['xbc'], {output: 'indices'}))

  # Last character is added/removed/different
  assert_equal("@@ -1 +1 @@\n-abc\n+abcd\n",
               diff(['abc'], ['abcd'], {output: 'unified'}))
  assert_equal([{from_idx: 0, from_count: 1, to_idx: 0, to_count: 1}],
               diff(['abc'], ['abcd'], {output: 'indices'}))
  assert_equal("@@ -1 +1 @@\n-abcd\n+abc\n",
               diff(['abcd'], ['abc'], {output: 'unified'}))
  assert_equal([{from_idx: 0, from_count: 1, to_idx: 0, to_count: 1}],
               diff(['abcd'], ['abc'], {output: 'indices'}))
  var diff_unified: string = diff(['abc'], ['abx'], {output: 'unified'})
  assert_equal("@@ -1 +1 @@\n-abc\n+abx\n", diff_unified)
  var diff_indices: list<dict<number>> =
    diff(['abc'], ['abx'], {output: 'indices'})
  assert_equal([{from_idx: 0, from_count: 1, to_idx: 0, to_count: 1}],
               diff_indices)

  # partial string modification at the start and at the end.
  var fromlist =<< trim END
    one two
    three four
    five six
  END
  var tolist =<< trim END
    one
    six
  END
  assert_equal("@@ -1,3 +1,2 @@\n-one two\n-three four\n-five six\n+one\n+six\n", diff(fromlist, tolist, {output: 'unified'}))
  assert_equal([{from_idx: 0, from_count: 3, to_idx: 0, to_count: 2}],
               diff(fromlist, tolist, {output: 'indices'}))

  # non-contiguous modifications
  fromlist =<< trim END
    one two
    three four
    five abc six
  END
  tolist =<< trim END
    one abc two
    three four
    five six
  END
  assert_equal("@@ -1 +1 @@\n-one two\n+one abc two\n@@ -3 +3 @@\n-five abc six\n+five six\n",
               diff(fromlist, tolist, {output: 'unified'}))
  assert_equal([{'from_count': 1, 'to_idx': 0, 'to_count': 1, 'from_idx': 0},
                {'from_count': 1, 'to_idx': 2, 'to_count': 1, 'from_idx': 2}],
               diff(fromlist, tolist, {output: 'indices'}))

  # add/remove blank lines
  assert_equal("@@ -2,2 +1,0 @@\n-\n-\n",
               diff(['one', '', '', 'two'], ['one', 'two'], {output: 'unified'}))
  assert_equal([{from_idx: 1, from_count: 2, to_idx: 1, to_count: 0}],
               diff(['one', '', '', 'two'], ['one', 'two'], {output: 'indices'}))
  assert_equal("@@ -1,0 +2,2 @@\n+\n+\n",
               diff(['one', 'two'], ['one', '', '', 'two'], {output: 'unified'}))
  assert_equal([{'from_idx': 1, 'from_count': 0, 'to_idx': 1, 'to_count': 2}],
               diff(['one', 'two'], ['one', '', '', 'two'], {output: 'indices'}))

  # diff ignoring case
  assert_equal('', diff(['abc', 'def'], ['ABC', 'DEF'], {icase: true, output: 'unified'}))
  assert_equal([], diff(['abc', 'def'], ['ABC', 'DEF'], {icase: true, output: 'indices'}))

  # diff ignoring all whitespace changes except leading whitespace changes
  assert_equal('', diff(['abc def'], ['abc  def '], {iwhite: true}))
  assert_equal("@@ -1 +1 @@\n- abc\n+  xxx\n", diff([' abc'], ['  xxx'], {iwhite: v:true}))
  assert_equal("@@ -1 +1 @@\n- abc\n+  xxx\n", diff([' abc'], ['  xxx'], {iwhite: v:false}))
  assert_equal("@@ -1 +1 @@\n-abc \n+xxx  \n", diff(['abc '], ['xxx  '], {iwhite: v:true}))
  assert_equal("@@ -1 +1 @@\n-abc \n+xxx  \n", diff(['abc '], ['xxx  '], {iwhite: v:false}))

  # diff ignoring all whitespace changes
  assert_equal('', diff(['abc def'], [' abc  def '], {iwhiteall: true}))
  assert_equal("@@ -1 +1 @@\n- abc \n+  xxx  \n", diff([' abc '], ['  xxx  '], {iwhiteall: v:true}))
  assert_equal("@@ -1 +1 @@\n- abc \n+  xxx  \n", diff([' abc '], ['  xxx  '], {iwhiteall: v:false}))

  # diff ignoring trailing whitespace changes
  assert_equal('', diff(['abc'], ['abc  '], {iwhiteeol: true}))

  # diff ignoring blank lines
  assert_equal('', diff(['one', '', '', 'two'], ['one', 'two'], {iblank: true}))
  assert_equal('', diff(['one', 'two'], ['one', '', '', 'two'], {iblank: true}))

  # same string
  assert_equal('', diff(['abc', 'def', 'ghi'], ['abc', 'def', 'ghi']))
  assert_equal('', diff([''], ['']))
  assert_equal('', diff([], []))

  # different xdiff algorithms
  for algo in ['myers', 'minimal', 'patience', 'histogram']
    assert_equal("@@ -1 +1 @@\n- abc \n+  xxx  \n",
      diff([' abc '], ['  xxx  '], {algorithm: algo, output: 'unified'}))
    assert_equal([{from_idx: 0, from_count: 1, to_idx: 0, to_count: 1}],
      diff([' abc '], ['  xxx  '], {algorithm: algo, output: 'indices'}))
  endfor
  assert_equal("@@ -1 +1 @@\n- abc \n+  xxx  \n",
    diff([' abc '], ['  xxx  '], {indent-heuristic: true, output: 'unified'}))
  assert_equal([{from_idx: 0, from_count: 1, to_idx: 0, to_count: 1}],
    diff([' abc '], ['  xxx  '], {indent-heuristic: true, output: 'indices'}))

  # identical strings
  assert_equal('', diff(['111', '222'], ['111', '222'], {output: 'unified'}))
  assert_equal([], diff(['111', '222'], ['111', '222'], {output: 'indices'}))
  assert_equal('', diff([], [], {output: 'unified'}))
  assert_equal([], diff([], [], {output: 'indices'}))

  # If 'diffexpr' is set, it should not be used for diff()
  def MyDiffExpr()
  enddef
  var save_diffexpr = &diffexpr
  :set diffexpr=MyDiffExpr()
  assert_equal("@@ -1 +1 @@\n-abc\n+\n",
               diff(['abc'], [''], {output: 'unified'}))
  assert_equal([{'from_idx': 0, 'from_count': 1, 'to_idx': 0, 'to_count': 1}],
               diff(['abc'], [''], {output: 'indices'}))
  assert_equal('MyDiffExpr()', &diffexpr)
  &diffexpr = save_diffexpr

  # try different values for unified diff 'context'
  assert_equal("@@ -0,0 +1 @@\n+x\n",
               diff(['a', 'b', 'c'], ['x', 'a', 'b', 'c']))
  assert_equal("@@ -0,0 +1 @@\n+x\n",
               diff(['a', 'b', 'c'], ['x', 'a', 'b', 'c'], {context: 0}))
  assert_equal("@@ -1 +1,2 @@\n+x\n a\n",
               diff(['a', 'b', 'c'], ['x', 'a', 'b', 'c'], {context: 1}))
  assert_equal("@@ -1,2 +1,3 @@\n+x\n a\n b\n",
               diff(['a', 'b', 'c'], ['x', 'a', 'b', 'c'], {context: 2}))
  assert_equal("@@ -1,3 +1,4 @@\n+x\n a\n b\n c\n",
               diff(['a', 'b', 'c'], ['x', 'a', 'b', 'c'], {context: 3}))
  assert_equal("@@ -1,3 +1,4 @@\n+x\n a\n b\n c\n",
               diff(['a', 'b', 'c'], ['x', 'a', 'b', 'c'], {context: 4}))
  assert_equal("@@ -0,0 +1 @@\n+x\n",
               diff(['a', 'b', 'c'], ['x', 'a', 'b', 'c'], {context: -1}))

  # Error cases
  assert_fails('call diff({}, ["a"])', 'E1211:')
  assert_fails('call diff(["a"], {})', 'E1211:')
  assert_fails('call diff(["a"], ["a"], [])', 'E1206:')
  assert_fails('call diff(["a"], ["a"], {output: "xyz"})', 'E106: Unsupported diff output format: xyz')
  assert_fails('call diff(["a"], ["a"], {context: []})', 'E745: Using a List as a Number')
enddef

" Test for using the diff() function with 'diffexpr'
func Test_diffexpr_with_diff_func()
  CheckScreendump

  let lines =<< trim END
    def DiffFuncExpr()
      var in: list<string> = readfile(v:fname_in)
      var new: list<string> = readfile(v:fname_new)
      var out: string = diff(in, new)
      writefile(split(out, "\n"), v:fname_out)
    enddef
    set diffexpr=DiffFuncExpr()

    edit Xdifffunc1.txt
    diffthis
    vert split Xdifffunc2.txt
    diffthis
  END
  call writefile(lines, 'XsetupDiffFunc.vim', 'D')

  call writefile(['zero', 'one', 'two', 'three'], 'Xdifffunc1.txt', 'D')
  call writefile(['one', 'twox', 'three', 'four'], 'Xdifffunc2.txt', 'D')

  let buf = RunVimInTerminal('-S XsetupDiffFunc.vim', {'rows': 12})
  call VerifyScreenDump(buf, 'Test_difffunc_diffexpr_1', {})
  call StopVimInTerminal(buf)
endfunc

func Test_diff_toggle_wrap_skipcol_leftcol()
  61vnew
  call setline(1, 'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.')
  30vnew
  call setline(1, 'ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.')
  let win1 = win_getid()
  setlocal smoothscroll
  exe "normal! $\<C-E>"
  wincmd l
  let win2 = win_getid()
  setlocal smoothscroll
  exe "normal! $\<C-E>"
  call assert_equal([
        \ '<<<sadipscing elitr, sed diam |<<<tetur sadipscing elitr, sed|',
        \ 'nonumy eirmod tempor invidunt | diam nonumy eirmod tempor inv|',
        \ 'ut labore et dolore magna aliq|idunt ut labore et dolore magn|',
        \ 'uyam erat, sed diam voluptua. |a aliquyam erat, sed diam volu|',
        \ '~                             |ptua.                         |',
        \ ], ScreenLines([1, 5], 62))
  call assert_equal({'col': 29, 'row': 4, 'endcol': 29, 'curscol': 29},
        \ screenpos(win1, line('.', win1), col('.', win1)))
  call assert_equal({'col': 36, 'row': 5, 'endcol': 36, 'curscol': 36},
        \ screenpos(win2, line('.', win2), col('.', win2)))

  wincmd h
  diffthis
  wincmd l
  diffthis
  normal! 0
  call assert_equal([
        \ '  ipsum dolor sit amet, conset|  Lorem ipsum dolor sit amet, |',
        \ '~                             |~                             |',
        \ ], ScreenLines([1, 2], 62))
  call assert_equal({'col': 3, 'row': 1, 'endcol': 3, 'curscol': 3},
        \ screenpos(win1, line('.', win1), col('.', win1)))
  call assert_equal({'col': 34, 'row': 1, 'endcol': 34, 'curscol': 34},
        \ screenpos(win2, line('.', win2), col('.', win2)))

  normal! $
  call assert_equal([
        \ '  voluptua.                   |   diam voluptua.             |',
        \ '~                             |~                             |',
        \ ], ScreenLines([1, 2], 62))
  call assert_equal({'col': 11, 'row': 1, 'endcol': 11, 'curscol': 11},
        \ screenpos(win1, line('.', win1), col('.', win1)))
  call assert_equal({'col': 48, 'row': 1, 'endcol': 48, 'curscol': 48},
        \ screenpos(win2, line('.', win2), col('.', win2)))

  diffoff!
  call assert_equal([
        \ 'ipsum dolor sit amet, consetet|Lorem ipsum dolor sit amet, co|',
        \ 'ur sadipscing elitr, sed diam |nsetetur sadipscing elitr, sed|',
        \ 'nonumy eirmod tempor invidunt | diam nonumy eirmod tempor inv|',
        \ 'ut labore et dolore magna aliq|idunt ut labore et dolore magn|',
        \ 'uyam erat, sed diam voluptua. |a aliquyam erat, sed diam volu|',
        \ '~                             |ptua.                         |',
        \ ], ScreenLines([1, 6], 62))
  call assert_equal({'col': 29, 'row': 5, 'endcol': 29, 'curscol': 29},
        \ screenpos(win1, line('.', win1), col('.', win1)))
  call assert_equal({'col': 36, 'row': 6, 'endcol': 36, 'curscol': 36},
        \ screenpos(win2, line('.', win2), col('.', win2)))

  bwipe!
  bwipe!
endfunc

" Ctrl-D reveals filler lines below the last line in the buffer.
func Test_diff_eob_halfpage()
  new
  call setline(1, ['']->repeat(10) + ['a'])
  diffthis
  new
  call setline(1, ['']->repeat(3) + ['a', 'b'])
  diffthis
  resize 5
  wincmd j
  resize 5
  norm G
  call assert_equal(7, line('w0'))
  exe "norm! \<C-D>"
  call assert_equal(8, line('w0'))

  %bwipe!
endfunc

func Test_diff_overlapped_diff_blocks_will_be_merged()
  CheckScreendump

  let lines =<< trim END
    func DiffExprStub()
      let txt_in = readfile(v:fname_in)
      let txt_new = readfile(v:fname_new)
      if txt_in == ["line1"] && txt_new == ["line2"]
        call writefile(["1c1"], v:fname_out)
      elseif txt_in == readfile("Xdiin1") && txt_new == readfile("Xdinew1")
        call writefile(readfile("Xdiout1"), v:fname_out)
      elseif txt_in == readfile("Xdiin2") && txt_new == readfile("Xdinew2")
        call writefile(readfile("Xdiout2"), v:fname_out)
      endif
    endfunc
  END
  call writefile(lines, 'XdiffSetup', 'D')

  call WriteDiffFiles(0, [], [])
  let buf = RunVimInTerminal('-d -S XdiffSetup Xdifile1 Xdifile2', {})
  call term_sendkeys(buf, ":set autoread\<CR>\<c-w>w:set autoread\<CR>\<c-w>w")

  call WriteDiffFiles(buf, ["a", "b"], ["x", "x"])
  call writefile(["a", "b"], "Xdiin1")
  call writefile(["x", "x"], "Xdinew1")
  call writefile(["1c1", "2c2"], "Xdiout1")
  call term_sendkeys(buf, ":set diffexpr=DiffExprStub()\<CR>:")
  call VerifyBoth(buf, "Test_diff_overlapped_2.01", "")
  call term_sendkeys(buf, ":set diffexpr&\<CR>:")

  call WriteDiffFiles(buf, ["a", "b", "c"], ["x", "c"])
  call writefile(["a", "b", "c"], "Xdiin1")
  call writefile(["x", "c"], "Xdinew1")
  call writefile(["1c1", "2d1"], "Xdiout1")
  call term_sendkeys(buf, ":set diffexpr=DiffExprStub()\<CR>:")
  call VerifyBoth(buf, "Test_diff_overlapped_2.02", "")
  call term_sendkeys(buf, ":set diffexpr&\<CR>:")

  call WriteDiffFiles(buf, ["a", "c"], ["x", "x", "c"])
  call writefile(["a", "c"], "Xdiin1")
  call writefile(["x", "x", "c"], "Xdinew1")
  call writefile(["1c1", "1a2"], "Xdiout1")
  call term_sendkeys(buf, ":set diffexpr=DiffExprStub()\<CR>:")
  call VerifyBoth(buf, "Test_diff_overlapped_2.03", "")
  call term_sendkeys(buf, ":set diffexpr&\<CR>:")

  call StopVimInTerminal(buf)
  wincmd c

  call WriteDiffFiles3(0, [], [], [])
  let buf = RunVimInTerminal('-d -S XdiffSetup Xdifile1 Xdifile2 Xdifile3', {})
  call term_sendkeys(buf, ":set autoread\<CR>\<c-w>w:set autoread\<CR>\<c-w>w:set autoread\<CR>\<c-w>w")

  call WriteDiffFiles3(buf, ["a", "b", "c"], ["a", "x", "c"], ["y", "b", "c"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.01", "")

  call WriteDiffFiles3(buf, ["a", "b", "c"], ["a", "x", "c"], ["a", "y", "c"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.02", "")

  call WriteDiffFiles3(buf, ["a", "b", "c"], ["a", "x", "c"], ["a", "b", "y"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.03", "")

  call WriteDiffFiles3(buf, ["a", "b", "c"], ["a", "x", "c"], ["y", "y", "c"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.04", "")

  call WriteDiffFiles3(buf, ["a", "b", "c"], ["a", "x", "c"], ["a", "y", "y"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.05", "")

  call WriteDiffFiles3(buf, ["a", "b", "c"], ["a", "x", "c"], ["y", "y", "y"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.06", "")

  call WriteDiffFiles3(buf, ["a", "b", "c"], ["a", "x", "x"], ["y", "y", "c"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.07", "")

  call WriteDiffFiles3(buf, ["a", "b", "c"], ["x", "x", "c"], ["a", "y", "y"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.08", "")

  call WriteDiffFiles3(buf, ["a", "b", "c", "d", "e"], ["a", "x", "c", "x", "e"], ["y", "y", "y", "d", "e"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.09", "")

  call WriteDiffFiles3(buf, ["a", "b", "c", "d", "e"], ["a", "x", "c", "x", "e"], ["y", "y", "y", "y", "e"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.10", "")

  call WriteDiffFiles3(buf, ["a", "b", "c", "d", "e"], ["a", "x", "c", "x", "e"], ["y", "y", "y", "y", "y"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.11", "")

  call WriteDiffFiles3(buf, ["a", "b", "c", "d", "e"], ["a", "x", "c", "x", "e"], ["a", "y", "y", "d", "e"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.12", "")

  call WriteDiffFiles3(buf, ["a", "b", "c", "d", "e"], ["a", "x", "c", "x", "e"], ["a", "y", "y", "y", "e"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.13", "")

  call WriteDiffFiles3(buf, ["a", "b", "c", "d", "e"], ["a", "x", "c", "x", "e"], ["a", "y", "y", "y", "y"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.14", "")

  call WriteDiffFiles3(buf, ["a", "b", "c", "d", "e"], ["a", "x", "c", "x", "e"], ["a", "b", "y", "d", "e"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.15", "")

  call WriteDiffFiles3(buf, ["a", "b", "c", "d", "e"], ["a", "x", "c", "x", "e"], ["a", "b", "y", "y", "e"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.16", "")

  call WriteDiffFiles3(buf, ["a", "b", "c", "d", "e"], ["a", "x", "c", "x", "e"], ["a", "b", "y", "y", "y"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.17", "")

  call WriteDiffFiles3(buf, ["a", "b"], ["x", "b"], ["y", "y"])
  call writefile(["a", "b"], "Xdiin1")
  call writefile(["x", "b"], "Xdinew1")
  call writefile(["1c1"], "Xdiout1")
  call writefile(["a", "b"], "Xdiin2")
  call writefile(["y", "y"], "Xdinew2")
  call writefile(["1c1", "2c2"], "Xdiout2")
  call term_sendkeys(buf, ":set diffexpr=DiffExprStub()\<CR>:")
  call VerifyInternal(buf, "Test_diff_overlapped_3.18", "")
  call term_sendkeys(buf, ":set diffexpr&\<CR>:")

  call WriteDiffFiles3(buf, ["a", "b", "c", "d"], ["x", "b", "x", "d"], ["y", "y", "c", "d"])
  call writefile(["a", "b", "c", "d"], "Xdiin1")
  call writefile(["x", "b", "x", "d"], "Xdinew1")
  call writefile(["1c1", "3c3"], "Xdiout1")
  call writefile(["a", "b", "c", "d"], "Xdiin2")
  call writefile(["y", "y", "c", "d"], "Xdinew2")
  call writefile(["1c1", "2c2"], "Xdiout2")
  call term_sendkeys(buf, ":set diffexpr=DiffExprStub()\<CR>:")
  call VerifyInternal(buf, "Test_diff_overlapped_3.19", "")
  call term_sendkeys(buf, ":set diffexpr&\<CR>:")

  call WriteDiffFiles3(buf, ["a", "b", "c", "d"], ["x", "b", "x", "d"], ["y", "y", "y", "d"])
  call writefile(["a", "b", "c", "d"], "Xdiin1")
  call writefile(["x", "b", "x", "d"], "Xdinew1")
  call writefile(["1c1", "3c3"], "Xdiout1")
  call writefile(["a", "b", "c", "d"], "Xdiin2")
  call writefile(["y", "y", "y", "d"], "Xdinew2")
  call writefile(["1c1", "2,3c2,3"], "Xdiout2")
  call term_sendkeys(buf, ":set diffexpr=DiffExprStub()\<CR>:")
  call VerifyInternal(buf, "Test_diff_overlapped_3.20", "")
  call term_sendkeys(buf, ":set diffexpr&\<CR>:")

  call WriteDiffFiles3(buf, ["a", "b", "c", "d"], ["x", "b", "x", "d"], ["y", "y", "y", "y"])
  call writefile(["a", "b", "c", "d"], "Xdiin1")
  call writefile(["x", "b", "x", "d"], "Xdinew1")
  call writefile(["1c1", "3c3"], "Xdiout1")
  call writefile(["a", "b", "c", "d"], "Xdiin2")
  call writefile(["y", "y", "y", "y"], "Xdinew2")
  call writefile(["1c1", "2,4c2,4"], "Xdiout2")
  call term_sendkeys(buf, ":set diffexpr=DiffExprStub()\<CR>:")
  call VerifyInternal(buf, "Test_diff_overlapped_3.21", "")
  call term_sendkeys(buf, ":set diffexpr&\<CR>:")

  call WriteDiffFiles3(buf, ["a", "b", "c"], ["a", "x", "c"], ["b", "c"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.22", "")

  call WriteDiffFiles3(buf, ["a", "b", "c"], ["a", "x", "c"], ["c"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.23", "")

  call WriteDiffFiles3(buf, ["a", "b", "c"], ["a", "x", "c"], [])
  call VerifyBoth(buf, "Test_diff_overlapped_3.24", "")

  call WriteDiffFiles3(buf, ["a", "b", "c"], ["a", "x", "c"], ["a", "c"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.25", "")

  call WriteDiffFiles3(buf, ["a", "b", "c"], ["a", "x", "c"], ["a"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.26", "")

  call WriteDiffFiles3(buf, ["a", "b", "c"], ["a", "x", "c"], ["b"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.27", "")

  call WriteDiffFiles3(buf, ["a", "b", "c", "d", "e"], ["a", "x", "c", "x", "e"], ["d", "e"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.28", "")

  call WriteDiffFiles3(buf, ["a", "b", "c", "d", "e"], ["a", "x", "c", "x", "e"], ["e"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.29", "")

  call WriteDiffFiles3(buf, ["a", "b", "c", "d", "e"], ["a", "x", "c", "x", "e"], ["a", "d", "e"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.30", "")

  call WriteDiffFiles3(buf, ["a", "b", "c", "d", "e"], ["a", "x", "c", "x", "e"], ["a", "e"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.31", "")

  call WriteDiffFiles3(buf, ["a", "b", "c", "d", "e"], ["a", "x", "c", "x", "e"], ["a"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.32", "")

  call WriteDiffFiles3(buf, ["a", "b", "c", "d", "e"], ["a", "x", "c", "x", "e"], ["a", "b", "d", "e"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.33", "")

  call WriteDiffFiles3(buf, ["a", "b", "c", "d", "e"], ["a", "x", "c", "x", "e"], ["a", "b", "e"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.34", "")

  call WriteDiffFiles3(buf, ["a", "b", "c", "d", "e"], ["a", "x", "c", "x", "e"], ["a", "b"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.35", "")

  call WriteDiffFiles3(buf, ["a", "b", "c"], ["a", "x", "c"], ["a", "y", "b", "c"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.36", "")

  call WriteDiffFiles3(buf, ["a", "b", "c"], ["a", "x", "c"], ["a", "b", "y", "c"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.37", "")

  call WriteDiffFiles3(buf, ["a", "b", "c"], ["d", "e"], ["b", "f"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.38", "")

  call WriteDiffFiles3(buf, ["a", "b", "c"], ["d", "e"], ["b"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.39", "")

  " File 3 overlaps twice, 2nd overlap completely within the existing block.
  call WriteDiffFiles3(buf, ["foo", "a", "b", "c", "bar"], ["foo", "w", "x", "y", "z", "bar"], ["foo", "1", "a", "b", "2", "bar"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.40", "")

  " File 3 overlaps twice, 2nd overlap extends beyond existing block on new
  " side. Make sure we don't over-extend the range and hit 'bar'.
  call WriteDiffFiles3(buf, ["foo", "a", "b", "c", "d", "bar"], ["foo", "w", "x", "y", "z", "u", "bar"], ["foo", "1", "a", "b", "2", "d", "bar"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.41", "")

  " Chained overlaps. File 3's 2nd overlap spans two diff blocks and is longer
  " than the 2nd one.
  call WriteDiffFiles3(buf, ["foo", "a", "b", "c", "d", "e", "f", "bar"], ["foo", "w", "x", "y", "z", "e", "u", "bar"], ["foo", "1", "b", "2", "3", "d", "4", "f", "bar"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.42", "")

  " File 3 has 2 overlaps. An add and a delete. First overlap's expansion hits
  " the 2nd one. Make sure we adjust the diff block to have fewer lines.
  call WriteDiffFiles3(buf, ["foo", "a", "b", "bar"], ["foo", "x", "y", "bar"], ["foo", "1", "a", "bar"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.43", "")

  " File 3 has 2 overlaps. An add and another add. First overlap's expansion hits
  " the 2nd one. Make sure we adjust the diff block to have more lines.
  call WriteDiffFiles3(buf, ["foo", "a", "b", "c", "d", "bar"], ["foo", "w", "x", "y", "z", "u", "bar"], ["foo", "1", "a", "b", "3", "4", "d", "bar"])
  call VerifyBoth(buf, "Test_diff_overlapped_3.44", "")

  call StopVimInTerminal(buf)
endfunc

" switching windows in diff mode caused an unnecessary scroll
func Test_diff_topline_noscroll()
  CheckScreendump

  let content =<< trim END
    call setline(1, range(1,60))
    vnew
    call setline(1, range(1,10) + range(50,60))
    windo diffthis
    norm! G
    exe "norm! 30\<C-y>"
  END
  call writefile(content, 'Xcontent', 'D')
  let buf = RunVimInTerminal('-S Xcontent', {'rows': 20})
  call VerifyScreenDump(buf, 'Test_diff_topline_1', {})
  call term_sendkeys(buf, ":echo line('w0', 1001)\<cr>")
  call term_wait(buf)
  call VerifyScreenDump(buf, 'Test_diff_topline_2', {})
  call term_sendkeys(buf, "\<C-W>p")
  call term_wait(buf)
  call VerifyScreenDump(buf, 'Test_diff_topline_3', {})
  call term_sendkeys(buf, "\<C-W>p")
  call term_wait(buf)
  call VerifyScreenDump(buf, 'Test_diff_topline_4', {})
  call StopVimInTerminal(buf)
endfunc

" Test inline highlighting which shows what's different within each diff block
func Test_diff_inline()
  CheckScreendump

  call WriteDiffFiles(0, [], [])
  let buf = RunVimInTerminal('-d Xdifile1 Xdifile2', {})
  call term_sendkeys(buf, ":set autoread\<CR>\<c-w>w:set autoread\<CR>\<c-w>w")

  call WriteDiffFiles(buf, ["abcdef ghi jk n", "x", "y"], ["aBcef gHi lm n", "y", "z"])
  call VerifyInternal(buf, "Test_diff_inline_01", "")
  call VerifyInternal(buf, "Test_diff_inline_02", " diffopt+=inline:none")

  " inline:simple is the same as default
  call VerifyInternal(buf, "Test_diff_inline_01", " diffopt+=inline:simple")

  call VerifyInternal(buf, "Test_diff_inline_03", " diffopt+=inline:char")
  call VerifyInternal(buf, "Test_diff_inline_04", " diffopt+=inline:word")

  " multiple inline values will the last one
  call VerifyInternal(buf, "Test_diff_inline_01", " diffopt+=inline:none,inline:char,inline:simple")
  call VerifyInternal(buf, "Test_diff_inline_02", " diffopt+=inline:simple,inline:word,inline:none")
  call VerifyInternal(buf, "Test_diff_inline_03", " diffopt+=inline:simple,inline:word,inline:char")

  " DiffTextAdd highlight
  call term_sendkeys(buf, ":hi DiffTextAdd ctermbg=blue\<CR>")
  call VerifyInternal(buf, "Test_diff_inline_05", " diffopt+=inline:char")

  " Live update in insert mode
  call term_sendkeys(buf, "\<Esc>isometext")
  call VerifyScreenDump(buf, "Test_diff_inline_06", {})
  call term_sendkeys(buf, "\<Esc>u")

  " icase simple scenarios
  call VerifyInternal(buf, "Test_diff_inline_07", " diffopt+=inline:simple,icase")
  call VerifyInternal(buf, "Test_diff_inline_08", " diffopt+=inline:char,icase")
  call VerifyInternal(buf, "Test_diff_inline_09", " diffopt+=inline:word,icase")

  " diff algorithms should affect highlight
  call WriteDiffFiles(buf, ["apples and oranges"], ["oranges and apples"])
  call VerifyInternal(buf, "Test_diff_inline_10", " diffopt+=inline:char")
  call VerifyInternal(buf, "Test_diff_inline_11", " diffopt+=inline:char,algorithm:patience")

  " icase: composing chars and Unicode fold case edge cases
  call WriteDiffFiles(buf,
        \ ["1 - sigma in 6σ and Ὀδυσσεύς", "1 - angstrom in åå", "1 - composing: ii⃗I⃗"],
        \ ["2 - Sigma in 6Σ and ὈΔΥΣΣΕΎΣ", "2 - Angstrom in ÅÅ", "2 - Composing: i⃗I⃗I⃗"])
  call VerifyInternal(buf, "Test_diff_inline_12", " diffopt+=inline:char")
  call VerifyInternal(buf, "Test_diff_inline_13", " diffopt+=inline:char,icase")

  " wide chars
  call WriteDiffFiles(buf, ["abc😅xde一", "f🚀g"], ["abcy😢de", "二f🚀g"])
  call VerifyInternal(buf, "Test_diff_inline_14", " diffopt+=inline:char,icase")

  " NUL char (\n below is internally substituted as NUL)
  call WriteDiffFiles(buf, ["1\n34\n5\n6"], ["1234\n5", "6"])
  call VerifyInternal(buf, "Test_diff_inline_15", " diffopt+=inline:char")

  " word diff: always use first buffer's iskeyword and ignore others' for consistency
  call WriteDiffFiles(buf, ["foo+bar test"], ["foo+baz test"])
  call VerifyInternal(buf, "Test_diff_inline_word_01", " diffopt+=inline:word")

  call term_sendkeys(buf, ":set iskeyword+=+\<CR>:diffupdate\<CR>")
  call VerifyInternal(buf, "Test_diff_inline_word_02", " diffopt+=inline:word")

  call term_sendkeys(buf, ":set iskeyword&\<CR>:wincmd w\<CR>")
  call term_sendkeys(buf, ":set iskeyword+=+\<CR>:wincmd w\<CR>:diffupdate\<CR>")
  " Use the previous screen dump as 2nd buffer's iskeyword does not matter
  call VerifyInternal(buf, "Test_diff_inline_word_01", " diffopt+=inline:word")

  call term_sendkeys(buf, ":windo set iskeyword&\<CR>:1wincmd w\<CR>")

  " word diff: test handling of multi-byte characters. Only alphanumeric chars
  " (e.g. Greek alphabet, but not CJK/emoji) count as words.
  call WriteDiffFiles(buf, ["🚀⛵️一二三ひらがなΔέλτα Δelta foobar"], ["🚀🛸一二四ひらなδέλτα δelta foobar"])
  call VerifyInternal(buf, "Test_diff_inline_word_03", " diffopt+=inline:word")

  " char diff: should slide highlight to whitespace boundary if possible for
  " better readability (by using forced indent-heuristics). A wrong result
  " would be if the highlight is "Bar, prefix". It should be "prefixBar, "
  " instead.
  call WriteDiffFiles(buf, ["prefixFoo, prefixEnd"], ["prefixFoo, prefixBar, prefixEnd"])
  call VerifyInternal(buf, "Test_diff_inline_char_01", " diffopt+=inline:char")

  " char diff: small gaps between inline diff blocks will be merged during refine step
  " - first segment: test that we iteratively merge small gaps after we merged
  "   adjacent blocks, but only with limited number (set to 4) of iterations.
  " - second and third segments: show that we need a large enough adjacent block to
  "   trigger a merge.
  " - fourth segment: small gaps are not merged when adjacent large block is
  "   on a different line.
  call WriteDiffFiles(buf,
        \ ["abcdefghijklmno", "anchor1",
        \  "abcdefghijklmno", "anchor2",
        \  "abcdefghijklmno", "anchor3",
        \  "test", "multiline"],
        \ ["a?c?e?g?i?k???o", "anchor1",
        \  "a??de?????klmno", "anchor2",
        \  "a??de??????lmno", "anchor3",
        \  "t?s?", "??????i?e"])
  call VerifyInternal(buf, "Test_diff_inline_char_02", " diffopt+=inline:char")

  " Test multi-line blocks and whitespace
  call WriteDiffFiles(buf,
        \ ["this   is   ", "sometest text foo", "baz abc def ", "one", "word another word", "additional line"],
        \ ["this is some test", "texts", "foo bar abX Yef     ", "oneword another word"])
  call VerifyInternal(buf, "Test_diff_inline_multiline_01", " diffopt+=inline:char,iwhite")
  call VerifyInternal(buf, "Test_diff_inline_multiline_02", " diffopt+=inline:word,iwhite")
  call VerifyInternal(buf, "Test_diff_inline_multiline_03", " diffopt+=inline:char,iwhiteeol")
  call VerifyInternal(buf, "Test_diff_inline_multiline_04", " diffopt+=inline:word,iwhiteeol")
  call VerifyInternal(buf, "Test_diff_inline_multiline_05", " diffopt+=inline:char,iwhiteall")
  call VerifyInternal(buf, "Test_diff_inline_multiline_06", " diffopt+=inline:word,iwhiteall")

  " newline should be highlighted too when 'list' is set
  call term_sendkeys(buf, ":windo set list\<CR>")
  call VerifyInternal(buf, "Test_diff_inline_multiline_07", " diffopt+=inline:char")
  call VerifyInternal(buf, "Test_diff_inline_multiline_08", " diffopt+=inline:char,iwhite")
  call VerifyInternal(buf, "Test_diff_inline_multiline_09", " diffopt+=inline:char,iwhiteeol")
  call VerifyInternal(buf, "Test_diff_inline_multiline_10", " diffopt+=inline:char,iwhiteall")
  call term_sendkeys(buf, ":windo set nolist\<CR>")

  call StopVimInTerminal(buf)
endfunc

func Test_diff_inline_multibuffer()
  CheckScreendump

  call WriteDiffFiles3(0, [], [], [])
  let buf = RunVimInTerminal('-d Xdifile1 Xdifile2 Xdifile3', {})
  call term_sendkeys(buf, ":windo set autoread\<CR>:1wincmd w\<CR>")
  call term_sendkeys(buf, ":hi DiffTextAdd ctermbg=blue\<CR>")

  call WriteDiffFiles3(buf,
        \ ["That is buffer1.", "anchor", "Some random text", "anchor"],
        \ ["This is buffer2.", "anchor", "Some text", "anchor", "buffer2/3"],
        \ ["This is buffer3. Last.", "anchor", "Some more", "text here.", "anchor", "only in buffer2/3", "not in buffer1"])
  call VerifyInternal(buf, "Test_diff_inline_multibuffer_01", " diffopt+=inline:char")

  " Close one of the buffers and make sure it updates correctly
  call term_sendkeys(buf, ":diffoff\<CR>")
  call VerifyInternal(buf, "Test_diff_inline_multibuffer_02", " diffopt+=inline:char")

  " Update text in the non-diff buffer and nothing should be changed
  call term_sendkeys(buf, "\<Esc>isometext")
  call VerifyScreenDump(buf, "Test_diff_inline_multibuffer_03", {})
  call term_sendkeys(buf, "\<Esc>u")

  call term_sendkeys(buf, ":diffthis\<CR>")
  call VerifyInternal(buf, "Test_diff_inline_multibuffer_01", " diffopt+=inline:char")

  " Test that removing first buffer from diff will in turn use the next
  " earliest buffer's iskeyword during word diff.
  call WriteDiffFiles3(buf,
        \ ["This+is=a-setence"],
        \ ["This+is=another-setence"],
        \ ["That+is=a-setence"])
  call term_sendkeys(buf, ":set iskeyword+=+\<CR>:2wincmd w\<CR>:set iskeyword+=-\<CR>:1wincmd w\<CR>")
  call VerifyInternal(buf, "Test_diff_inline_multibuffer_04", " diffopt+=inline:word")
  call term_sendkeys(buf, ":diffoff\<CR>")
  call VerifyInternal(buf, "Test_diff_inline_multibuffer_05", " diffopt+=inline:word")
  call term_sendkeys(buf, ":diffthis\<CR>")
  call VerifyInternal(buf, "Test_diff_inline_multibuffer_04", " diffopt+=inline:word")

  " Test multi-buffer char diff refinement, and that removing a buffer from
  " diff will update the others properly.
  call WriteDiffFiles3(buf,
        \ ["abcdefghijkYmYYY"],
        \ ["aXXdXXghijklmnop"],
        \ ["abcdefghijkYmYop"])
  call VerifyInternal(buf, "Test_diff_inline_multibuffer_06", " diffopt+=inline:char")
  call term_sendkeys(buf, ":diffoff\<CR>")
  call VerifyInternal(buf, "Test_diff_inline_multibuffer_07", " diffopt+=inline:char")
  call term_sendkeys(buf, ":diffthis\<CR>")
  call VerifyInternal(buf, "Test_diff_inline_multibuffer_06", " diffopt+=inline:char")

  call StopVimInTerminal(buf)
endfunc

" Test that when using multi-buffer diff, an empty block would be correctly
" skipped in the result, without resulting in invalid states or crashes.
func Test_diff_inline_multibuffer_empty_block()
  CheckScreendump

  call writefile(['anchor1', '1234567890abcde', 'anchor2'], 'Xdifile1')
  call writefile(['anchor1', '1234567--0abc-e', 'anchor2'], 'Xdifile2')
  call writefile(['anchor1', 'anchor2'], 'Xdifile3')
  call writefile(['anchor1', '1???????90abcd?', 'anchor2'], 'Xdifile4')

  let buf = RunVimInTerminal('-d Xdifile1 Xdifile2 Xdifile3 Xdifile4', {})
  call VerifyInternal(buf, "Test_diff_inline_multibuffer_empty_block_01", " diffopt+=inline:char")

  call StopVimInTerminal(buf)
endfunc

func Test_diffget_diffput_linematch()
  CheckScreendump
  call delete('.Xdifile1.swp')
  call delete('.Xdifile2.swp')
  call WriteDiffFiles(0, [], [])
  let buf = RunVimInTerminal('-d Xdifile1 Xdifile2', {})
  call term_sendkeys(buf, ":set autoread\<CR>\<c-w>w:set autoread\<CR>\<c-w>w")

  " enable linematch
  call term_sendkeys(buf, ":set diffopt+=linematch:30\<CR>")
  call WriteDiffFiles(buf, ['',
      \ 'common line',
      \ 'common line',
      \ '',
      \ 'ABCabc',
      \ 'ABCabc',
      \ 'ABCabc',
      \ 'ABCabc',
      \ 'common line',
      \ 'common line',
      \ 'common line',
      \ 'something' ],
      \ ['',
      \ 'common line',
      \ 'common line',
      \ '',
      \ 'DEFabc',
      \ 'xyz',
      \ 'xyz',
      \ 'xyz',
      \ 'DEFabc',
      \ 'DEFabc',
      \ 'DEFabc',
      \ 'common line',
      \ 'common line',
      \ 'DEF',
      \ 'common line',
      \ 'DEF',
      \ 'something'])
  call VerifyScreenDump(buf, 'Test_diff_get_put_linematch_1', {})

  " get from window 1 from line 5 to 9
  call term_sendkeys(buf, "1\<c-w>w")
  call term_sendkeys(buf, ":5,9diffget\<CR>")
  call VerifyScreenDump(buf, 'Test_diff_get_put_linematch_2', {})

  " undo the last diffget
  call term_sendkeys(buf, "u")

  " get from window 2 from line 5 to 10
  call term_sendkeys(buf, "2\<c-w>w")
  call term_sendkeys(buf, ":5,10diffget\<CR>")
  call VerifyScreenDump(buf, 'Test_diff_get_put_linematch_3', {})

  " undo the last diffget
  call term_sendkeys(buf, "u")

  " get all from window 2
  call term_sendkeys(buf, "2\<c-w>w")
  call term_sendkeys(buf, ":4,17diffget\<CR>")
  call VerifyScreenDump(buf, 'Test_diff_get_put_linematch_4', {})

  " undo the last diffget
  call term_sendkeys(buf, "u")

  " get all from window 1
  call term_sendkeys(buf, "1\<c-w>w")
  call term_sendkeys(buf, ":4,12diffget\<CR>")
  call VerifyScreenDump(buf, 'Test_diff_get_put_linematch_5', {})

  " undo the last diffget
  call term_sendkeys(buf, "u")

  " get from window 1 using do 1 line 5
  call term_sendkeys(buf, "1\<c-w>w")
  call term_sendkeys(buf, "5gg")
  call term_sendkeys(buf, ":diffget\<CR>")
  call VerifyScreenDump(buf, 'Test_diff_get_put_linematch_6', {})

  " undo the last diffget
  call term_sendkeys(buf, "u")

  " get from window 1 using do 2 line 6
  call term_sendkeys(buf, "1\<c-w>w")
  call term_sendkeys(buf, "6gg")
  call term_sendkeys(buf, ":diffget\<CR>")
  call VerifyScreenDump(buf, 'Test_diff_get_put_linematch_7', {})

  " undo the last diffget
  call term_sendkeys(buf, "u")

  " get from window 1 using do 2 line 7
  call term_sendkeys(buf, "1\<c-w>w")
  call term_sendkeys(buf, "7gg")
  call term_sendkeys(buf, ":diffget\<CR>")
  call VerifyScreenDump(buf, 'Test_diff_get_put_linematch_8', {})

  " undo the last diffget
  call term_sendkeys(buf, "u")

  " get from window 1 using do 2 line 11
  call term_sendkeys(buf, "1\<c-w>w")
  call term_sendkeys(buf, "11gg")
  call term_sendkeys(buf, ":diffget\<CR>")
  call VerifyScreenDump(buf, 'Test_diff_get_put_linematch_9', {})

  " undo the last diffget
  call term_sendkeys(buf, "u")

  " get from window 1 using do 2 line 12
  call term_sendkeys(buf, "1\<c-w>w")
  call term_sendkeys(buf, "12gg")
  call term_sendkeys(buf, ":diffget\<CR>")
  call VerifyScreenDump(buf, 'Test_diff_get_put_linematch_10', {})

  " undo the last diffget
  call term_sendkeys(buf, "u")

  " put from window 1 using dp 1 line 5
  call term_sendkeys(buf, "1\<c-w>w")
  call term_sendkeys(buf, "5gg")
  call term_sendkeys(buf, ":diffput\<CR>")
  call VerifyScreenDump(buf, 'Test_diff_get_put_linematch_11', {})

  " undo the last diffput
  call term_sendkeys(buf, "2\<c-w>w")
  call term_sendkeys(buf, "u")

  " put from window 1 using dp 2 line 6
  call term_sendkeys(buf, "1\<c-w>w")
  call term_sendkeys(buf, "6gg")
  call term_sendkeys(buf, ":diffput\<CR>")
  call VerifyScreenDump(buf, 'Test_diff_get_put_linematch_12', {})

  " undo the last diffput
  call term_sendkeys(buf, "2\<c-w>w")
  call term_sendkeys(buf, "u")

  " put from window 1 using dp 2 line 7
  call term_sendkeys(buf, "1\<c-w>w")
  call term_sendkeys(buf, "7gg")
  call term_sendkeys(buf, ":diffput\<CR>")
  call VerifyScreenDump(buf, 'Test_diff_get_put_linematch_13', {})

  " undo the last diffput
  call term_sendkeys(buf, "2\<c-w>w")
  call term_sendkeys(buf, "u")

  " put from window 1 using dp 2 line 11
  call term_sendkeys(buf, "1\<c-w>w")
  call term_sendkeys(buf, "11gg")
  call term_sendkeys(buf, ":diffput\<CR>")
  call VerifyScreenDump(buf, 'Test_diff_get_put_linematch_14', {})

  " undo the last diffput
  call term_sendkeys(buf, "2\<c-w>w")
  call term_sendkeys(buf, "u")

  " put from window 1 using dp 2 line 12
  call term_sendkeys(buf, "1\<c-w>w")
  call term_sendkeys(buf, "12gg")
  call term_sendkeys(buf, ":diffput\<CR>")
  call VerifyScreenDump(buf, 'Test_diff_get_put_linematch_15', {})

  " undo the last diffput
  call term_sendkeys(buf, "2\<c-w>w")
  call term_sendkeys(buf, "u")

  " put from window 2 using dp line 6
  call term_sendkeys(buf, "2\<c-w>w")
  call term_sendkeys(buf, "6gg")
  call term_sendkeys(buf, ":diffput\<CR>")
  call VerifyScreenDump(buf, 'Test_diff_get_put_linematch_16', {})

  " undo the last diffput
  call term_sendkeys(buf, "1\<c-w>w")
  call term_sendkeys(buf, "u")

  " put from window 2 using dp line 8
  call term_sendkeys(buf, "2\<c-w>w")
  call term_sendkeys(buf, "8gg")
  call term_sendkeys(buf, ":diffput\<CR>")
  call VerifyScreenDump(buf, 'Test_diff_get_put_linematch_17', {})

  " undo the last diffput
  call term_sendkeys(buf, "1\<c-w>w")
  call term_sendkeys(buf, "u")

  " put from window 2 using dp line 9
  call term_sendkeys(buf, "2\<c-w>w")
  call term_sendkeys(buf, "9gg")
  call term_sendkeys(buf, ":diffput\<CR>")
  call VerifyScreenDump(buf, 'Test_diff_get_put_linematch_18', {})

  " undo the last diffput
  call term_sendkeys(buf, "1\<c-w>w")
  call term_sendkeys(buf, "u")

  " put from window 2 using dp line 17
  call term_sendkeys(buf, "2\<c-w>w")
  call term_sendkeys(buf, "17gg")
  call term_sendkeys(buf, ":diffput\<CR>")
  call VerifyScreenDump(buf, 'Test_diff_get_put_linematch_19', {})
  " clean up
  call StopVimInTerminal(buf)
endfunc

func Test_linematch_diff()
  CheckScreendump
  call delete('.Xdifile1.swp')
  call delete('.Xdifile2.swp')
  call WriteDiffFiles(0, [], [])
  let buf = RunVimInTerminal('-d Xdifile1 Xdifile2', {})
  call term_sendkeys(buf, ":set autoread\<CR>\<c-w>w:set autoread\<CR>\<c-w>w")

  " enable linematch
  call term_sendkeys(buf, ":set diffopt+=linematch:30\<CR>")
  call WriteDiffFiles(buf, ['// abc d?',
      \ '// d?',
      \ '// d?' ],
      \ ['!',
      \ 'abc d!',
      \ 'd!'])
  call term_sendkeys(buf, ":\<CR>") " clear cmdline
  call VerifyScreenDump(buf, 'Test_linematch_diff1', {})

  " test that filler is always implicitly set by linematch
  call term_sendkeys(buf, ":set diffopt-=filler\<CR>")
  call term_sendkeys(buf, ":\<CR>") " clear cmdline
  call VerifyScreenDump(buf, 'Test_linematch_diff1', {})

  " clean up
  call StopVimInTerminal(buf)
endfunc

func Test_linematch_diff_iwhite()
  CheckScreendump
  call delete('.Xdifile1.swp')
  call delete('.Xdifile2.swp')
  call WriteDiffFiles(0, [], [])
  let buf = RunVimInTerminal('-d Xdifile1 Xdifile2', {})
  call term_sendkeys(buf, ":set autoread\<CR>\<c-w>w:set autoread\<CR>\<c-w>w")

  " setup a diff with 2 files and set linematch:30, with ignore white
  call term_sendkeys(buf, ":set diffopt+=linematch:30\<CR>")
  call WriteDiffFiles(buf, ['void testFunction () {',
      \ '  for (int i = 0; i < 10; i++) {',
      \ '    for (int j = 0; j < 10; j++) {',
      \ '    }',
      \ '  }',
      \ '}' ],
      \ ['void testFunction () {',
      \ '  // for (int j = 0; j < 10; i++) {',
      \ '  // }',
      \ '}'])
  call VerifyScreenDump(buf, 'Test_linematch_diff_iwhite1', {})
  call term_sendkeys(buf, ":set diffopt+=iwhiteall\<CR>")
  call VerifyScreenDump(buf, 'Test_linematch_diff_iwhite2', {})
  " clean up
  call StopVimInTerminal(buf)
endfunc

func Test_linematch_diff_grouping()
  CheckScreendump
  call delete('.Xdifile1.swp')
  call delete('.Xdifile2.swp')
  call WriteDiffFiles(0, [], [])
  let buf = RunVimInTerminal('-d Xdifile1 Xdifile2', {})
  call term_sendkeys(buf, ":set autoread\<CR>\<c-w>w:set autoread\<CR>\<c-w>w")

  " a diff that would result in multiple groups before grouping optimization
  call term_sendkeys(buf, ":set diffopt+=linematch:30\<CR>")
  call WriteDiffFiles(buf, ['!A',
      \ '!B',
      \ '!C' ],
      \ ['?Z',
      \ '?A',
      \ '?B',
      \ '?C',
      \ '?A',
      \ '?B',
      \ '?B',
      \ '?C'])
  call VerifyScreenDump(buf, 'Test_linematch_diff_grouping1', {})
  call WriteDiffFiles(buf, ['!A',
      \ '!B',
      \ '!C' ],
      \ ['?A',
      \ '?Z',
      \ '?B',
      \ '?C',
      \ '?A',
      \ '?B',
      \ '?C',
      \ '?C'])
  call VerifyScreenDump(buf, 'Test_linematch_diff_grouping2', {})
  " clean up
  call StopVimInTerminal(buf)
endfunc

func Test_linematch_diff_scroll()
  CheckScreendump
  call delete('.Xdifile1.swp')
  call delete('.Xdifile2.swp')
  call WriteDiffFiles(0, [], [])
  let buf = RunVimInTerminal('-d Xdifile1 Xdifile2', {})
  call term_sendkeys(buf, ":set autoread\<CR>\<c-w>w:set autoread\<CR>\<c-w>w")

  " a diff that would result in multiple groups before grouping optimization
  call term_sendkeys(buf, ":set diffopt+=linematch:30\<CR>")
  call WriteDiffFiles(buf, ['!A',
      \ '!B',
      \ '!C' ],
      \ ['?A',
      \ '?Z',
      \ '?B',
      \ '?C',
      \ '?A',
      \ '?B',
      \ '?C',
      \ '?C'])
  " scroll down to show calculation of top fill and scroll to correct line in
  " both windows
  call VerifyScreenDump(buf, 'Test_linematch_diff_grouping_scroll0', {})
  call term_sendkeys(buf, "3\<c-e>")
  call VerifyScreenDump(buf, 'Test_linematch_diff_grouping_scroll1', {})
  call term_sendkeys(buf, "3\<c-e>")
  call VerifyScreenDump(buf, 'Test_linematch_diff_grouping_scroll2', {})
  " clean up
  call StopVimInTerminal(buf)
endfunc

func Test_linematch_line_limit_exceeded()
  CheckScreendump
  call delete('.Xdifile1.swp')
  call delete('.Xdifile2.swp')
  call WriteDiffFiles(0, [], [])
  let buf = RunVimInTerminal('-d Xdifile1 Xdifile2', {})
  call term_sendkeys(buf, ":set autoread\<CR>\<c-w>w:set autoread\<CR>\<c-w>w")

  call term_sendkeys(buf, ":set diffopt+=linematch:10\<CR>")
  " a diff block will not be aligned with linematch because it's contents
  " exceed 10 lines
  call WriteDiffFiles(buf,
        \ ['common line',
        \ 'HIL',
        \ '',
        \ 'aABCabc',
        \ 'aABCabc',
        \ 'aABCabc',
        \ 'aABCabc',
        \ 'common line',
        \ 'HIL',
        \ 'common line',
        \ 'something'],
        \ ['common line',
        \ 'DEF',
        \ 'GHI',
        \ 'something',
        \ '',
        \ 'aDEFabc',
        \ 'xyz',
        \ 'xyz',
        \ 'xyz',
        \ 'aDEFabc',
        \ 'aDEFabc',
        \ 'aDEFabc',
        \ 'common line',
        \ 'DEF',
        \ 'GHI',
        \ 'something else',
        \ 'common line',
        \ 'something'])
  call VerifyScreenDump(buf, 'Test_linematch_line_limit_exceeded1', {})
  " after increasing the count to 30, the limit is not exceeded, and the
  " alignment algorithm will run on the largest diff block here
  call term_sendkeys(buf, ":set diffopt+=linematch:30\<CR>")
  call VerifyScreenDump(buf, 'Test_linematch_line_limit_exceeded2', {})
  " clean up
  call StopVimInTerminal(buf)
endfunc

func Test_linematch_3diffs()
  CheckScreendump
  call delete('.Xdifile1.swp')
  call delete('.Xdifile2.swp')
  call delete('.Xdifile3.swp')
  call WriteDiffFiles3(0, [], [], [])
  let buf = RunVimInTerminal('-d Xdifile1 Xdifile2 Xdifile3', {})
  call term_sendkeys(buf, "1\<c-w>w:set autoread\<CR>")
  call term_sendkeys(buf, "2\<c-w>w:set autoread\<CR>")
  call term_sendkeys(buf, "3\<c-w>w:set autoread\<CR>")
  call term_sendkeys(buf, ":set diffopt+=linematch:30\<CR>")
  call WriteDiffFiles3(buf,
        \ ["",
        \ "  common line",
        \ "      AAA",
        \ "      AAA",
        \ "      AAA"],
        \ ["",
        \ "  common line",
        \ "  <<<<<<< HEAD",
        \ "      AAA",
        \ "      AAA",
        \ "      AAA",
        \ "  =======",
        \ "      BBB",
        \ "      BBB",
        \ "      BBB",
        \ "  >>>>>>> branch1"],
        \ ["",
        \ "  common line",
        \ "      BBB",
        \ "      BBB",
        \ "      BBB"])
  call VerifyScreenDump(buf, 'Test_linematch_3diffs1', {})
  " clean up
  call StopVimInTerminal(buf)
endfunc

" this used to access invalid memory
func Test_linematch_3diffs_sanity_check()
  CheckScreendump
  call delete('.Xfile_linematch1.swp')
  call delete('.Xfile_linematch2.swp')
  call delete('.Xfile_linematch3.swp')
  let lines =<< trim END
    set diffopt+=linematch:60
    call feedkeys("Aq\<esc>")
    call feedkeys("GAklm\<esc>")
    call feedkeys("o")
  END
  call writefile(lines, 'Xlinematch_3diffs.vim', 'D')
  call writefile(['abcd', 'def', 'hij'], 'Xfile_linematch1', 'D')
  call writefile(['defq', 'hijk', 'nopq'], 'Xfile_linematch2', 'D')
  call writefile(['hijklm', 'nopqr', 'stuv'], 'Xfile_linematch3', 'D')
  call WriteDiffFiles3(0, [], [], [])
  let buf = RunVimInTerminal('-d -S Xlinematch_3diffs.vim Xfile_linematch1 Xfile_linematch2 Xfile_linematch3', {})
  call VerifyScreenDump(buf, 'Test_linematch_3diffs2', {})

  " clean up
  call StopVimInTerminal(buf)
endfunc

func Test_diffanchors()
  CheckScreendump
  call WriteDiffFiles3(0,
      \ ["anchorA1", "1", "2", "3",
      \  "100", "101", "102", "anchorB", "103", "104", "105"],
      \ ["100", "101", "102", "anchorB", "103", "104", "105",
      \  "anchorA2", "1", "2", "3"],
      \ ["100", "anchorB", "103",
      \  "anchorA3", "1", "2", "3"])
  let buf = RunVimInTerminal('-d Xdifile1 Xdifile2 Xdifile3', {})

  " Simple diff without any anchors
  call VerifyInternal(buf, "Test_diff_anchors_00", "")

  " Setting diffopt+=anchor or diffanchors without the other won't do anything
  call VerifyInternal(buf, "Test_diff_anchors_00", " diffopt+=anchor")
  call VerifyInternal(buf, "Test_diff_anchors_00", " dia=1/anchorA/")

  " Use a single anchor by specifying a pattern. Test both internal and
  " external diff to make sure both paths work.
  call VerifyBoth(buf, "Test_diff_anchors_01", " dia=1/anchorA/ diffopt+=anchor")

  " Use 2 anchors. They should be sorted by line number, so in file 2/3
  " anchorB is used before anchorA.
  call VerifyBoth(buf, "Test_diff_anchors_02", " dia=1/anchorA/,1/anchorB/ diffopt+=anchor")

  " Set marks and specify addresses using marks and repeat the test
  call term_sendkeys(buf, ":2wincmd w\<CR>:1/anchorA/mark a\<CR>")
  call term_sendkeys(buf, ":1/anchorB/mark b\<CR>")
  call term_sendkeys(buf, ":3wincmd w\<CR>:1/anchorA/mark a\<CR>")
  call term_sendkeys(buf, ":1/anchorB/mark b\<CR>")
  call term_sendkeys(buf, ":1wincmd w\<CR>:1/anchorA/mark a\<CR>")
  call term_sendkeys(buf, ":1/anchorB/mark b\<CR>")

  call VerifyInternal(buf, "Test_diff_anchors_01", " dia='a diffopt+=anchor")
  call VerifyInternal(buf, "Test_diff_anchors_02", " dia='a,'b diffopt+=anchor")

  " Update marks to point somewhere else. When we first set the mark the diff
  " won't be updated until we manually invoke :diffupdate.
  call VerifyInternal(buf, "Test_diff_anchors_01", " dia='a diffopt+=anchor")
  call term_sendkeys(buf, ":1wincmd w\<CR>:1/anchorB/mark a\<CR>:")
  call term_wait(buf)
  call VerifyScreenDump(buf, "Test_diff_anchors_01", {})
  call term_sendkeys(buf, ":diffupdate\<CR>:")
  call term_wait(buf)
  call VerifyScreenDump(buf, "Test_diff_anchors_03", {})

  " Use local diff anchors with line numbers, and repeat the same test
  call term_sendkeys(buf, ":2wincmd w\<CR>:setlocal dia=8\<CR>")
  call term_sendkeys(buf, ":3wincmd w\<CR>:setlocal dia=4\<CR>")
  call term_sendkeys(buf, ":1wincmd w\<CR>:setlocal dia=1\<CR>")
  call VerifyInternal(buf, "Test_diff_anchors_01", " diffopt+=anchor")
  call term_sendkeys(buf, ":2wincmd w\<CR>:setlocal dia=8,4\<CR>")
  call term_sendkeys(buf, ":3wincmd w\<CR>:setlocal dia=4,2\<CR>")
  call term_sendkeys(buf, ":1wincmd w\<CR>:setlocal dia=1,8\<CR>")
  call VerifyInternal(buf, "Test_diff_anchors_02", " diffopt+=anchor")

  " Test multiple diff anchors on the same line in file 1.
  call term_sendkeys(buf, ":1wincmd w\<CR>:setlocal dia=1,1\<CR>")
  call VerifyInternal(buf, "Test_diff_anchors_04", " diffopt+=anchor")

  " Test that if one file has fewer diff anchors than others. Vim should only
  " use the minimum in this case.
  call term_sendkeys(buf, ":1wincmd w\<CR>:setlocal dia=8\<CR>")
  call VerifyInternal(buf, "Test_diff_anchors_05", " diffopt+=anchor")

  " $+1 should anchor everything past the last line
  call term_sendkeys(buf, ":1wincmd w\<CR>:setlocal dia=$+1\<CR>")
  call VerifyInternal(buf, "Test_diff_anchors_06", " diffopt+=anchor")

  " Sorting of diff anchors should work with multiple anchors
  call term_sendkeys(buf, ":1wincmd w\<CR>:setlocal dia=1,10,8,2\<CR>")
  call term_sendkeys(buf, ":2wincmd w\<CR>:setlocal dia=1,2,3,4\<CR>")
  call term_sendkeys(buf, ":3wincmd w\<CR>:setlocal dia=4,3,2,1\<CR>")
  call VerifyInternal(buf, "Test_diff_anchors_07", " diffopt+=anchor")

  " Intentionally set an invalid anchor with wrong line number. Should fall
  " back to treat it as if no anchors are used at all.
  call term_sendkeys(buf, ":1wincmd w\<CR>:setlocal dia=1,10,8,2,1000 | silent! diffupdate\<CR>:")
  call VerifyScreenDump(buf, "Test_diff_anchors_00", {})

  call StopVimInTerminal(buf)
endfunc

" Test that scrollbind and topline calculations work correctly, even when diff
" anchors create adjacent diff blocks which complicates the calculations.
func Test_diffanchors_scrollbind_topline()
  CheckScreendump

  " Simple overlapped line anchored to be adjacent to each other
  call WriteDiffFiles(0,
      \ ["anchor1", "diff1a", "anchor2"],
      \ ["anchor1", "diff2a", "anchor2"])
  let buf = RunVimInTerminal('-d Xdifile1 Xdifile2', {})

  call term_sendkeys(buf, ":1wincmd w\<CR>:setlocal dia=2\<CR>")
  call term_sendkeys(buf, ":2wincmd w\<CR>:setlocal dia=3\<CR>")

  call VerifyInternal(buf, "Test_diff_anchors_scrollbind_topline_01", " diffopt+=anchor")
  call term_sendkeys(buf, "\<Esc>\<C-E>")
  call VerifyScreenDump(buf, "Test_diff_anchors_scrollbind_topline_02", {})
  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, "Test_diff_anchors_scrollbind_topline_03", {})
  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, "Test_diff_anchors_scrollbind_topline_04", {})

  " Also test no-filler
  call term_sendkeys(buf, "gg")
  call VerifyInternal(buf, "Test_diff_anchors_scrollbind_topline_05", " diffopt+=anchor diffopt-=filler")
  call term_sendkeys(buf, "\<Esc>\<C-E>")
  call VerifyScreenDump(buf, "Test_diff_anchors_scrollbind_topline_06", {})
  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, "Test_diff_anchors_scrollbind_topline_07", {})

  call StopVimInTerminal(buf)
endfunc

func Test_diffanchors_scrollbind_topline2()
  CheckScreendump

  " More-complicated case with 3 files and multiple overlapping diff blocks
  call WriteDiffFiles3(0,
      \ ["anchor1"],
      \ ["diff2a", "diff2b", "diff2c", "diff2d", "anchor2"],
      \ ["diff3a", "diff3c", "diff3d", "anchor3", "diff3e"])
  let buf = RunVimInTerminal('-d Xdifile1 Xdifile2 Xdifile3', {})

  call term_sendkeys(buf, ":1wincmd w\<CR>:setlocal dia=1,1,2\<CR>")
  call term_sendkeys(buf, ":2wincmd w\<CR>:setlocal dia=3,5,6\<CR>")
  call term_sendkeys(buf, ":3wincmd w\<CR>:setlocal dia=2,4,5\<CR>")

  call VerifyInternal(buf, "Test_diff_anchors_scrollbind_topline_08", " diffopt+=anchor")
  call term_sendkeys(buf, ":1wincmd w\<CR>")
  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, "Test_diff_anchors_scrollbind_topline_09", {})
  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, "Test_diff_anchors_scrollbind_topline_10", {})
  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, "Test_diff_anchors_scrollbind_topline_11", {})
  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, "Test_diff_anchors_scrollbind_topline_12", {})

  " Also test no-filler
  call term_sendkeys(buf, ":3wincmd w\<CR>gg")
  call VerifyInternal(buf, "Test_diff_anchors_scrollbind_topline_13", " diffopt+=anchor diffopt-=filler")
  call term_sendkeys(buf, "\<Esc>\<C-E>")
  call VerifyScreenDump(buf, "Test_diff_anchors_scrollbind_topline_14", {})
  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, "Test_diff_anchors_scrollbind_topline_15", {})
  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, "Test_diff_anchors_scrollbind_topline_16", {})
  call term_sendkeys(buf, "\<C-E>")
  call VerifyScreenDump(buf, "Test_diff_anchors_scrollbind_topline_17", {})

  call StopVimInTerminal(buf)
endfunc

" Test that setting 'diffanchors' will update the diff.
func Test_diffanchors_option_set_update()
  set diffanchors='a diffopt=internal,filler,anchor

  " Set up 3 tabs that share some buffers, and set up marks on each of them.
  " We want to make sure only relevant tabs are updated if buffer-local diff
  " anchors are updated, but all tabs should refresh if global diff anchors
  " are updated (see diffanchors_changed() in code).

  " Tab 1. A buffer here will be reused.
  call setline(1, range(1, 10))
  3mark a
  4mark b
  diffthis
  new
  call setline(1, range(21, 25))
  let buf = bufnr()
  1mark a
  2mark b
  diffthis
  call assert_equal(2, diff_filler(1))
  call assert_equal(0, diff_filler(2))

  " Tab 2. "buf" is here but intentionally not participating in diff.
  tabnew
  exec 'buf ' .. buf
  diffoff
  new
  call setline(1, range(31, 40))
  8mark a
  9mark b
  diffthis
  new
  call setline(1, range(41, 50))
  5mark a
  6mark b
  diffthis

  call assert_equal(3, diff_filler(5))
  call assert_equal(0, diff_filler(6))
  call assert_equal(0, diff_filler(7))

  " Update mark a location, and check that the diff has *not* updated. When
  " updating marks diff's won't automatically update.
  7mark a
  call assert_equal(3, diff_filler(5))
  call assert_equal(0, diff_filler(6))
  call assert_equal(0, diff_filler(7))

  " Tab 3. "buf" is used here and also in a diff.
  tabnew
  call setline(1, range(51, 65))
  10mark a
  11mark b
  diffthis
  exec 'sbuffer ' .. buf
  diffthis

  " Change local diff anchor of "buf" to mark b
  setlocal diffanchors='b

  " Tab 1 should immediately update the diff to use mark b because the buf
  " local diff anchor has been changed in "buf".
  1tabnext
  call assert_equal(0, diff_filler(1))
  call assert_equal(1, diff_filler(2))

  " Tab 2 should not immediately update because "buf" is not a diff buffer
  " here.
  2tabnext
  call assert_equal(3, diff_filler(5))
  call assert_equal(0, diff_filler(6))
  call assert_equal(0, diff_filler(7))

  " Manual diff update would refresh the diff since we previously changed mark
  " a's location above.
  diffupdate
  call assert_equal(0, diff_filler(5))
  call assert_equal(0, diff_filler(6))
  call assert_equal(1, diff_filler(7))

  " Go back to tab 1. Reset diff anchor to global value and make sure it uses
  " mark a again.
  1tabnext
  set diffanchors<
  call assert_equal(2, diff_filler(1))
  call assert_equal(0, diff_filler(2))

  " Now, change the global diff anchor to mark b. This should affect all tabs
  " including tab 2 which should update automatically.
  set diffanchors='b
  call assert_equal(0, diff_filler(1))
  call assert_equal(2, diff_filler(2))

  2tabnext
  call assert_equal(0, diff_filler(5))
  call assert_equal(3, diff_filler(6))
  call assert_equal(0, diff_filler(7))

  %bw!
  set diffopt&
  set diffanchors&
endfunc

" Test that using diff anchors with window/buffer-local addresses will work as
" expected and use the relevant window/buffer instead of curbuf/curwin.
func Test_diffanchors_buf_win_local_addresses()
  " Win 1-3 point to buffer 1. Set up different window-specific jump history
  " Win 2 is the one we activate diff mode on.
  call setline(1, range(1, 15))
  norm 2gg
  norm 3gg

  split
  norm 4gg
  norm 5gg

  split
  norm 11gg
  norm 12gg
  call setline(10, 'new text 1') " update the '. mark to line 10

  " Win 4 points to buffer 2
  botright vert new
  call setline(1, range(101, 110))
  norm 8gg
  norm 9gg
  call setline(3, 'new text 2') " update the '. mark to line 3

  2wincmd w
  diffthis
  4wincmd w
  diffthis

  " Test buffer-local marks using '. Should be anchored to lines 10 / 3.
  set diffopt=internal,filler,anchor
  set diffanchors='.
  4wincmd w
  call assert_equal(7, diff_filler(3))

  " Test window-local marks using '' Should be anchored to lines 4 / 8.
  " Note that windows 1 & 3 point to the buffer being diff'ed but are not used
  " for diffing themselves and therefore should not be used. Windows 2 & 4
  " should be used.
  set diffanchors=''
  2wincmd w
  call assert_equal(4, diff_filler(4))

  " Also test "." for the current cursor position, which is also
  " window-specific. Make sure the cursor position at the longer file doesn't
  " result in the other file using out of bounds line number.
  4wincmd w
  norm G
  2wincmd w
  norm G
  set diffanchors=.
  diffupdate
  4wincmd w
  call assert_equal(5, diff_filler(10))

  %bw!
  set diffopt&
  set diffanchors&
endfunc

" Test diff anchors error handling for anchors that fail to resolve to a line.
" These are not handled during option parsing because they depend on the
" specifics of the buffer at diff time.
func Test_diffanchors_invalid()
  call setline(1, range(1, 5))
  new
  call setline(1, range(11, 20))
  set diffopt=internal,filler,anchor
  windo diffthis
  1wincmd w

  " Line numbers that are out of bounds should be an error
  set diffanchors=0
  call assert_fails('diffupdate', 'E16:')
  set diffanchors=1
  diffupdate
  set diffanchors=$
  diffupdate
  set diffanchors=$+1
  diffupdate
  set diffanchors=$+2
  call assert_fails('diffupdate', 'E16:')

  " Test that non-existent marks in any one buffer will be detected
  set diffanchors='a
  call assert_fails('diffupdate', 'E20:')
  2mark a
  call assert_fails('diffupdate', 'E20:')

  set diffanchors=1
  setlocal diffanchors='a
  diffupdate

  set diffanchors<
  windo 2mark a
  set diffanchors='b
  call assert_fails('diffupdate', 'E20:')
  set diffanchors='a
  diffupdate

  " File marks are ok to use for anchors only if it is in the same file
  1wincmd w
  3mark C
  setlocal diffanchors='C
  diffupdate
  set diffanchors='C
  call assert_fails('diffupdate', 'E20:')

  " Buffer-local marks also can only be used in buffers that have them.
  set diffanchors=1
  exec "norm 1ggVj\<Esc>"
  setlocal diffanchors='<
  diffupdate
  set diffanchors='<
  call assert_fails('diffupdate', 'E20:')

  " Pattern search that failed will be an error too
  let @/='orig_search_pat'
  set diffanchors=1/5/
  diffupdate
  call assert_equal('orig_search_pat', @/) " also check we don't pollute the search register
  set diffanchors=1/does_not_exist/
  call assert_fails('diffupdate', 'E1550:')
  call assert_equal('orig_search_pat', @/)

  %bw!
  set diffopt&
  set diffanchors&
endfunc

" Test diffget/diffput behaviors when using diff anchors which could create
" adjacent diff blocks.
func Test_diffget_diffput_diffanchors()
  set diffanchors=1/anchor/
  set diffopt=internal,filler,anchor

  call setline(1, ['1', 'anchor1', '4'])
  diffthis
  new
  call setline(1, ['2', '3', 'anchor2', '4', '5'])
  diffthis
  wincmd w

  " Test using no-range diffget. It should grab the closest diff block only,
  " even if there are multiple adjacent blocks.
  2
  diffget
  call assert_equal(['1', 'anchor2', '4'], getline(1, '$'))
  diffget
  call assert_equal(['2', '3', 'anchor2', '4'], getline(1, '$'))

  " Test using a range to get/put all the adjacent diff blocks.
  1,$delete
  call setline(1, ['anchor1', '4'])
  0,1 diffget
  call assert_equal(['2', '3', 'anchor2', '4'], getline(1, '$'))

  1,$delete
  call setline(1, ['anchor1', '4'])
  0,$+1 diffget
  call assert_equal(['2', '3', 'anchor2', '4', '5'], getline(1, '$'))

  1,$delete
  call setline(1, ['anchor1', '4'])
  0,1 diffput
  wincmd w
  call assert_equal(['anchor1', '4', '5'], getline(1,'$'))

  %bw!
  set diffopt&
  set diffanchors&
endfunc

" vim: shiftwidth=2 sts=2 expandtab
