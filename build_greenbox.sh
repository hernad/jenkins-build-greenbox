#!/bin/bash

uname -a

PROXY=`docker inspect --format '{{ .State.Status }}' apt-cacher-ng`

if [ X$PROXY != Xrunning ] ; then
   ./run_proxy.sh
fi

git clone https://github.com/hernad/greenbox.git

cp bintray_api_key/greenbox

cd greenbox
git checkout apps_modular -f
git pull
./build.sh greenbox 


echo "this image is going to be base for apps"

docker tag greenbox greenbox:for_apps
docker images | grep greenbox


echo "building docker apps image"
./build.sh docker green

APP=docker
VER=`cat DOCKER_VERSION`
echo "build and upload to bintray docker_$VER.tar.xz"
rm -rf $APP
./upload_app.sh $APP $VER J


APP=green
VER=`cat apps/green/VERSION`
echo "build and upload to bintray green_$VER.tar.xz"
rm -rf $APP
./upload_app.sh $APP $VER  J


VER=`cat VBOX_VERSION`
APP=VirtualBox
./upload_app.sh $APP ${VER} J  #.tar.xz


rm bintray_api_key

echo == jenkins build greenbox end ==
