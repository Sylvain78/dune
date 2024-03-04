Most tests have two versions: one where the variable is used inside a dune file,
and one where the same variables are used in the command line.

  $ export DUNE_SANDBOX=symlink

We begin with a that tries to build several modules defined in the current
directory.

- a belongs to a wrapped library
- b belongs to an executable
- c belongs to an unwrapped library
- d belongs to a wrapped library (transition mode) : in this case, both the
prefixed and unprefixed modules are built.

  $ dune clean
  $ dune build --display short @t1
      ocamldep .a1.objs/a1__A.impl.d
        ocamlc .b.eobjs/byte/dune__exe__B.{cmi,cmo,cmt}
        ocamlc .c1.objs/byte/c.{cmi,cmo,cmt}
      ocamldep .c2.objs/c2__D.impl.d
        ocamlc .a1.objs/byte/a1.{cmi,cmo,cmt}
        ocamlc .c2.objs/byte/c2.{cmi,cmo,cmt}
        ocamlc .a1.objs/byte/a1__A.{cmi,cmo,cmt}
        ocamlc .c2.objs/byte/c2__D.{cmi,cmo,cmt}

Command line version.

  $ dune build --verbose %{cmo:a} %{cmo:b} %{cmo:c} 2>&1 | grep -A100 'Actual targets'
  Actual targets:
  - _build/default/.a1.objs/byte/a1__A.cmo
  - _build/default/.b.eobjs/byte/dune__exe__B.cmo
  - _build/default/.c1.objs/byte/c.cmo

The next test tries to build a .cmi file (of a module in a wrapped library).

  $ dune clean
  $ dune build --display short @t2
      ocamldep .a1.objs/a1__A.impl.d
        ocamlc .a1.objs/byte/a1.{cmi,cmo,cmt}
        ocamlc .a1.objs/byte/a1__A.{cmi,cmo,cmt}

Command line version.

  $ dune build --verbose %{cmi:a} 2>&1 | grep -A100 'Actual targets'
  Actual targets:
  - _build/default/.a1.objs/byte/a1__A.cmi

Command line version; note that the error message is slightly different.

  $ dune build %{cmo:xxxx}
  File "command line", line 1, characters 0-11:
  Error: Module Xxxx does not exist.
  [1]

The next test builds a native .cmxa.

  $ dune clean
  $ dune build --display short @t4
        ocamlc .a1.objs/byte/a1.{cmi,cmo,cmt}
      ocamldep .a1.objs/a1__A.impl.d
      ocamlopt .a1.objs/native/a1.{cmx,o}
        ocamlc .a1.objs/byte/a1__A.{cmi,cmo,cmt}
      ocamlopt .a1.objs/native/a1__A.{cmx,o}
      ocamlopt a1.{a,cmxa}

Command line version.

  $ dune build --verbose %{cmxa:a1} 2>&1 | grep -A100 'Actual targets'
  Actual targets:
  - _build/default/a1.cmxa

Command line version.

  $ dune build %{cma:bar_}
  File "command line", line 1, characters 0-11:
  Error: Library bar_ does not exist.
  [1]

This test tries to build a .cma in a subdirectory, where a different project is
defined. The library is public in this case, but we use the local name.

  $ dune clean
  $ dune build --display short @t6
        ocamlc sub2/.bar2.objs/byte/bar2.{cmi,cmo,cmt}
      ocamldep sub2/.bar2.objs/bar2__Y2.impl.d
        ocamlc sub2/.bar2.objs/byte/bar2__Y2.{cmi,cmo,cmt}
        ocamlc sub2/bar2.cma

Command line version.

  $ dune build --verbose %{cma:sub2/bar2} 2>&1 | grep -A100 'Actual targets'
  Actual targets:
  - _build/default/sub2/bar2.cma

This test builds a .cmo in a subdirectory (same project).

  $ dune clean
  $ dune build --display short @t7
      ocamldep sub/.bar.objs/bar__X.impl.d
        ocamlc sub/.bar.objs/byte/bar.{cmi,cmo,cmt}
        ocamlc sub/.bar.objs/byte/bar__X.{cmi,cmo,cmt}

Command line version.

  $ dune build --verbose %{cmo:sub/x} 2>&1 | grep -A100 'Actual targets'
  Actual targets:
  - _build/default/sub/.bar.objs/byte/bar__X.cmo

This test builds a module in a subdirectory (different project) belonging to a
private library.

  $ dune clean
  $ dune build --display short @t8
      ocamldep sub3/.c1.objs/c1__X.impl.d
        ocamlc sub3/.c1.objs/byte/c1.{cmi,cmo,cmt}
        ocamlc sub3/.c1.objs/byte/c1__X.{cmi,cmo,cmt}

COmmand line version.

  $ dune build --verbose %{cmo:sub3/x} 2>&1 | grep -A100 'Actual targets'
  Actual targets:
  - _build/default/sub3/.c1.objs/byte/c1__X.cmo

This test builds a private library in a subdirectory belonging to a different
project.

  $ dune clean
  $ dune build --display short @t9
        ocamlc sub3/.c1.objs/byte/c1.{cmi,cmo,cmt}
      ocamldep sub3/.c1.objs/c1__X.impl.d
        ocamlc sub3/.c1.objs/byte/c1__X.{cmi,cmo,cmt}
        ocamlc sub3/c1.cma

Command line version.

  $ dune build --verbose %{cma:sub3/c1} 2>&1 | grep -A100 'Actual targets'
  Actual targets:
  - _build/default/sub3/c1.cma

This test builds a library in the current directory that has the same name as a
public library defined in a subdirectory.

  $ dune clean
  $ dune build --display short @t10
        ocamlc .c1.objs/byte/c.{cmi,cmo,cmt}
        ocamlc c1.cma

Command line version.

  $ dune build --verbose %{cma:c1} 2>&1 | grep -A100 'Actual targets'
  Actual targets:
  - _build/default/c1.cma

This test checks error handling.

  $ dune build %{cma:../x}
  File "command line", line 1, characters 0-11:
  Error: cannot escape the workspace root directory
  [1]
  $ dune build %{cma:../../x}
  Error: path outside the workspace: ../../x from default
  -> required by %{cma:../../x} at command line:1
  [1]

This test checks that everything still works if we invoke dune from a
subdirectory.

  $ (cd sub && dune build --display short %{cmx:x})
      ocamldep .bar.objs/bar__X.impl.d
        ocamlc .bar.objs/byte/bar.{cmi,cmo,cmt}
        ocamlc .bar.objs/byte/bar__X.{cmi,cmo,cmt}
      ocamlopt .bar.objs/native/bar__X.{cmx,o}

The following test checks that the variables can be used in the (action) field
of a (rule).

  $ dune build --display short _build/default/my.cmxs
        ocamlc .plugin.objs/byte/plugin.{cmi,cmo,cmt}
      ocamldep .plugin.objs/plugin__X1.impl.d
      ocamldep .plugin.objs/plugin__X2.impl.d
      ocamldep .dummy.objs/dummy__X3.impl.d
      ocamlopt .plugin.objs/native/plugin.{cmx,o}
        ocamlc .plugin.objs/byte/plugin__X1.{cmi,cmo,cmt}
        ocamlc .plugin.objs/byte/plugin__X2.{cmi,cmo,cmt}
        ocamlc .dummy.objs/byte/dummy.{cmi,cmo,cmt}
      ocamlopt .plugin.objs/native/plugin__X1.{cmx,o}
      ocamlopt .plugin.objs/native/plugin__X2.{cmx,o}
        ocamlc .dummy.objs/byte/dummy__X3.{cmi,cmo,cmt}
      ocamlopt plugin.{a,cmxa}
      ocamlopt .dummy.objs/native/dummy__X3.{cmx,o}
      ocamlopt my.cmxs