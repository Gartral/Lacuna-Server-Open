. dataapps.sh

cp dataapps.sh /etc/profile.d/

yum -y install ncurses-devel gcc make glibc-devel gcc-c++ zlib-devel openssl-devel java
rpm -ivh *.rpm

cd pcre-8.10
./configure --prefix=/data/apps
make
make install
cd ..

cd nginx-0.7.67
./configure --prefix=/data/apps --with-pcre=../pcre-8.10 --with-http_ssl_module --with-openssl=../openssl-1.0.0a
make
make install
cd ..

cd perl-5.12.1
./Configure -Dprefix=/data/apps -des
make
make install
cd ..

cd libevent-1.4.14b-stable
./configure --prefix=/data/apps
make
make install
cd ..

cd memcached-1.4.5
./configure --prefix=/data/apps
make
make install
cd ..

cd git-1.7.2.2
./configure --without-tcltk --prefix=/data/apps
make
make install
cd ..

cpan App::cpanminus

