#!/bin/bash
# 2015-Nov-12 Updated to latest Kafka stable: 0.8.2.2
# 2015-Mar-18 Updated to latest Kafka stable: 0.8.2.1
# 2015-Mar-20 Added the init.d script and changed to use binary download of scala 2.10, Kafka 0.8.2.1

set -e
set -u
#app_user=kafka
name=kafka
version=0.8.2.2
scala_version=2.10
package_version="-10"
description="Apache Kafka is a distributed publish-subscribe messaging system."
url="https://kafka.apache.org/"
arch="all"
section="misc"
license="Apache Software License 2.0"
bin_package="kafka_${scala_version}-${version}.tgz"
bin_download_url="http://apache.arvixe.com//kafka/${version}/${bin_package}"
origdir="$(pwd)"

#_ MAIN _#
rm -rf ${name}*.deb
if [[ ! -f "${bin_package}" ]]; then
  wget -c ${bin_download_url}
fi
mkdir -p tmp && pushd tmp
rm -rf kafka
mkdir -p kafka
cd kafka
mkdir -p build/usr/loca/kafka
mkdir -p build/usr/local/kafka/kafka-logs
mkdir -p build/etc/default
mkdir -p build/etc/init
mkdir -p build/etc/init.d
mkdir -p build/etc/kafka
mkdir -p build/var/log/kafka
mkdir -p build/usr/local/zookeeper/data


cp ${origdir}/files/config/default/kafka.default build/etc/default/kafka
cp ${origdir}/files/config/init/kafka.upstart.conf build/etc/init/kafka.conf
cp ${origdir}/files/config/init/kafka.init.d build/etc/init.d/kafka
cp ${origdir}/files/config/init/zookeeper.init.d build/etc/init.d/zookeeper

# Updated to use the Binary package

tar zxf ${origdir}/${bin_package}
cd kafka_${scala_version}-${version}

mv config/* ../build/etc/kafka

rm -rf bin/windows
cp ${origdir}/files/config/etc/zookeeper.properties ../build/etc/kafka
cp ${origdir}/files/config/etc/server.properties ../build/etc/kafka
cp ${origdir}/files/config/etc/log4j.properties ../build/etc/kafka
mv * ../build/usr/local/kafka
cd ../build
pushd usr/local/kafka
patch -p1 < ${origdir}/files/patch/paths.patch
popd

fpm -t deb \
    -n ${name} \
    -v ${version}${package_version} \
    --description "${description}" \
    --url="{$url}" \
    -a ${arch} \
    --category ${section} \
    --vendor "" \
    --license "${license}" \
    --config-files etc/kafka \
    -m "${USER}@localhost" \
    --prefix=/ \
    -d openjdk-7-jre-headless \
    --after-install ${origdir}/files/build/postinst \
    --after-remove ${origdir}/files/build/postrm \
    -s dir \
    -- .
mv kafka*.deb ${origdir}
popd
