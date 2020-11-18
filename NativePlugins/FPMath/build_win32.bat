@echo off
set _wp_class=FPMath
set _wp_src=.\src\%_wp_class%.c
set _wp_obj=.\obj\%_wp_class%.obj
set _wp_dll=..\..\GWP\bin\%_wp_class%\Lib%_wp_class%.dll
set _wp_lib=..\..\GWP\bin\%_wp_class%\Lib%_wp_class%.lib
set _wp_godot_headers=..\godot_headers

call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars32.bat"

cl /Fo"%_wp_obj%" /c "%_wp_src%" /nologo -EHsc -DNDEBUG /MD /I"." /I"%_wp_godot_headers%"
link /nologo /dll /out:"%_wp_dll%" /implib:"%_wp_lib%" "%_wp_obj%"

pause

