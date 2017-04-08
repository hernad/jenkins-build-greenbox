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

echo getting bintray_api_key from jenkins home
mv ../bintray_api_key .

./build.sh greenbox 

./create_greenbox_iso.sh
echo moving iso to jenkins home
mv greenbox*.iso ..

echo "this image is going to be base for apps"

docker tag greenbox greenbox:for_apps
docker images | grep greenbox


echo "building docker apps image"
./build.sh docker
if [ $? != 0 ] ; then
   echo "build docker ERROR"
   exit 1
fi

./build.sh green
if [ $? != 0 ] ; then
   echo "build green ERROR"
   exit 1
fi


APP=docker
VER=`cat DOCKER_VERSION`
echo "build and upload to bintray docker_$VER.tar.xz"
rm -rf $APP
./upload_app.sh $APP $VER J
if [ $? != 0 ] ; then
   echo "upload $APP ERROR"
   exit 1
fi


APP=green
VER=`cat apps/green/VERSION`
echo "build and upload to bintray green_$VER.tar.xz"
rm -rf $APP
./upload_app.sh $APP $VER  J
if [ $? != 0 ] ; then
   echo "upload $APP ERROR"
   exit 1
fi


VER=`cat VBOX_VERSION`
APP=VirtualBox
./upload_app.sh $APP ${VER} J  #.tar.xz
if [ $? != 0 ] ; then
   echo "upload $APP ERROR"
   exit 1
fi



rm bintray_api_key

echo == jenkins build greenbox end ==
