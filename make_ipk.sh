#!/bin/sh

tar -czvf data.tar.gz --mode='a+x' --owner=0 --group=0 etc lib usr 
size=`cat data.tar.gz | wc -c`

cd control
sed -i "s/\(Installed-Size:\) [[:digit:]]\+/\1 $size/" control 
ver=`awk '/^Version:/{print $2}' control`
tar -czvf ../control.tar.gz --mode='a+x' --owner=0 --group=0 control postinst prerm
cd ..

tar -zcvf watchvpn_"$ver"_all.ipk control.tar.gz data.tar.gz debian-binary

rm *.gz
