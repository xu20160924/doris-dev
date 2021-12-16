# doris-dev
The Doris development environment by using doccker.


We know that be of Doris only support build and develop on the Linux os, even though we just want to read the code, there is no highlight and code jumping. So this will cause inconvenience for Mac users, for this reason I try to set up environment in docker with Clion to develop  and build the be code.



1. Dockerfile

   ```dockerfile
   # basic image
   FROM ubuntu:20.04
   # author information
   LABEL version="v1" maintainer="x"
   
   # boost version info
   ARG BOOST_VERSION=1.73.0
   ARG BOOST_VERSION_=1_73_0
   ENV BOOST_VERSION=${BOOST_VERSION}
   ENV BOOST_VERSION_=${BOOST_VERSION_}
   ENV BOOST_ROOT=/usr/include/boost
   # When installing tzData directly, you may need to manually select the time zone. Add this environment variable so that it is automatically selected without interaction
   ENV DEBIAN_FRONTEND=noninteractive
   # apt source, improve speed
   COPY sources.list /etc/apt/sources.list
   
   RUN apt-get update
   # Installing openssh and rsync that Clion can to remote deployment and connect to docker for develop.
   RUN apt install -y --no-install-recommends tzdata build-essential cmake gdb openssh-server rsync vim git wget
   
   # for doris
   RUN apt install -y openjdk-8-jdk byacc flex automake libtool-bin bison binutils-dev libiberty-dev zip unzip libncurses5-dev curl git ninja-build python brotli
   RUN apt install -y software-properties-common
   RUN add-apt-repository ppa:ubuntu-toolchain-r/ppa
   RUN apt update
   RUN apt install -y gcc-10 g++-10
   RUN apt install -y autoconf automake libtool autopoint
   RUN apt install -y libssl-dev
   
   # for locales
   RUN apt-get update && apt-get install -y --no-install-recommends locales locales-all
   RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
   ENV LANG en_US.UTF-8
   ENV LANGUAGE en_US:en
   ENV LC_ALL en_US.UTF-8
   
   # config sshd and rsnyc, allow root login, close usePAM, allow rsnyc
   RUN mkdir /var/run/sshd
   RUN sed -ri 's/^#PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config &&  sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && sed -ri 's/RSYNC_ENABLE=false/RSYNC_ENABLE=true/g' /etc/default/rsync
   
   # config rsync service
   COPY rsync.conf /etc
   # set password for user
   RUN echo 'user:xxxx' |chpasswd
   RUN mkdir /root/sync
   # install boost
   #RUN wget --max-redirect 3 --no-check-certificate https://dl.bintray.com/boostorg/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_}.tar.gz
   #RUN mkdir -p /usr/include/boost && tar zxf boost_${BOOST_VERSION_}.tar.gz -C /usr/include/boost --strip-components=1 && rm *.tar.gz
   # last step will start ssh and rsync service when docker-compse start
   COPY entrypoint.sh /sbin
   RUN chmod +x /sbin/entrypoint.sh
   ENTRYPOINT [ "/sbin/entrypoint.sh" ]
   ```

   

2. docker-compose.yml

   ```yaml
   version: "3"
   
   services:
     env:
       build: .
       container_name: doris-dev
       # Forward docker port 22 to host 45678 port 873 to 8730,873 for file synchronization
       ports:
         - "45678:22"
         - "8730:873"
       cap_add:
         - ALL
   ```

   

3. rsync.conf

   ```properties
   # config info
   max connections = 8
   log file = /var/log/rsync.log
   timeout = 300
   
   [sync] # module name
   comment = sync
   # The path is folder need synchronization
   path = /root/sync
   read only = no
   list = yes
   uid = root
   gid = root
   ```

   

4. sources.list

   ```
   deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted
   deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted
   deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal universe
   deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates universe
   deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal multiverse
   deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates multiverse
   deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse
   deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted
   deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security universe
   deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security multiverse
   ```



5. entrypoint.sh

   ```
   #!/bin/bash
   
   /usr/bin/rsync --daemon --config=/etc/rsync.conf
   /usr/sbin/sshd -D
   ```



6. Config Toolchains

- Add a remote host

7. Config remote CMake


-  Set environment variable

      ```properties
      DORIS_GCC_HOME=/usr
      DORIS_THIRDPARTY=/root/sync/incubator-doris/thirdparty
      ```

8. Config deployment


- SSH configuration same with remote host

- Set up the relationship mapping between local folders and folders in docker.
