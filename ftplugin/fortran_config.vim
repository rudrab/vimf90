function! GenSys()
  if filereadable("sys")
    vsp sys
  else
    let lines=["Project\t= #Name of the project and executable", "Exclude\t= #Dirs to exclude in search"]
    let lines+=["FC\t= #Name of the compiler"]
    call writefile(lines, "sys")
    vsplit sys
  endif
endfunction
