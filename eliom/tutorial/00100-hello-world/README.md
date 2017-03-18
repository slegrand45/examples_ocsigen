# Hello world!


## What you will learn

  In this first tutorial, we will see how to build this classical example. The goal is simply to display "Hello world!" on a web page.


## Prerequisites

  In order to complete this tutorial, you need to install at a bare minimum:

  - [The OCaml language](http://www.ocaml.org/docs/install.html)
  - The OCaml package manager [OPAM](https://opam.ocaml.org/doc/Install.html)

  This tutorial has been tested with OCaml version 4.03.0. So i would recommend to install this version or a greater one.


## Install Eliom

  The easiest way to install Eliom and all its dependencies is to use OPAM:

```
  $ opam install eliom
```

  This tutorial has been tested with Eliom version 6.2.0. So i would recommend to install this version or a greater one.


## Create the project

  Now that everything needed is installed, we can create our first project. Eliom provides a shell command named `eliom-distillery` in order to initialize a new project:

```
  $ eliom-distillery -name mysite -template basic.ppx
```

  This command creates a new project named `mysite`. The project directory is populated with some files coming from the predefined template named `basic.ppx`:

```
  $ cd mysite/
  $ ls
  Makefile  Makefile.options  mysite.conf.in  mysite.eliom  README  static
```


## First test

  To test the application, we can run the Eliom server in test mode. You can use one of these commands:

```
  $ make test.byte
```

  or

```
  $ make test.opt
```

  The first command will compile the server in bytecode mode whereas the second one will compile the server in native executable mode.

  After the compilation, the Eliom server is automatically launched and ready to answer to client requests. Open your web browser and go to [http://localhost:8080/](http://localhost:8080/). You should see "Welcome from Eliom's distillery!".


## Modify the message

  Now we want to display our own message and say hello to the world. To change the default text, we need to edit the main source code file. By default, its name is the project name with the `.eliom` extension. So open the file named `mysite.eliom` with a text editor, change the text "Welcome from Eliom's distillery!" to "Hello world!" and save the file.

  Then we have to rebuild the application to take into account the change. If needed, stop the current server with `Ctrl+C`. Then rerun either `make test.byte` or `make test.opt`. Refresh the web page [http://localhost:8080/](http://localhost:8080/), you should now see "Hello world!".

  Congratulations, you have made your first Eliom application!
  

## Next step

  In the [next tutorial](../00200-static-table/), we will see how to create a much more interesting web page.
