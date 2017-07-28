Playing around with "user defined types" in Fortran.

Some related references:

- [Examples][1]
- StackOverflow [question][2] about user-defined types
- (Lack of) support [in `f2py`][3] (and possible workaround [`f90wrap`][4])

When trying to convert a Fortran subroutine to Python via `f2py`, a
problem occurs if the subroutine uses a user-defined type:

```
$ make fortran_example.so
...
Skipping type userdefined
                        Constructing wrapper function "example.foo"...
                          quux = foo(bar,baz)
                        Constructing wrapper function "example.make_udf"...
getctype: No C-type found in "{'attrspec': [], 'typename': 'userdefined', 'intent': ['out'], 'typespec': 'type'}", assuming void.
getctype: No C-type found in "{'attrspec': [], 'typename': 'userdefined', 'intent': ['out'], 'typespec': 'type'}", assuming void.
getctype: No C-type found in "{'attrspec': [], 'typename': 'userdefined', 'intent': ['out'], 'typespec': 'type'}", assuming void.
Traceback (most recent call last):
...
  File ".../numpy/f2py/capi_maps.py", line 412, in getpydocsign
    sig = '%s : %s %s%s' % (a, opt, c2py_map[ctype], init)
KeyError: 'void'
Makefile:7: recipe for target 'fortran_example.so' failed
make: *** [fortran_example.so] Error 1
```

Decently [helpful article][5] and ["pre-article"][6] to that one.

## Doing Everything

Run the exact same Fortran code in five different ways:

```
$ make main > /dev/null; ./main; make clean > /dev/null
 foo(   1.0000000000000000        16.000000000000000      ) =    61.000000000000000
 make_udf(   1.2500000000000000        5.0000000000000000             1337 )
        =    1.2500000000000000        5.0000000000000000             1337
 foo_array(
                4 ,
     [[   3.0000000000000000        4.5000000000000000      ],
      [   1.0000000000000000        1.2500000000000000      ],
      [   9.0000000000000000        0.0000000000000000      ],
      [  -1.0000000000000000        4.0000000000000000      ]],
 ) =
     [[   6.0000000000000000        9.0000000000000000      ],
      [   2.0000000000000000        2.5000000000000000      ],
      [   18.000000000000000        0.0000000000000000      ],
      [  -2.0000000000000000        8.0000000000000000      ]]
$ make main_c > /dev/null; ./main_c; make clean > /dev/null
quux = foo(1.000000, 16.000000) = 61.000000
quuz = make_udf(1.250000, 5.000000, 1337) = UserDefined(1.250000, 5.000000, 1337)
foo_array(
    4,
    [[3.000000, 4.500000],
     [1.000000, 1.250000],
     [9.000000, 0.000000],
     [-1.000000, 4.000000]],
) =
    [[6.000000, 9.000000],
     [2.000000, 2.500000],
     [18.000000, 0.000000],
     [-2.000000, 8.000000]]
made_it_ptr = 0x7ffd3c9a3d30
made_it_ptr = 140725620194608
made_it = UserDefined(3.125000, -10.500000, 101)
$ make example.so > /dev/null; python check_ctypes.py; make clean > /dev/null
<CDLL '.../example.so', handle 16e1440 at 7f2491f75350>
quux = foo(c_double(1.0), c_double(16.0)) = c_double(61.0)
quuz = make_udf(c_double(1.25), c_double(5.0), c_int(1337)) = UserDefined(buzz=1.25, broken=5.0, how_many=1337)
address(quuz) = 43429856
*address(quuz) = UserDefined(buzz=1.25, broken=5.0, how_many=1337)
val =
[[ 3.    4.5 ]
 [ 1.    1.25]
 [ 9.    0.  ]
 [-1.    4.  ]]
two_val = foo_array(c_int(4), val)
two_val =
[[  6.    9. ]
 [  2.    2.5]
 [ 18.    0. ]
 [ -2.    8. ]]
made_it_ptr: <__main__.LP_UserDefined object at 0x7f2b77ee4560>
address: 140731938143600
made_it: UserDefined(buzz=1.97626258336e-323, broken=2.15683764813e-317, how_many=2012013104)
*address = UserDefined(buzz=1.97626258336e-323, broken=2.15683764813e-317, how_many=2012013104)
$ make fortran_example.so > /dev/null; python check_fortran_extension.py; make clean > /dev/null
fortran_example: <module 'fortran_example' from '.../fortran_example.so'>
fortran_example.example: <fortran object>
dir(fortran_example.example): ['foo', 'foo_array', 'foo_not_c']
fortran_example.example.foo      (1.0, 16.0) = 0.0
fortran_example.example.foo_not_c(1.0, 16.0) = 61.0
val =
[[ 3.    4.5 ]
 [ 1.    1.25]
 [ 9.    0.  ]
 [-1.    4.  ]]
two_val = fortran_example.example.foo_array(val, 4)
two_val =
[[  6.    9. ]
 [  2.    2.5]
 [ 18.    0. ]
 [ -2.    8. ]]

$ make cy_example.so > /dev/null 2>&1; python check_cython.py; make clean > /dev/null
quux = foo(1.0, 16.0) = 61.0
quuz = make_udf_(1.25, 5.0, 1337) = {'broken': 5.0, 'how_many': 1337, 'buzz': 1.25}
val =
[[ 3.    4.5 ]
 [ 1.    1.25]
 [ 9.    0.  ]
 [-1.    4.  ]]
two_val = foo_array_(val)
two_val =
[[  6.    9. ]
 [  2.    2.5]
 [ 18.    0. ]
 [ -2.    8. ]]
```

[1]: http://www.mathcs.emory.edu/~cheung/Courses/561/Syllabus/6-Fortran/struct.html
[2]: https://stackoverflow.com/q/8557244
[3]: https://mail.scipy.org/pipermail/scipy-user/2008-December/018881.html
[4]: https://github.com/jameskermode/f90wrap
[5]: https://maurow.bitbucket.io/notes/calling_fortran_from_python.html
[6]: https://maurow.bitbucket.io/notes/calling_fortran_from_c.html
