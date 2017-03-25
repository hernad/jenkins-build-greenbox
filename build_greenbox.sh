#!/bin/bash

uname -a

PROXY=`docker inspect --format '{{ .State.Status }}' apt-cacher-ng`

if [ X$PROXY != Xrunning ] ; then
   ./run_proxy.sh
fi

git clone https://github.com/hernad/greenbox.git

cd greenbox
git checkout apps_modular -f
git pull
./build.sh greenbox 


echo "this image is going to be base for apps"

docker tag greenbox greenbox:for_apps
docker images | grep greenbox


echo "building docker apps image"
./build.sh docker

echo 0fb3d0dbf74aa18783a95ccd2dc05c24b94633662b55194d7b16e665a4ed3f51 > bintray_api_key

echo "build docker_xyz.tar.xz"
APP=docker
VER=`cat DOCKER_VERSION`
rm -rf $APP
./upload_app.sh $APP $VER J


echo "build green_xyz.tar.xz"
APP=green
VER=`cat apps/green/VERSION`
rm -rf $APP
./upload_app.sh $APP $VER  J


VER=`cat VBOX_VERSION`
APP=VirtualBox
./upload_app.sh $APP ${VER} J  #.tar.xz

rm bintray_api_key


echo == jenkins build greenbox end ==
