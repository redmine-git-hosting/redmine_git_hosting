---
layout: default
title: Bitnami installation
---

### {{ page.title }}
***

As Bitnami override some internal paths needed to build native Ruby extension you must compile libgit2 yourself [**before** installing Redmine Git Hosting]({{ site.baseurl }}/howtos/install).

Here's the steps :

#### **(step 1)** Do some cleanup

    bitnami$ sudo apt-get purge libgit2 libgit2-dev

***

#### **(step 2)** Install dependencies

    bitnami# sudo apt-get install build-essential libssh2-1 libssh2-1-dev cmake libgpg-error-dev

***

#### **(step 3)** Copy libssh2 pkg-config

    bitnami$ sudo cp /usr/lib/x86_64-linux-gnu/pkgconfig/libssh2.pc /opt/bitnami/common/lib/pkgconfig/

***

#### **(step 4)** Clone libgit2 repository and build the lib

    bitnami$ mkdir tmp
    bitnami$ cd tmp
    bitnami$ git clone https://github.com/libgit2/libgit2.git
    bitnami$ cd libgit2
    bitnami$ git checkout v0.21.4
    bitnami$ mkdir build
    bitnami$ cd build
    bitnami$ export PKG_CONFIG_PATH=/opt/bitnami/common/lib/pkgconfig
    bitnami$ cmake .. -DCMAKE_INSTALL_PREFIX=/opt/bitnami/common -DUSE_SSH=true
    bitnami$ sudo cmake --build . --target install

Now you can return to [Plugin install (step 2)]({{ site.baseurl }}/howtos/install/#step-2-clone-the-plugin).
