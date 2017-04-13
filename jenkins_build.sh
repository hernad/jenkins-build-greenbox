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
git log -1

echo getting bintray_api_key from jenkins home
mv ../bintray_api_key .

./build.sh greenbox
if [ $? != 0 ] ; then
   echo "greenbox iso build ERROR!"
   exit 1
fi

./create_greenbox_iso.sh
echo moving iso to jenkins home
cp GREENBOX_VERSION ..
cp greenbox.iso ../greenbox-$(cat GREENBOX_VERSION).iso

echo "this image is going to be base for apps"

docker tag greenbox greenbox:for_apps
docker images greenbox

APP=docker
VER=`cat DOCKER_VERSION`
./bintray_check_is_app_exists.sh $APP $VER

if [ $? != 0 ] ; then

   echo "building docker apps image"
   ./build.sh docker
   if [ $? != 0 ] ; then
   echo "build docker ERROR"
      exit 1
  fi
  echo "build and upload to bintray docker_$VER.tar.xz"
  rm -rf $APP
  ./upload_app.sh $APP $VER J
  ./bintray_check_is_app_exists.sh $APP $VER
  if [ $? != 0 ] ; then
    echo "upload $APP ERROR"
    exit 1
  fi

else
  echo "$APP / $VER exits"
fi

APP=green
VER=`cat apps/green/VERSION`
./bintray_check_is_app_exists.sh $APP $VER

if [ $? != 0 ] ; then

  ./build.sh green
  if [ $? != 0 ] ; then
      echo "build green ERROR"
      exit 1
  fi

  echo "build and upload to bintray green_$VER.tar.xz"
  rm -rf $APP
  ./upload_app.sh $APP $VER  J
  ./bintray_check_is_app_exists.sh $APP $VER
  if [ $? != 0 ] ; then
     echo "upload $APP ERROR"
     exit 1
  fi

else
  echo "$APP / $VER exits"
fi


VER=`cat VBOX_VERSION`
APP=VirtualBox
./bintray_check_is_app_exists.sh $APP $VER

if [ $? != 0 ] ; then
  ./upload_app.sh $APP ${VER} J  #.tar.xz
  ./bintray_check_is_app_exists.sh $APP $VER
  if [ $? != 0 ] ; then
     echo "upload $APP ERROR"
     exit 1
  fi
else
  echo "$APP / $VER exits"
fi


rm bintray_api_key
