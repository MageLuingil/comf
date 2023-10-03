comf
====

A collection of personal config files to quickly set up a comfy linux home environment.

Setup
-----

```
curl -o- https://raw.githubusercontent.com/MageLuingil/comf/main/setup.sh | bash
```
or
```
wget -qO- https://raw.githubusercontent.com/MageLuingil/comf/main/setup.sh | bash
```

Options
-------

To run the script with additional args:

```
curl -o- https://raw.githubusercontent.com/MageLuingil/comf/main/setup.sh | bash -s -- [OPTIONS]
```

Available options:

| Option |   |
| ------ | - |
|  `-b`  | Use a remote branch to download from other than `main`
|  `-d`  | Specify a home directory other than `$HOME`
|  `-f`  | Only download the specified file, nothing else
|  `-q`  | Quiet mode - suppress output

TODO
----

* Move prompt to this repo
