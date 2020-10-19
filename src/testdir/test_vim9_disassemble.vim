" Test the :disassemble command, and compilation as a side effect

source check.vim

func NotCompiled()
  echo "not"
endfunc

let s:scriptvar = 4
let g:globalvar = 'g'
let b:buffervar = 'b'
let w:windowvar = 'w'
let t:tabpagevar = 't'

def s:ScriptFuncLoad(arg: string)
  var local = 1
  buffers
  echo arg
  echo local
  echo &lines
  echo v:version
  echo s:scriptvar
  echo g:globalvar
  echo get(g:, "global")
  echo b:buffervar
  echo get(b:, "buffer")
  echo w:windowvar
  echo get(w:, "window")
  echo t:tabpagevar
  echo get(t:, "tab")
  echo &tabstop
  echo $ENVVAR
  echo @z
enddef

def Test_disassemble_load()
  assert_fails('disass NoFunc', 'E1061:')
  assert_fails('disass NotCompiled', 'E1091:')
  assert_fails('disass', 'E471:')
  assert_fails('disass [', 'E475:')
  assert_fails('disass 234', 'E129:')
  assert_fails('disass <XX>foo', 'E129:')

  var res = execute('disass s:ScriptFuncLoad')
  assert_match('<SNR>\d*_ScriptFuncLoad.*' ..
        'buffers.*' ..
        ' EXEC \+buffers.*' ..
        ' LOAD arg\[-1\].*' ..
        ' LOAD $0.*' ..
        ' LOADOPT &lines.*' ..
        ' LOADV v:version.*' ..
        ' LOADS s:scriptvar from .*test_vim9_disassemble.vim.*' ..
        ' LOADG g:globalvar.*' ..
        'echo get(g:, "global")\_s*' ..
        '\d\+ LOAD g:\_s*' ..
        '\d\+ PUSHS "global"\_s*' ..
        '\d\+ BCALL get(argc 2).*' ..
        ' LOADB b:buffervar.*' ..
        'echo get(b:, "buffer")\_s*' ..
        '\d\+ LOAD b:\_s*' ..
        '\d\+ PUSHS "buffer"\_s*' ..
        '\d\+ BCALL get(argc 2).*' ..
        ' LOADW w:windowvar.*' ..
        'echo get(w:, "window")\_s*' ..
        '\d\+ LOAD w:\_s*' ..
        '\d\+ PUSHS "window"\_s*' ..
        '\d\+ BCALL get(argc 2).*' ..
        ' LOADT t:tabpagevar.*' ..
        'echo get(t:, "tab")\_s*' ..
        '\d\+ LOAD t:\_s*' ..
        '\d\+ PUSHS "tab"\_s*' ..
        '\d\+ BCALL get(argc 2).*' ..
        ' LOADENV $ENVVAR.*' ..
        ' LOADREG @z.*',
        res)
enddef

def s:EditExpand()
  var filename = "file"
  var filenr = 123
  edit the`=filename``=filenr`.txt
enddef

def Test_disassemble_exec_expr()
  var res = execute('disass s:EditExpand')
  assert_match('<SNR>\d*_EditExpand\_s*' ..
        ' var filename = "file"\_s*' ..
        '\d PUSHS "file"\_s*' ..
        '\d STORE $0\_s*' ..
        ' var filenr = 123\_s*' ..
        '\d STORE 123 in $1\_s*' ..
        ' edit the`=filename``=filenr`.txt\_s*' ..
        '\d PUSHS "edit the"\_s*' ..
        '\d LOAD $0\_s*' ..
        '\d LOAD $1\_s*' ..
        '\d 2STRING stack\[-1\]\_s*' ..
        '\d\+ PUSHS ".txt"\_s*' ..
        '\d\+ EXECCONCAT 4\_s*' ..
        '\d\+ PUSHNR 0\_s*' ..
        '\d\+ RETURN',
        res)
enddef

def s:YankRange()
  norm! m[jjm]
  :'[,']yank
enddef

def Test_disassemble_yank_range()
  var res = execute('disass s:YankRange')
  assert_match('<SNR>\d*_YankRange.*' ..
        ' norm! m\[jjm\]\_s*' ..
        '\d EXEC   norm! m\[jjm\]\_s*' ..
        '  :''\[,''\]yank\_s*' ..
        '\d EXEC   :''\[,''\]yank\_s*' ..
        '\d PUSHNR 0\_s*' ..
        '\d RETURN',
        res)
enddef

def s:PutExpr()
  :3put ="text"
enddef

def Test_disassemble_put_expr()
  var res = execute('disass s:PutExpr')
  assert_match('<SNR>\d*_PutExpr.*' ..
        ' :3put ="text"\_s*' ..
        '\d PUSHS "text"\_s*' ..
        '\d PUT = 3\_s*' ..
        '\d PUSHNR 0\_s*' ..
        '\d RETURN',
        res)
enddef

def s:ScriptFuncPush()
  var localbool = true
  var localspec = v:none
  var localblob = 0z1234
  if has('float')
    var localfloat = 1.234
  endif
enddef

def Test_disassemble_push()
  var res = execute('disass s:ScriptFuncPush')
  assert_match('<SNR>\d*_ScriptFuncPush.*' ..
        'localbool = true.*' ..
        ' PUSH v:true.*' ..
        'localspec = v:none.*' ..
        ' PUSH v:none.*' ..
        'localblob = 0z1234.*' ..
        ' PUSHBLOB 0z1234.*',
        res)
  if has('float')
    assert_match('<SNR>\d*_ScriptFuncPush.*' ..
          'localfloat = 1.234.*' ..
          ' PUSHF 1.234.*',
          res)
  endif
enddef

def s:ScriptFuncStore()
  var localnr = 1
  localnr = 2
  var localstr = 'abc'
  localstr = 'xyz'
  v:char = 'abc'
  s:scriptvar = 'sv'
  g:globalvar = 'gv'
  b:buffervar = 'bv'
  w:windowvar = 'wv'
  t:tabpagevar = 'tv'
  &tabstop = 8
  $ENVVAR = 'ev'
  @z = 'rv'
enddef

def Test_disassemble_store()
  var res = execute('disass s:ScriptFuncStore')
  assert_match('<SNR>\d*_ScriptFuncStore.*' ..
        'var localnr = 1.*' ..
        'localnr = 2.*' ..
        ' STORE 2 in $0.*' ..
        'var localstr = ''abc''.*' ..
        'localstr = ''xyz''.*' ..
        ' STORE $1.*' ..
        'v:char = ''abc''.*' ..
        'STOREV v:char.*' ..
        's:scriptvar = ''sv''.*' ..
        ' STORES s:scriptvar in .*test_vim9_disassemble.vim.*' ..
        'g:globalvar = ''gv''.*' ..
        ' STOREG g:globalvar.*' ..
        'b:buffervar = ''bv''.*' ..
        ' STOREB b:buffervar.*' ..
        'w:windowvar = ''wv''.*' ..
        ' STOREW w:windowvar.*' ..
        't:tabpagevar = ''tv''.*' ..
        ' STORET t:tabpagevar.*' ..
        '&tabstop = 8.*' ..
        ' STOREOPT &tabstop.*' ..
        '$ENVVAR = ''ev''.*' ..
        ' STOREENV $ENVVAR.*' ..
        '@z = ''rv''.*' ..
        ' STOREREG @z.*',
        res)
enddef

def s:ScriptFuncStoreMember()
  var locallist: list<number> = []
  locallist[0] = 123
  var localdict: dict<number> = {}
  localdict["a"] = 456
enddef

def Test_disassemble_store_member()
  var res = execute('disass s:ScriptFuncStoreMember')
  assert_match('<SNR>\d*_ScriptFuncStoreMember\_s*' ..
        'var locallist: list<number> = []\_s*' ..
        '\d NEWLIST size 0\_s*' ..
        '\d STORE $0\_s*' ..
        'locallist\[0\] = 123\_s*' ..
        '\d PUSHNR 123\_s*' ..
        '\d PUSHNR 0\_s*' ..
        '\d LOAD $0\_s*' ..
        '\d STORELIST\_s*' ..
        'var localdict: dict<number> = {}\_s*' ..
        '\d NEWDICT size 0\_s*' ..
        '\d STORE $1\_s*' ..
        'localdict\["a"\] = 456\_s*' ..
        '\d\+ PUSHNR 456\_s*' ..
        '\d\+ PUSHS "a"\_s*' ..
        '\d\+ LOAD $1\_s*' ..
        '\d\+ STOREDICT\_s*' ..
        '\d\+ PUSHNR 0\_s*' ..
        '\d\+ RETURN',
        res)
enddef

def s:ListAssign()
  var x: string
  var y: string
  var l: list<any>
  [x, y; l] = g:stringlist
enddef

def Test_disassemble_list_assign()
  var res = execute('disass s:ListAssign')
  assert_match('<SNR>\d*_ListAssign\_s*' ..
        'var x: string\_s*' ..
        '\d PUSHS "\[NULL\]"\_s*' ..
        '\d STORE $0\_s*' ..
        'var y: string\_s*' ..
        '\d PUSHS "\[NULL\]"\_s*' ..
        '\d STORE $1\_s*' ..
        'var l: list<any>\_s*' ..
        '\d NEWLIST size 0\_s*' ..
        '\d STORE $2\_s*' ..
        '\[x, y; l\] = g:stringlist\_s*' ..
        '\d LOADG g:stringlist\_s*' ..
        '\d CHECKTYPE list<any> stack\[-1\]\_s*' ..
        '\d CHECKLEN >= 2\_s*' ..
        '\d\+ ITEM 0\_s*' ..
        '\d\+ CHECKTYPE string stack\[-1\]\_s*' ..
        '\d\+ STORE $0\_s*' ..
        '\d\+ ITEM 1\_s*' ..
        '\d\+ CHECKTYPE string stack\[-1\]\_s*' ..
        '\d\+ STORE $1\_s*' ..
        '\d\+ SLICE 2\_s*' ..
        '\d\+ STORE $2\_s*' ..
        '\d\+ PUSHNR 0\_s*' ..
        '\d\+ RETURN',
        res)
enddef

def s:ListAdd()
  var l: list<number> = []
  add(l, 123)
  add(l, g:aNumber)
enddef

def Test_disassemble_list_add()
  var res = execute('disass s:ListAdd')
  assert_match('<SNR>\d*_ListAdd\_s*' ..
        'var l: list<number> = []\_s*' ..
        '\d NEWLIST size 0\_s*' ..
        '\d STORE $0\_s*' ..
        'add(l, 123)\_s*' ..
        '\d LOAD $0\_s*' ..
        '\d PUSHNR 123\_s*' ..
        '\d LISTAPPEND\_s*' ..
        '\d DROP\_s*' ..
        'add(l, g:aNumber)\_s*' ..
        '\d LOAD $0\_s*' ..
        '\d\+ LOADG g:aNumber\_s*' ..
        '\d\+ CHECKTYPE number stack\[-1\]\_s*' ..
        '\d\+ LISTAPPEND\_s*' ..
        '\d\+ DROP\_s*' ..
        '\d\+ PUSHNR 0\_s*' ..
        '\d\+ RETURN',
        res)
enddef

def s:ScriptFuncUnlet()
  g:somevar = "value"
  unlet g:somevar
  unlet! g:somevar
  unlet $SOMEVAR
enddef

def Test_disassemble_unlet()
  var res = execute('disass s:ScriptFuncUnlet')
  assert_match('<SNR>\d*_ScriptFuncUnlet\_s*' ..
        'g:somevar = "value"\_s*' ..
        '\d PUSHS "value"\_s*' ..
        '\d STOREG g:somevar\_s*' ..
        'unlet g:somevar\_s*' ..
        '\d UNLET g:somevar\_s*' ..
        'unlet! g:somevar\_s*' ..
        '\d UNLET! g:somevar\_s*' ..
        'unlet $SOMEVAR\_s*' ..
        '\d UNLETENV $SOMEVAR\_s*',
        res)
enddef

def s:ScriptFuncTry()
  try
    echo "yes"
  catch /fail/
    echo "no"
  finally
    throw "end"
  endtry
enddef

def Test_disassemble_try()
  var res = execute('disass s:ScriptFuncTry')
  assert_match('<SNR>\d*_ScriptFuncTry\_s*' ..
        'try\_s*' ..
        '\d TRY catch -> \d\+, finally -> \d\+\_s*' ..
        'echo "yes"\_s*' ..
        '\d PUSHS "yes"\_s*' ..
        '\d ECHO 1\_s*' ..
        'catch /fail/\_s*' ..
        '\d JUMP -> \d\+\_s*' ..
        '\d PUSH v:exception\_s*' ..
        '\d PUSHS "fail"\_s*' ..
        '\d COMPARESTRING =\~\_s*' ..
        '\d JUMP_IF_FALSE -> \d\+\_s*' ..
        '\d CATCH\_s*' ..
        'echo "no"\_s*' ..
        '\d\+ PUSHS "no"\_s*' ..
        '\d\+ ECHO 1\_s*' ..
        'finally\_s*' ..
        'throw "end"\_s*' ..
        '\d\+ PUSHS "end"\_s*' ..
        '\d\+ THROW\_s*' ..
        'endtry\_s*' ..
        '\d\+ ENDTRY',
        res)
enddef

def s:ScriptFuncNew()
  var ll = [1, "two", 333]
  var dd = #{one: 1, two: "val"}
enddef

def Test_disassemble_new()
  var res = execute('disass s:ScriptFuncNew')
  assert_match('<SNR>\d*_ScriptFuncNew\_s*' ..
        'var ll = \[1, "two", 333\]\_s*' ..
        '\d PUSHNR 1\_s*' ..
        '\d PUSHS "two"\_s*' ..
        '\d PUSHNR 333\_s*' ..
        '\d NEWLIST size 3\_s*' ..
        '\d STORE $0\_s*' ..
        'var dd = #{one: 1, two: "val"}\_s*' ..
        '\d PUSHS "one"\_s*' ..
        '\d PUSHNR 1\_s*' ..
        '\d PUSHS "two"\_s*' ..
        '\d PUSHS "val"\_s*' ..
        '\d NEWDICT size 2\_s*',
        res)
enddef

def FuncWithArg(arg: any)
  echo arg
enddef

func UserFunc()
  echo 'nothing'
endfunc

func UserFuncWithArg(arg)
  echo a:arg
endfunc

def s:ScriptFuncCall(): string
  changenr()
  char2nr("abc")
  Test_disassemble_new()
  FuncWithArg(343)
  ScriptFuncNew()
  s:ScriptFuncNew()
  UserFunc()
  UserFuncWithArg("foo")
  var FuncRef = function("UserFunc")
  FuncRef()
  var FuncRefWithArg = function("UserFuncWithArg")
  FuncRefWithArg("bar")
  return "yes"
enddef

def Test_disassemble_call()
  var res = execute('disass s:ScriptFuncCall')
  assert_match('<SNR>\d\+_ScriptFuncCall\_s*' ..
        'changenr()\_s*' ..
        '\d BCALL changenr(argc 0)\_s*' ..
        '\d DROP\_s*' ..
        'char2nr("abc")\_s*' ..
        '\d PUSHS "abc"\_s*' ..
        '\d BCALL char2nr(argc 1)\_s*' ..
        '\d DROP\_s*' ..
        'Test_disassemble_new()\_s*' ..
        '\d DCALL Test_disassemble_new(argc 0)\_s*' ..
        '\d DROP\_s*' ..
        'FuncWithArg(343)\_s*' ..
        '\d\+ PUSHNR 343\_s*' ..
        '\d\+ DCALL FuncWithArg(argc 1)\_s*' ..
        '\d\+ DROP\_s*' ..
        'ScriptFuncNew()\_s*' ..
        '\d\+ DCALL <SNR>\d\+_ScriptFuncNew(argc 0)\_s*' ..
        '\d\+ DROP\_s*' ..
        's:ScriptFuncNew()\_s*' ..
        '\d\+ DCALL <SNR>\d\+_ScriptFuncNew(argc 0)\_s*' ..
        '\d\+ DROP\_s*' ..
        'UserFunc()\_s*' ..
        '\d\+ UCALL UserFunc(argc 0)\_s*' ..
        '\d\+ DROP\_s*' ..
        'UserFuncWithArg("foo")\_s*' ..
        '\d\+ PUSHS "foo"\_s*' ..
        '\d\+ UCALL UserFuncWithArg(argc 1)\_s*' ..
        '\d\+ DROP\_s*' ..
        'var FuncRef = function("UserFunc")\_s*' ..
        '\d\+ PUSHS "UserFunc"\_s*' ..
        '\d\+ BCALL function(argc 1)\_s*' ..
        '\d\+ STORE $0\_s*' ..
        'FuncRef()\_s*' ..
        '\d\+ LOAD $\d\_s*' ..
        '\d\+ PCALL (argc 0)\_s*' ..
        '\d\+ DROP\_s*' ..
        'var FuncRefWithArg = function("UserFuncWithArg")\_s*' ..
        '\d\+ PUSHS "UserFuncWithArg"\_s*' ..
        '\d\+ BCALL function(argc 1)\_s*' ..
        '\d\+ STORE $1\_s*' ..
        'FuncRefWithArg("bar")\_s*' ..
        '\d\+ PUSHS "bar"\_s*' ..
        '\d\+ LOAD $\d\_s*' ..
        '\d\+ PCALL (argc 1)\_s*' ..
        '\d\+ DROP\_s*' ..
        'return "yes"\_s*' ..
        '\d\+ PUSHS "yes"\_s*' ..
        '\d\+ RETURN',
        res)
enddef


def s:CreateRefs()
  var local = 'a'
  def Append(arg: string)
    local ..= arg
  enddef
  g:Append = Append
  def Get(): string
    return local
  enddef
  g:Get = Get
enddef

def Test_disassemble_closure()
  CreateRefs()
  var res = execute('disass g:Append')
  assert_match('<lambda>\d\_s*' ..
        'local ..= arg\_s*' ..
        '\d LOADOUTER $0\_s*' ..
        '\d LOAD arg\[-1\]\_s*' ..
        '\d CONCAT\_s*' ..
        '\d STOREOUTER $0\_s*' ..
        '\d PUSHNR 0\_s*' ..
        '\d RETURN',
        res)

  res = execute('disass g:Get')
  assert_match('<lambda>\d\_s*' ..
        'return local\_s*' ..
        '\d LOADOUTER $0\_s*' ..
        '\d RETURN',
        res)

  unlet g:Append
  unlet g:Get
enddef


def EchoArg(arg: string): string
  return arg
enddef
def RefThis(): func
  return function('EchoArg')
enddef
def s:ScriptPCall()
  RefThis()("text")
enddef

def Test_disassemble_pcall()
  var res = execute('disass s:ScriptPCall')
  assert_match('<SNR>\d\+_ScriptPCall\_s*' ..
        'RefThis()("text")\_s*' ..
        '\d DCALL RefThis(argc 0)\_s*' ..
        '\d PUSHS "text"\_s*' ..
        '\d PCALL top (argc 1)\_s*' ..
        '\d PCALL end\_s*' ..
        '\d DROP\_s*' ..
        '\d PUSHNR 0\_s*' ..
        '\d RETURN',
        res)
enddef


def s:FuncWithForwardCall(): string
  return g:DefinedLater("yes")
enddef

def DefinedLater(arg: string): string
  return arg
enddef

def Test_disassemble_update_instr()
  var res = execute('disass s:FuncWithForwardCall')
  assert_match('FuncWithForwardCall\_s*' ..
        'return g:DefinedLater("yes")\_s*' ..
        '\d PUSHS "yes"\_s*' ..
        '\d DCALL DefinedLater(argc 1)\_s*' ..
        '\d RETURN',
        res)

  # Calling the function will change UCALL into the faster DCALL
  assert_equal('yes', FuncWithForwardCall())

  res = execute('disass s:FuncWithForwardCall')
  assert_match('FuncWithForwardCall\_s*' ..
        'return g:DefinedLater("yes")\_s*' ..
        '\d PUSHS "yes"\_s*' ..
        '\d DCALL DefinedLater(argc 1)\_s*' ..
        '\d RETURN',
        res)
enddef


def FuncWithDefault(arg: string = 'default'): string
  return arg
enddef

def Test_disassemble_call_default()
  var res = execute('disass FuncWithDefault')
  assert_match('FuncWithDefault\_s*' ..
        '\d PUSHS "default"\_s*' ..
        '\d STORE arg\[-1]\_s*' ..
        'return arg\_s*' ..
        '\d LOAD arg\[-1]\_s*' ..
        '\d RETURN',
        res)
enddef


def HasEval()
  if has("eval")
    echo "yes"
  else
    echo "no"
  endif
enddef

def HasNothing()
  if has("nothing")
    echo "yes"
  else
    echo "no"
  endif
enddef

def HasSomething()
  if has("nothing")
    echo "nothing"
  elseif has("something")
    echo "something"
  elseif has("eval")
    echo "eval"
  elseif has("less")
    echo "less"
  endif
enddef

def Test_disassemble_const_expr()
  assert_equal("\nyes", execute('HasEval()'))
  var instr = execute('disassemble HasEval')
  assert_match('HasEval\_s*' ..
        'if has("eval")\_s*' ..
        'echo "yes"\_s*' ..
        '\d PUSHS "yes"\_s*' ..
        '\d ECHO 1\_s*' ..
        'else\_s*' ..
        'echo "no"\_s*' ..
        'endif\_s*',
        instr)
  assert_notmatch('JUMP', instr)

  assert_equal("\nno", execute('HasNothing()'))
  instr = execute('disassemble HasNothing')
  assert_match('HasNothing\_s*' ..
        'if has("nothing")\_s*' ..
        'echo "yes"\_s*' ..
        'else\_s*' ..
        'echo "no"\_s*' ..
        '\d PUSHS "no"\_s*' ..
        '\d ECHO 1\_s*' ..
        'endif',
        instr)
  assert_notmatch('PUSHS "yes"', instr)
  assert_notmatch('JUMP', instr)

  assert_equal("\neval", execute('HasSomething()'))
  instr = execute('disassemble HasSomething')
  assert_match('HasSomething.*' ..
        'if has("nothing")\_s*' ..
        'echo "nothing"\_s*' ..
        'elseif has("something")\_s*' ..
        'echo "something"\_s*' ..
        'elseif has("eval")\_s*' ..
        'echo "eval"\_s*' ..
        '\d PUSHS "eval"\_s*' ..
        '\d ECHO 1\_s*' ..
        'elseif has("less").*' ..
        'echo "less"\_s*' ..
        'endif',
        instr)
  assert_notmatch('PUSHS "nothing"', instr)
  assert_notmatch('PUSHS "something"', instr)
  assert_notmatch('PUSHS "less"', instr)
  assert_notmatch('JUMP', instr)
enddef

def ReturnInIf(): string
  if g:cond
    return "yes"
  else
    return "no"
  endif
enddef

def Test_disassemble_return_in_if()
  var instr = execute('disassemble ReturnInIf')
  assert_match('ReturnInIf\_s*' ..
        'if g:cond\_s*' ..
        '0 LOADG g:cond\_s*' ..
        '1 JUMP_IF_FALSE -> 4\_s*' ..
        'return "yes"\_s*' ..
        '2 PUSHS "yes"\_s*' ..
        '3 RETURN\_s*' ..
        'else\_s*' ..
        ' return "no"\_s*' ..
        '4 PUSHS "no"\_s*' ..
        '5 RETURN$',
        instr)
enddef

def WithFunc()
  var Funky1: func
  var Funky2: func = function("len")
  var Party2: func = funcref("UserFunc")
enddef

def Test_disassemble_function()
  var instr = execute('disassemble WithFunc')
  assert_match('WithFunc\_s*' ..
        'var Funky1: func\_s*' ..
        '0 PUSHFUNC "\[none]"\_s*' ..
        '1 STORE $0\_s*' ..
        'var Funky2: func = function("len")\_s*' ..
        '2 PUSHS "len"\_s*' ..
        '3 BCALL function(argc 1)\_s*' ..
        '4 STORE $1\_s*' ..
        'var Party2: func = funcref("UserFunc")\_s*' ..
        '\d PUSHS "UserFunc"\_s*' ..
        '\d BCALL funcref(argc 1)\_s*' ..
        '\d STORE $2\_s*' ..
        '\d PUSHNR 0\_s*' ..
        '\d RETURN',
        instr)
enddef

if has('channel')
  def WithChannel()
    var job1: job
    var job2: job = job_start("donothing")
    var chan1: channel
  enddef
endif

def Test_disassemble_channel()
  CheckFeature channel

  var instr = execute('disassemble WithChannel')
  assert_match('WithChannel\_s*' ..
        'var job1: job\_s*' ..
        '\d PUSHJOB "no process"\_s*' ..
        '\d STORE $0\_s*' ..
        'var job2: job = job_start("donothing")\_s*' ..
        '\d PUSHS "donothing"\_s*' ..
        '\d BCALL job_start(argc 1)\_s*' ..
        '\d STORE $1\_s*' ..
        'var chan1: channel\_s*' ..
        '\d PUSHCHANNEL 0\_s*' ..
        '\d STORE $2\_s*' ..
        '\d PUSHNR 0\_s*' ..
        '\d RETURN',
        instr)
enddef

def WithLambda(): string
  var F = {a -> "X" .. a .. "X"}
  return F("x")
enddef

def Test_disassemble_lambda()
  assert_equal("XxX", WithLambda())
  var instr = execute('disassemble WithLambda')
  assert_match('WithLambda\_s*' ..
        'var F = {a -> "X" .. a .. "X"}\_s*' ..
        '\d FUNCREF <lambda>\d\+\_s*' ..
        '\d STORE $0\_s*' ..
        'return F("x")\_s*' ..
        '\d PUSHS "x"\_s*' ..
        '\d LOAD $0\_s*' ..
        '\d PCALL (argc 1)\_s*' ..
        '\d RETURN',
        instr)

   var name = substitute(instr, '.*\(<lambda>\d\+\).*', '\1', '')
   instr = execute('disassemble ' .. name)
   assert_match('<lambda>\d\+\_s*' ..
        'return "X" .. a .. "X"\_s*' ..
        '\d PUSHS "X"\_s*' ..
        '\d LOAD arg\[-1\]\_s*' ..
        '\d 2STRING_ANY stack\[-1\]\_s*' ..
        '\d CONCAT\_s*' ..
        '\d PUSHS "X"\_s*' ..
        '\d CONCAT\_s*' ..
        '\d RETURN',
        instr)
enddef

def NestedOuter()
  def g:Inner()
    echomsg "inner"
  enddef
enddef

def Test_nested_func()
   var instr = execute('disassemble NestedOuter')
   assert_match('NestedOuter\_s*' ..
        'def g:Inner()\_s*' ..
        'echomsg "inner"\_s*' ..
        'enddef\_s*' ..
        '\d NEWFUNC <lambda>\d\+ Inner\_s*' ..
        '\d PUSHNR 0\_s*' ..
        '\d RETURN',
        instr)
enddef

def AndOr(arg: any): string
  if arg == 1 && arg != 2 || arg == 4
    return 'yes'
  endif
  return 'no'
enddef

def Test_disassemble_and_or()
  assert_equal("yes", AndOr(1))
  assert_equal("no", AndOr(2))
  assert_equal("yes", AndOr(4))
  var instr = execute('disassemble AndOr')
  assert_match('AndOr\_s*' ..
        'if arg == 1 && arg != 2 || arg == 4\_s*' ..
        '\d LOAD arg\[-1]\_s*' ..
        '\d PUSHNR 1\_s*' ..
        '\d COMPAREANY ==\_s*' ..
        '\d JUMP_IF_COND_FALSE -> \d\+\_s*' ..
        '\d LOAD arg\[-1]\_s*' ..
        '\d PUSHNR 2\_s*' ..
        '\d COMPAREANY !=\_s*' ..
        '\d JUMP_IF_COND_TRUE -> \d\+\_s*' ..
        '\d LOAD arg\[-1]\_s*' ..
        '\d\+ PUSHNR 4\_s*' ..
        '\d\+ COMPAREANY ==\_s*' ..
        '\d\+ JUMP_IF_FALSE -> \d\+',
        instr)
enddef

def ForLoop(): list<number>
  var res: list<number>
  for i in range(3)
    res->add(i)
  endfor
  return res
enddef

def Test_disassemble_for_loop()
  assert_equal([0, 1, 2], ForLoop())
  var instr = execute('disassemble ForLoop')
  assert_match('ForLoop\_s*' ..
        'var res: list<number>\_s*' ..
        '\d NEWLIST size 0\_s*' ..
        '\d STORE $0\_s*' ..
        'for i in range(3)\_s*' ..
        '\d STORE -1 in $1\_s*' ..
        '\d PUSHNR 3\_s*' ..
        '\d BCALL range(argc 1)\_s*' ..
        '\d FOR $1 -> \d\+\_s*' ..
        '\d STORE $2\_s*' ..
        'res->add(i)\_s*' ..
        '\d LOAD $0\_s*' ..
        '\d LOAD $2\_s*' ..
        '\d\+ LISTAPPEND\_s*' ..
        '\d\+ DROP\_s*' ..
        'endfor\_s*' ..
        '\d\+ JUMP -> \d\+\_s*' ..
        '\d\+ DROP',
        instr)
enddef

def ForLoopEval(): string
  var res = ""
  for str in eval('["one", "two"]')
    res ..= str
  endfor
  return res
enddef

def Test_disassemble_for_loop_eval()
  assert_equal('onetwo', ForLoopEval())
  var instr = execute('disassemble ForLoopEval')
  assert_match('ForLoopEval\_s*' ..
        'var res = ""\_s*' ..
        '\d PUSHS ""\_s*' ..
        '\d STORE $0\_s*' ..
        'for str in eval(''\["one", "two"\]'')\_s*' ..
        '\d STORE -1 in $1\_s*' ..
        '\d PUSHS "\["one", "two"\]"\_s*' ..
        '\d BCALL eval(argc 1)\_s*' ..
        '\d CHECKTYPE list<any> stack\[-1\]\_s*' ..
        '\d FOR $1 -> \d\+\_s*' ..
        '\d STORE $2\_s*' ..
        'res ..= str\_s*' ..
        '\d\+ LOAD $0\_s*' ..
        '\d\+ LOAD $2\_s*' ..
        '\d\+ CHECKTYPE string stack\[-1\]\_s*' ..
        '\d\+ CONCAT\_s*' ..
        '\d\+ STORE $0\_s*' ..
        'endfor\_s*' ..
        '\d\+ JUMP -> 6\_s*' ..
        '\d\+ DROP\_s*' ..
        'return res\_s*' ..
        '\d\+ LOAD $0\_s*' ..
        '\d\+ RETURN',
        instr)
enddef

let g:number = 42

def TypeCast()
  var l: list<number> = [23, <number>g:number]
enddef

def Test_disassemble_typecast()
  var instr = execute('disassemble TypeCast')
  assert_match('TypeCast.*' ..
        'var l: list<number> = \[23, <number>g:number\].*' ..
        '\d PUSHNR 23\_s*' ..
        '\d LOADG g:number\_s*' ..
        '\d CHECKTYPE number stack\[-1\]\_s*' ..
        '\d NEWLIST size 2\_s*' ..
        '\d STORE $0\_s*' ..
        '\d PUSHNR 0\_s*' ..
        '\d RETURN\_s*',
        instr)
enddef

def Computing()
  var nr = 3
  var nrres = nr + 7
  nrres = nr - 7
  nrres = nr * 7
  nrres = nr / 7
  nrres = nr % 7

  var anyres = g:number + 7
  anyres = g:number - 7
  anyres = g:number * 7
  anyres = g:number / 7
  anyres = g:number % 7

  if has('float')
    var fl = 3.0
    var flres = fl + 7.0
    flres = fl - 7.0
    flres = fl * 7.0
    flres = fl / 7.0
  endif
enddef

def Test_disassemble_computing()
  var instr = execute('disassemble Computing')
  assert_match('Computing.*' ..
        'var nr = 3.*' ..
        '\d STORE 3 in $0.*' ..
        'var nrres = nr + 7.*' ..
        '\d LOAD $0.*' ..
        '\d PUSHNR 7.*' ..
        '\d OPNR +.*' ..
        '\d STORE $1.*' ..
        'nrres = nr - 7.*' ..
        '\d OPNR -.*' ..
        'nrres = nr \* 7.*' ..
        '\d OPNR \*.*' ..
        'nrres = nr / 7.*' ..
        '\d OPNR /.*' ..
        'nrres = nr % 7.*' ..
        '\d OPNR %.*' ..
        'var anyres = g:number + 7.*' ..
        '\d LOADG g:number.*' ..
        '\d PUSHNR 7.*' ..
        '\d OPANY +.*' ..
        '\d STORE $2.*' ..
        'anyres = g:number - 7.*' ..
        '\d OPANY -.*' ..
        'anyres = g:number \* 7.*' ..
        '\d OPANY \*.*' ..
        'anyres = g:number / 7.*' ..
        '\d OPANY /.*' ..
        'anyres = g:number % 7.*' ..
        '\d OPANY %.*',
        instr)
  if has('float')
    assert_match('Computing.*' ..
        'var fl = 3.0.*' ..
        '\d PUSHF 3.0.*' ..
        '\d STORE $3.*' ..
        'var flres = fl + 7.0.*' ..
        '\d LOAD $3.*' ..
        '\d PUSHF 7.0.*' ..
        '\d OPFLOAT +.*' ..
        '\d STORE $4.*' ..
        'flres = fl - 7.0.*' ..
        '\d OPFLOAT -.*' ..
        'flres = fl \* 7.0.*' ..
        '\d OPFLOAT \*.*' ..
        'flres = fl / 7.0.*' ..
        '\d OPFLOAT /.*',
        instr)
  endif
enddef

def AddListBlob()
  var reslist = [1, 2] + [3, 4]
  var resblob = 0z1122 + 0z3344
enddef

def Test_disassemble_add_list_blob()
  var instr = execute('disassemble AddListBlob')
  assert_match('AddListBlob.*' ..
        'var reslist = \[1, 2] + \[3, 4].*' ..
        '\d PUSHNR 1.*' ..
        '\d PUSHNR 2.*' ..
        '\d NEWLIST size 2.*' ..
        '\d PUSHNR 3.*' ..
        '\d PUSHNR 4.*' ..
        '\d NEWLIST size 2.*' ..
        '\d ADDLIST.*' ..
        '\d STORE $.*.*' ..
        'var resblob = 0z1122 + 0z3344.*' ..
        '\d PUSHBLOB 0z1122.*' ..
        '\d PUSHBLOB 0z3344.*' ..
        '\d ADDBLOB.*' ..
        '\d STORE $.*',
        instr)
enddef

let g:aa = 'aa'
def ConcatString(): string
  var res = g:aa .. "bb"
  return res
enddef

def Test_disassemble_concat()
  var instr = execute('disassemble ConcatString')
  assert_match('ConcatString.*' ..
        'var res = g:aa .. "bb".*' ..
        '\d LOADG g:aa.*' ..
        '\d PUSHS "bb".*' ..
        '\d 2STRING_ANY stack\[-2].*' ..
        '\d CONCAT.*' ..
        '\d STORE $.*',
        instr)
  assert_equal('aabb', ConcatString())
enddef

def StringIndex(): string
  var s = "abcd"
  var res = s[1]
  return res
enddef

def Test_disassemble_string_index()
  var instr = execute('disassemble StringIndex')
  assert_match('StringIndex\_s*' ..
        'var s = "abcd"\_s*' ..
        '\d PUSHS "abcd"\_s*' ..
        '\d STORE $0\_s*' ..
        'var res = s\[1]\_s*' ..
        '\d LOAD $0\_s*' ..
        '\d PUSHNR 1\_s*' ..
        '\d STRINDEX\_s*' ..
        '\d STORE $1\_s*',
        instr)
  assert_equal('b', StringIndex())
enddef

def StringSlice(): string
  var s = "abcd"
  var res = s[1:8]
  return res
enddef

def Test_disassemble_string_slice()
  var instr = execute('disassemble StringSlice')
  assert_match('StringSlice\_s*' ..
        'var s = "abcd"\_s*' ..
        '\d PUSHS "abcd"\_s*' ..
        '\d STORE $0\_s*' ..
        'var res = s\[1:8]\_s*' ..
        '\d LOAD $0\_s*' ..
        '\d PUSHNR 1\_s*' ..
        '\d PUSHNR 8\_s*' ..
        '\d STRSLICE\_s*' ..
        '\d STORE $1\_s*',
        instr)
  assert_equal('bcd', StringSlice())
enddef

def ListIndex(): number
  var l = [1, 2, 3]
  var res = l[1]
  return res
enddef

def Test_disassemble_list_index()
  var instr = execute('disassemble ListIndex')
  assert_match('ListIndex\_s*' ..
        'var l = \[1, 2, 3]\_s*' ..
        '\d PUSHNR 1\_s*' ..
        '\d PUSHNR 2\_s*' ..
        '\d PUSHNR 3\_s*' ..
        '\d NEWLIST size 3\_s*' ..
        '\d STORE $0\_s*' ..
        'var res = l\[1]\_s*' ..
        '\d LOAD $0\_s*' ..
        '\d PUSHNR 1\_s*' ..
        '\d LISTINDEX\_s*' ..
        '\d STORE $1\_s*',
        instr)
  assert_equal(2, ListIndex())
enddef

def ListSlice(): list<number>
  var l = [1, 2, 3]
  var res = l[1:8]
  return res
enddef

def Test_disassemble_list_slice()
  var instr = execute('disassemble ListSlice')
  assert_match('ListSlice\_s*' ..
        'var l = \[1, 2, 3]\_s*' ..
        '\d PUSHNR 1\_s*' ..
        '\d PUSHNR 2\_s*' ..
        '\d PUSHNR 3\_s*' ..
        '\d NEWLIST size 3\_s*' ..
        '\d STORE $0\_s*' ..
        'var res = l\[1:8]\_s*' ..
        '\d LOAD $0\_s*' ..
        '\d PUSHNR 1\_s*' ..
        '\d PUSHNR 8\_s*' ..
        '\d LISTSLICE\_s*' ..
        '\d STORE $1\_s*',
        instr)
  assert_equal([2, 3], ListSlice())
enddef

def DictMember(): number
  var d = #{item: 1}
  var res = d.item
  res = d["item"]
  return res
enddef

def Test_disassemble_dict_member()
  var instr = execute('disassemble DictMember')
  assert_match('DictMember\_s*' ..
        'var d = #{item: 1}\_s*' ..
        '\d PUSHS "item"\_s*' ..
        '\d PUSHNR 1\_s*' ..
        '\d NEWDICT size 1\_s*' ..
        '\d STORE $0\_s*' ..
        'var res = d.item\_s*' ..
        '\d\+ LOAD $0\_s*' ..
        '\d\+ MEMBER item\_s*' ..
        '\d\+ STORE $1\_s*' ..
        'res = d\["item"\]\_s*' ..
        '\d\+ LOAD $0\_s*' ..
        '\d\+ PUSHS "item"\_s*' ..
        '\d\+ MEMBER\_s*' ..
        '\d\+ STORE $1\_s*',
        instr)
  assert_equal(1, DictMember())
enddef

let somelist = [1, 2, 3, 4, 5]
def AnyIndex(): number
  var res = g:somelist[2]
  return res
enddef

def Test_disassemble_any_index()
  var instr = execute('disassemble AnyIndex')
  assert_match('AnyIndex\_s*' ..
        'var res = g:somelist\[2\]\_s*' ..
        '\d LOADG g:somelist\_s*' ..
        '\d PUSHNR 2\_s*' ..
        '\d ANYINDEX\_s*' ..
        '\d STORE $0\_s*' ..
        'return res\_s*' ..
        '\d LOAD $0\_s*' ..
        '\d CHECKTYPE number stack\[-1\]\_s*' ..
        '\d RETURN',
        instr)
  assert_equal(3, AnyIndex())
enddef

def AnySlice(): list<number>
  var res = g:somelist[1:3]
  return res
enddef

def Test_disassemble_any_slice()
  var instr = execute('disassemble AnySlice')
  assert_match('AnySlice\_s*' ..
        'var res = g:somelist\[1:3\]\_s*' ..
        '\d LOADG g:somelist\_s*' ..
        '\d PUSHNR 1\_s*' ..
        '\d PUSHNR 3\_s*' ..
        '\d ANYSLICE\_s*' ..
        '\d STORE $0\_s*' ..
        'return res\_s*' ..
        '\d LOAD $0\_s*' ..
        '\d CHECKTYPE list<number> stack\[-1\]\_s*' ..
        '\d RETURN',
        instr)
  assert_equal([2, 3, 4], AnySlice())
enddef

def NegateNumber(): number
  var nr = 9
  var plus = +nr
  var res = -nr
  return res
enddef

def Test_disassemble_negate_number()
  var instr = execute('disassemble NegateNumber')
  assert_match('NegateNumber\_s*' ..
        'var nr = 9\_s*' ..
        '\d STORE 9 in $0\_s*' ..
        'var plus = +nr\_s*' ..
        '\d LOAD $0\_s*' ..
        '\d CHECKNR\_s*' ..
        '\d STORE $1\_s*' ..
        'var res = -nr\_s*' ..
        '\d LOAD $0\_s*' ..
        '\d NEGATENR\_s*' ..
        '\d STORE $2\_s*',
        instr)
  assert_equal(-9, NegateNumber())
enddef

def InvertBool(): bool
  var flag = true
  var invert = !flag
  var res = !!flag
  return res
enddef

def Test_disassemble_invert_bool()
  var instr = execute('disassemble InvertBool')
  assert_match('InvertBool\_s*' ..
        'var flag = true\_s*' ..
        '\d PUSH v:true\_s*' ..
        '\d STORE $0\_s*' ..
        'var invert = !flag\_s*' ..
        '\d LOAD $0\_s*' ..
        '\d INVERT (!val)\_s*' ..
        '\d STORE $1\_s*' ..
        'var res = !!flag\_s*' ..
        '\d LOAD $0\_s*' ..
        '\d 2BOOL (!!val)\_s*' ..
        '\d STORE $2\_s*',
        instr)
  assert_equal(true, InvertBool())
enddef

def ReturnBool(): bool
  var name: bool = 1 && 0 || 1
  return name
enddef

def Test_disassemble_return_bool()
  var instr = execute('disassemble ReturnBool')
  assert_match('ReturnBool\_s*' ..
        'var name: bool = 1 && 0 || 1\_s*' ..
        '0 PUSHNR 1\_s*' ..
        '1 JUMP_IF_COND_FALSE -> 3\_s*' ..
        '2 PUSHNR 0\_s*' ..
        '3 COND2BOOL\_s*' ..
        '4 JUMP_IF_COND_TRUE -> 6\_s*' ..
        '5 PUSHNR 1\_s*' ..
        '6 2BOOL (!!val)\_s*' ..
        '\d STORE $0\_s*' ..
        'return name\_s*' ..
        '\d LOAD $0\_s*' ..   
        '\d RETURN',
        instr)
  assert_equal(true, InvertBool())
enddef

def Test_disassemble_compare()
  var cases = [
        ['true == isFalse', 'COMPAREBOOL =='],
        ['true != isFalse', 'COMPAREBOOL !='],
        ['v:none == isNull', 'COMPARESPECIAL =='],
        ['v:none != isNull', 'COMPARESPECIAL !='],

        ['111 == aNumber', 'COMPARENR =='],
        ['111 != aNumber', 'COMPARENR !='],
        ['111 > aNumber', 'COMPARENR >'],
        ['111 < aNumber', 'COMPARENR <'],
        ['111 >= aNumber', 'COMPARENR >='],
        ['111 <= aNumber', 'COMPARENR <='],
        ['111 =~ aNumber', 'COMPARENR =\~'],
        ['111 !~ aNumber', 'COMPARENR !\~'],

        ['"xx" != aString', 'COMPARESTRING !='],
        ['"xx" > aString', 'COMPARESTRING >'],
        ['"xx" < aString', 'COMPARESTRING <'],
        ['"xx" >= aString', 'COMPARESTRING >='],
        ['"xx" <= aString', 'COMPARESTRING <='],
        ['"xx" =~ aString', 'COMPARESTRING =\~'],
        ['"xx" !~ aString', 'COMPARESTRING !\~'],
        ['"xx" is aString', 'COMPARESTRING is'],
        ['"xx" isnot aString', 'COMPARESTRING isnot'],

        ['0z11 == aBlob', 'COMPAREBLOB =='],
        ['0z11 != aBlob', 'COMPAREBLOB !='],
        ['0z11 is aBlob', 'COMPAREBLOB is'],
        ['0z11 isnot aBlob', 'COMPAREBLOB isnot'],

        ['[1, 2] == aList', 'COMPARELIST =='],
        ['[1, 2] != aList', 'COMPARELIST !='],
        ['[1, 2] is aList', 'COMPARELIST is'],
        ['[1, 2] isnot aList', 'COMPARELIST isnot'],

        ['#{a: 1} == aDict', 'COMPAREDICT =='],
        ['#{a: 1} != aDict', 'COMPAREDICT !='],
        ['#{a: 1} is aDict', 'COMPAREDICT is'],
        ['#{a: 1} isnot aDict', 'COMPAREDICT isnot'],

        ['{->33} == {->44}', 'COMPAREFUNC =='],
        ['{->33} != {->44}', 'COMPAREFUNC !='],
        ['{->33} is {->44}', 'COMPAREFUNC is'],
        ['{->33} isnot {->44}', 'COMPAREFUNC isnot'],

        ['77 == g:xx', 'COMPAREANY =='],
        ['77 != g:xx', 'COMPAREANY !='],
        ['77 > g:xx', 'COMPAREANY >'],
        ['77 < g:xx', 'COMPAREANY <'],
        ['77 >= g:xx', 'COMPAREANY >='],
        ['77 <= g:xx', 'COMPAREANY <='],
        ['77 =~ g:xx', 'COMPAREANY =\~'],
        ['77 !~ g:xx', 'COMPAREANY !\~'],
        ['77 is g:xx', 'COMPAREANY is'],
        ['77 isnot g:xx', 'COMPAREANY isnot'],
        ]
  var floatDecl = ''
  if has('float')
    cases->extend([
        ['1.1 == aFloat', 'COMPAREFLOAT =='],
        ['1.1 != aFloat', 'COMPAREFLOAT !='],
        ['1.1 > aFloat', 'COMPAREFLOAT >'],
        ['1.1 < aFloat', 'COMPAREFLOAT <'],
        ['1.1 >= aFloat', 'COMPAREFLOAT >='],
        ['1.1 <= aFloat', 'COMPAREFLOAT <='],
        ['1.1 =~ aFloat', 'COMPAREFLOAT =\~'],
        ['1.1 !~ aFloat', 'COMPAREFLOAT !\~'],
        ])
    floatDecl = 'var aFloat = 2.2'
  endif

  var nr = 1
  for case in cases
    # declare local variables to get a non-constant with the right type
    writefile(['def TestCase' .. nr .. '()',
             '  var isFalse = false',
             '  var isNull = v:null',
             '  var aNumber = 222',
             '  var aString = "yy"',
             '  var aBlob = 0z22',
             '  var aList = [3, 4]',
             '  var aDict = #{x: 2}',
             floatDecl,
             '  if ' .. case[0],
             '    echo 42'
             '  endif',
             'enddef'], 'Xdisassemble')
    source Xdisassemble
    var instr = execute('disassemble TestCase' .. nr)
    assert_match('TestCase' .. nr .. '.*' ..
        'if ' .. substitute(case[0], '[[~]', '\\\0', 'g') .. '.*' ..
        '\d \(PUSH\|FUNCREF\).*' ..
        '\d \(PUSH\|FUNCREF\|LOAD\).*' ..
        '\d ' .. case[1] .. '.*' ..
        '\d JUMP_IF_FALSE -> \d\+.*',
        instr)

    nr += 1
  endfor

  delete('Xdisassemble')
enddef

def s:FalsyOp()
  echo g:flag ?? "yes"
  echo [] ?? "empty list"
  echo "" ?? "empty string"
enddef

def Test_dsassemble_falsy_op()
  var res = execute('disass s:FalsyOp')
  assert_match('\<SNR>\d*_FalsyOp\_s*' ..
      'echo g:flag ?? "yes"\_s*' ..
      '0 LOADG g:flag\_s*' ..
      '1 JUMP_AND_KEEP_IF_TRUE -> 3\_s*' ..
      '2 PUSHS "yes"\_s*' ..
      '3 ECHO 1\_s*' ..
      'echo \[\] ?? "empty list"\_s*' ..
      '4 NEWLIST size 0\_s*' ..
      '5 JUMP_AND_KEEP_IF_TRUE -> 7\_s*' ..
      '6 PUSHS "empty list"\_s*' ..
      '7 ECHO 1\_s*' ..
      'echo "" ?? "empty string"\_s*' ..
      '\d\+ PUSHS "empty string"\_s*' ..
      '\d\+ ECHO 1\_s*' ..
      '\d\+ PUSHNR 0\_s*' ..
      '\d\+ RETURN',
      res)
enddef

def Test_disassemble_compare_const()
  var cases = [
        ['"xx" == "yy"', false],
        ['"aa" == "aa"', true],
        ['has("eval") ? true : false', true],
        ['has("asdf") ? true : false', false],
        ]

  var nr = 1
  for case in cases
    writefile(['def TestCase' .. nr .. '()',
             '  if ' .. case[0],
             '    echo 42'
             '  endif',
             'enddef'], 'Xdisassemble')
    source Xdisassemble
    var instr = execute('disassemble TestCase' .. nr)
    if case[1]
      # condition true, "echo 42" executed
      assert_match('TestCase' .. nr .. '.*' ..
          'if ' .. substitute(case[0], '[[~]', '\\\0', 'g') .. '.*' ..
          '\d PUSHNR 42.*' ..
          '\d ECHO 1.*' ..
          '\d PUSHNR 0.*' ..
          '\d RETURN.*',
          instr)
    else
      # condition false, function just returns
      assert_match('TestCase' .. nr .. '.*' ..
          'if ' .. substitute(case[0], '[[~]', '\\\0', 'g') .. '[ \n]*' ..
          'echo 42[ \n]*' ..
          'endif[ \n]*' ..
          '\s*\d PUSHNR 0.*' ..
          '\d RETURN.*',
          instr)
    endif

    nr += 1
  endfor

  delete('Xdisassemble')
enddef

def s:Execute()
  execute 'help vim9.txt'
  var cmd = 'help vim9.txt'
  execute cmd
  var tag = 'vim9.txt'
  execute 'help ' .. tag
enddef

def Test_disassemble_execute()
  var res = execute('disass s:Execute')
  assert_match('\<SNR>\d*_Execute\_s*' ..
        "execute 'help vim9.txt'\\_s*" ..
        '\d PUSHS "help vim9.txt"\_s*' ..
        '\d EXECUTE 1\_s*' ..
        "var cmd = 'help vim9.txt'\\_s*" ..
        '\d PUSHS "help vim9.txt"\_s*' ..
        '\d STORE $0\_s*' ..
        'execute cmd\_s*' ..
        '\d LOAD $0\_s*' ..
        '\d EXECUTE 1\_s*' ..
        "var tag = 'vim9.txt'\\_s*" ..
        '\d PUSHS "vim9.txt"\_s*' ..
        '\d STORE $1\_s*' ..
        "execute 'help ' .. tag\\_s*" ..
        '\d\+ PUSHS "help "\_s*' ..
        '\d\+ LOAD $1\_s*' ..
        '\d\+ CONCAT\_s*' ..
        '\d\+ EXECUTE 1\_s*' ..
        '\d\+ PUSHNR 0\_s*' ..
        '\d\+ RETURN',
        res)
enddef

def s:Echomsg()
  echomsg 'some' 'message'
  echoerr 'went' .. 'wrong'
enddef

def Test_disassemble_echomsg()
  var res = execute('disass s:Echomsg')
  assert_match('\<SNR>\d*_Echomsg\_s*' ..
        "echomsg 'some' 'message'\\_s*" ..
        '\d PUSHS "some"\_s*' ..
        '\d PUSHS "message"\_s*' ..
        '\d ECHOMSG 2\_s*' ..
        "echoerr 'went' .. 'wrong'\\_s*" ..
        '\d PUSHS "wentwrong"\_s*' ..
        '\d ECHOERR 1\_s*' ..
        '\d PUSHNR 0\_s*' ..
        '\d RETURN',
        res)
enddef

def SomeStringArg(arg: string)
  echo arg
enddef

def SomeAnyArg(arg: any)
  echo arg
enddef

def SomeStringArgAndReturn(arg: string): string
  return arg
enddef

def Test_display_func()
  var res1 = execute('function SomeStringArg')
  assert_match('.* def SomeStringArg(arg: string)\_s*' ..
        '\d *echo arg.*' ..
        ' *enddef',
        res1)

  var res2 = execute('function SomeAnyArg')
  assert_match('.* def SomeAnyArg(arg: any)\_s*' ..
        '\d *echo arg\_s*' ..
        ' *enddef',
        res2)

  var res3 = execute('function SomeStringArgAndReturn')
  assert_match('.* def SomeStringArgAndReturn(arg: string): string\_s*' ..
        '\d *return arg\_s*' ..
        ' *enddef',
        res3)
enddef

def Test_vim9script_forward_func()
  var lines =<< trim END
    vim9script
    def FuncOne(): string
      return FuncTwo()
    enddef
    def FuncTwo(): string
      return 'two'
    enddef
    g:res_FuncOne = execute('disass FuncOne')
  END
  writefile(lines, 'Xdisassemble')
  source Xdisassemble

  # check that the first function calls the second with DCALL
  assert_match('\<SNR>\d*_FuncOne\_s*' ..
        'return FuncTwo()\_s*' ..
        '\d DCALL <SNR>\d\+_FuncTwo(argc 0)\_s*' ..
        '\d RETURN',
        g:res_FuncOne)

  delete('Xdisassemble')
  unlet g:res_FuncOne
enddef

def s:ConcatStrings(): string
  return 'one' .. 'two' .. 'three'
enddef

def s:ComputeConst(): number
  return 2 + 3 * 4 / 6 + 7
enddef

def s:ComputeConstParen(): number
  return ((2 + 4) * (8 / 2)) / (3 + 4)
enddef

def Test_simplify_const_expr()
  var res = execute('disass s:ConcatStrings')
  assert_match('<SNR>\d*_ConcatStrings\_s*' ..
        "return 'one' .. 'two' .. 'three'\\_s*" ..
        '\d PUSHS "onetwothree"\_s*' ..
        '\d RETURN',
        res)

  res = execute('disass s:ComputeConst')
  assert_match('<SNR>\d*_ComputeConst\_s*' ..
        'return 2 + 3 \* 4 / 6 + 7\_s*' ..
        '\d PUSHNR 11\_s*' ..
        '\d RETURN',
        res)

  res = execute('disass s:ComputeConstParen')
  assert_match('<SNR>\d*_ComputeConstParen\_s*' ..
        'return ((2 + 4) \* (8 / 2)) / (3 + 4)\_s*' ..
        '\d PUSHNR 3\>\_s*' ..
        '\d RETURN',
        res)
enddef

def s:CallAppend()
  eval "some text"->append(2)
enddef

def Test_shuffle()
  var res = execute('disass s:CallAppend')
  assert_match('<SNR>\d*_CallAppend\_s*' ..
        'eval "some text"->append(2)\_s*' ..
        '\d PUSHS "some text"\_s*' ..
        '\d PUSHNR 2\_s*' ..
        '\d SHUFFLE 2 up 1\_s*' ..
        '\d BCALL append(argc 2)\_s*' ..
        '\d DROP\_s*' ..
        '\d PUSHNR 0\_s*' ..
        '\d RETURN',
        res)
enddef

" vim: ts=8 sw=2 sts=2 expandtab tw=80 fdm=marker
