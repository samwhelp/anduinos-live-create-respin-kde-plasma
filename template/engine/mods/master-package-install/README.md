

# master-package-install




## Subject

* [Description](#description)




## Description

> This module is executed in the chroot environment.

The files in the [asset/package/install](asset/package/install) folder record the packages we want to install.

In practice, the list of packages to be installed is stored in the variable `package_install_list`.

Then execute the following instructions.

``` sh
apt install -y --no-install-recommends $package_install_list
```

For example, executing instructions like the following

``` sh
apt install -y --no-install-recommends gnome-tweaks nano micro vim neovim
```




## Folder: `asset/package/install`

The files in the [asset/package/install](asset/package/install) folder have the file extension `.txt`.

Each file contains a list of packages to be installed.

Each line in the file means the name of the package to be installed.

We can use `#` at the beginning of each line as a comment.
