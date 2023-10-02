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
|  `-d`  | Specify a home directory other than `$HOME`
|  `-q`  | Quiet mode - suppress output

TODO
----

* Add `-b` to specify remote branch to download files
* Add option to fetch specific files
* Move prompt to this repo
