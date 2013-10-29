function mg_acosh_ut::test1
  compile_opt strictarr

  result = mg_acosh(1)
  assert, result eq 0., 'incorrect result: %d', result

  return, 1
end


function mg_acosh_ut::test2
  compile_opt strictarr

  result = mg_acosh(2)
  assert, result eq alog(2 + sqrt(3)), 'incorrect result: %d', result

  return, 1
end


pro mg_acosh_ut__define
  compile_opt strictarr

  define = { mg_acosh_ut, inherits MGutLibTestCase }
end