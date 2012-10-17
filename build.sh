#!/bin/bash
# Copyright (C) 1994, 1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002,
# 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Free Software
# Foundation, Inc.
# This Makefile.in is free software; the Free Software Foundation
# gives unlimited permission to copy and/or distribute it,
# with or without modifications, as long as this notice is preserved.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY, to the extent permitted by law; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.

set -e

PWD=`pwd`
GITREPO="git://github.com/clearscene/opendias.git"
LOCALREPO="XXclearscene-src-opendias"
DEPTH=`uname -m | sed 's/x86_//;s/i[3-6]86/32/' `
VERSION=`head -1 debian/changelog | sed -e s/.*\(// -e s/\).*//`
ARCH=`uname -i`
if [ -f /etc/lsb-release ]; then 
  . /etc/lsb-release
  OS=$DISTRIB_ID
elif [ -f /etc/debian_version ]; then 
  OS=Debian
elif [ -f /etc/redhat-release ]; then 
  OS=Fedora
elif [ -f /etc/issues ]; then 
  OS=parseToGuess
else 
  echo `uname -s` 
fi

#===========================

clean() {
  # remove logs and temperary build file
  rm -f clearscene-opendias*
  rm -f opendias/debian/*.log
  rm -f opendias/debian/clearscene-opendias.debhelper.log
  rm -f opendias/debian/clearscene-opendias.substvars
  rm -fr opendias/debian/clearscene-opendias/
  rm -fr opendias/debian/files
}

distclean() {
  # cleanup source and build files
  clean
  rm -rf opendias
}

refreshsource() {
  distclean
  # Get back to a known place and then get the source
  if test -f ../opendias-${VERSION}.tar.gz ; then
    # Expand a tarball if available
    tar -zxvf ../opendias-${VERSION}.tar.gz
    mv opendias-${VERSION} opendias
  elif test -d ../${LOCALREPO} ; then
    # Otherwise copy a local checkout of code
    cp -r ../${LOCALREPO} opendias
  else
    # Finally, last resport, goto github and get a fresh clone
    git clone ${GITREPO} 
  fi
}

buildsource() {
  # Build the source
  cd opendias
  if test ! -f configure ; then
    autoreconf -iv
  fi
  ./configure
  make
  cd ../
}

packagedeb() {
  # make a deb package from built source
  if [ "$OS" != "Ubuntu" ]; then
    echo Building a DEB is not supported in this platform 
    exit
  else
    cp -r debian opendias
    cd opendias
    debuild -uc -us
    cd ../
  fi
}

packagerpm() {
  # make an rpm package from built source
#  if [ "$OS" == "Fedora" ]; then 
    for DIR in `cat redhat/dirs`; do
      mkdir -p redhat/install/${DIR}
    done
    redhat/rules
    rpmbuild --buildroot=${PWD}'/redhat/install' -bb --target i386 'redhat/opendias.spec'
#  else 
#    if [ "$OS" == "Ubuntu" ]; then 
#      if test ! -f clearscene-opendias_${VERSION}_${ARCH}.deb ; then
#        echo DEB package \(clearscene-opendias_${VERSION}_${ARCH}.deb\) is not available. This is required to RPM build on none Fedora platforms
#        exit
#      else
#        sudo alien -vkr clearscene-opendias_${VERSION}_${ARCH}.deb 
#      fi
#    else
#      echo Building an RPM is not supported in this platform
#      exit 0
#    fi 
#  fi 
}

checkversionbreakout() {
  echo You have just built the application from its sources.
  echo The sources latest version is:
  head -1 opendias/ChangeLog
  echo 
  echo Where the package you\'re about to build has a last changelog entry of:
  head -1 debian/changelog
  echo 
  echo -n Do you want to update the version in the debian/Changelog and .spec file? \[ Y \| n \] 
  read
  if [ "$REPLY" != "N" ] && [ "$REPLY" != "n" ]; then
    echo -e Exiting. You can continue by issuing the command \n ./build.sh $RESTART
    exit
  fi
}

builddeb() {
  # make and build an deb package from nothing
  refreshsource
  buildsource
  RESTART="packagedeb"
  checkversionbreakout
  packagedeb
}

buildrpm() {
  # make and build an rpm package from nothing
  refreshsource
  buildsource
  RESTART="packagerpm"
  checkversionbreakout
  packagerpm
}

#=============================

case "$1" in
  help)
    echo all - default action - blat everything and build everything \(same as buildall\)
    echo clean - remove logs and temperary build files
    echo distclean - cleanup source and build files
    echo cleansource - put the source back to a non built state
    echo refreshsource - distclean, then get fresh sources
    echo buildsource - build the sources
    echo packageXXX - Generate a XXX package from build sources \[rpm, deb, all\]
    echo buildXXX - get, build and generate a XXX package from nothing \[rpm, deb, all\]
    echo 
    echo Running ${OS} ${ARCH} ${DEPTH}bit
  ;;

  clean)
    clean
  ;;

  distclean)
    distclean
  ;;

  cleansource)
    # Put the source back to a non built state
    clean
    cd opendias
    make clean
    cd ../
  ;;

  refreshsource)
    refreshsource
  ;;

  buildsource)
    buildsource
  ;;

  packagedeb)
    packagedeb
  ;;

  packagerpm)
    packagerpm
  ;;

  packageall)
    # package both deb and rpm from a built source
    packagedeb
    packagerpm
  ;;

  builddeb)
    builddeb
  ;;

  buildrpm)
    buildrpm
  ;;

  all|buildall)
    # Default action - blat everything, and build everything.
    # Make and build a deb and rpm from nothing
    refreshsource
    buildsource
    RESTART="packageall"
    checkversionbreakout
    packagedeb
    packagerpm
  ;;

  *)
  echo "Unknown command. Try $N help" >&2
  exit 1
  ;;

esac

