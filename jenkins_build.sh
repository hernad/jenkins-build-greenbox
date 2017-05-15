#!/bin/bash

uname -a

[ -d greenbox ] || git clone https://github.com/hernad/greenbox.git


function build_app() {

APP=$1
VER=`cat apps/$APP/VERSION`
./bintray_check_is_app_exists.sh $APP $VER

if [ $? != 0 ] ; then

  echo === building $APP / $VER ==============
  ./build.sh $APP
  if [ $? != 0 ] ; then
      echo "build $APP ERROR"
      exit 1
  fi

  echo "build and upload to bintray $APP_$VER.tar.xz"
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

}


cd greenbox
cp ../.ssh_download_key .
git checkout apps_modular -f
git pull
git log -1

PROXY=`docker inspect --format '{{ .State.Status }}' apt-cacher-ng`

if [ X$PROXY != Xrunning ] ; then
   ./run_proxy.sh
fi

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

./push_iso_boot_to_tftp_server.sh
rm .ssh_download_key


cp greenbox.iso ../greenbox-$(cat GREENBOX_VERSION).iso

sha256sum greenbox.iso | awk '{print $1}' > ../greenbox-$(cat GREENBOX_VERSION).iso.sha256sum

echo "this image is going to be base for apps"

docker tag greenbox greenbox:for_apps
docker images greenbox

echo ======================= docker app ===========================
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

build_app green
build_app k8s
build_app python2
build_app developer
build_app x11

rm bintray_api_key
