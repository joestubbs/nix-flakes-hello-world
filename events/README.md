# A Python Script with ZMQ Library

This example provides a Nix flake for building a simple Python script that depends on the ZMQ library. 
We use Poetry to manage the environment and specify dependencies. 

Build the package with

```
nix build
```
This will create a `result` in the directory; execute
the program with

```
./result/bin/zmqtest
```
Nothing is printed, but no errors indicate that zmq was able to be imported. 

The flake also includes a development environment.
You can also build the development environment: 

```
nix build .#myenv
```

You can active the development environment with:

```
nix develop
```
Now you should have a shell with python and zmq all
hooked up: 

```
$ nix develop

nix nix-flakes-hello-world/events ➜ python
Python 3.10.9 (main, Dec  6 2022, 18:44:57) [GCC 12.2.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> import zmq
>>> 
```


## Using Poetry and poetry2nix
For example, create the project:
```
poetry init
```

Add the `zmq` library:

```
poetry add zmq
```

Then we use `poetry2nix` to write a Nix flake to build the package. Note that `poetry2nix` requires
a proper poetry package structure -- see the 
```
[tool.poetry.scripts]
zmqtest = 'zmqtest.app:main'
```
in the `pyproject.toml` file. 

