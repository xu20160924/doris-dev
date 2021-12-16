# 基础镜像
FROM ubuntu:20.04
# 作者信息版本信息
LABEL version="v2" \
      maintainer="Sunchao <hustcaid@gmail.com>"

# 可用命令行参数配置的boost版本信息
ARG BOOST_VERSION=1.73.0
ARG BOOST_VERSION_=1_73_0
ENV BOOST_VERSION=${BOOST_VERSION}
ENV BOOST_VERSION_=${BOOST_VERSION_}
ENV BOOST_ROOT=/usr/include/boost
# tzdata直接安装时可能需要手动选择时区，添加该环境变量让其不要通过交互，自动选择
ENV DEBIAN_FRONTEND=noninteractive
# apt换源，加快构建速度
COPY sources.list /etc/apt/sources.list

RUN apt-get update
# 安装openssh 和 rsync是用于clion的远程部署和连接docker开发
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

# 配置 sshd和rsnyc， 允许root登陆 关闭usePAM 允许rsnc
RUN mkdir /var/run/sshd
RUN sed -ri 's/^#PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config &&  sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && sed -ri 's/RSYNC_ENABLE=false/RSYNC_ENABLE=true/g' /etc/default/rsync

# config rsync service
COPY rsync.conf /etc
# 设置root的密码
RUN echo 'root:000000' |chpasswd
RUN mkdir /root/sync
# install boost
#RUN wget --max-redirect 3 --no-check-certificate https://dl.bintray.com/boostorg/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_}.tar.gz
#RUN mkdir -p /usr/include/boost && tar zxf boost_${BOOST_VERSION_}.tar.gz -C /usr/include/boost --strip-components=1 && rm *.tar.gz
# 在docker-compose的启动方式中，最后这一步将会启动ssh和rsync服务
COPY entrypoint.sh /sbin
RUN chmod +x /sbin/entrypoint.sh
ENTRYPOINT [ "/sbin/entrypoint.sh" ]
