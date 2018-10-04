FROM ros:kinetic-ros-base

RUN apt-get update && apt-get install -y --no-install-recommends \
        pkg-config \
        libxau-dev \
        libxdmcp-dev \
        libxcb1-dev \
        libxext-dev \
        libx11-dev \
        ros-kinetic-gazebo-* \
	gawk  \
	make  \
	git  \
	curl  \
	cmake  \
	wget \
	g++  \
	python-pip  \
	python-matplotlib  \
	python-serial \ 
	python-wxgtk3.0 \ 
	python-scipy  \
	python-opencv \ 
	python-numpy \ 
	python-pyparsing  \
	ccache \ 
	realpath \ 
	libopencv-dev \ 
	libxml2-dev \
	libxslt1-dev \
	sudo && \
    rm -rf /var/lib/apt/lists/*

RUN pip install future
RUN pip2 install pymavlink catkin_pkg --upgrade
RUN pip install MAVProxy==1.5.2

COPY --from=nvidia/opengl:1.0-glvnd-runtime-ubuntu16.04 \
  /usr/local/lib/x86_64-linux-gnu \
  /usr/local/lib/x86_64-linux-gnu

COPY --from=nvidia/opengl:1.0-glvnd-runtime-ubuntu16.04 \
  /usr/local/share/glvnd/egl_vendor.d/10_nvidia.json \
  /usr/local/share/glvnd/egl_vendor.d/10_nvidia.json

RUN echo '/usr/local/lib/x86_64-linux-gnu' >> /etc/ld.so.conf.d/glvnd.conf && \
    ldconfig && \
    echo '/usr/local/$LIB/libGL.so.1' >> /etc/ld.so.preload && \
    echo '/usr/local/$LIB/libEGL.so.1' >> /etc/ld.so.preload


# Now create the ros user itself
RUN  useradd ros && echo "ros:ros" | chpasswd && adduser ros sudo
RUN usermod -a -G dialout ros

RUN mkdir /var/run/sshd


# And, as that user...
USER ros

# HOME needs to be set explicitly. Without it, the HOME environment variable is
# set to "/"
#RUN HOME=/home/ros rosdep update

# Create a ROS workspace for the ROS user.
RUN mkdir -p /home/ros/workspace/src
RUN /bin/bash -c '. /opt/ros/kinetic/setup.bash; catkin_init_workspace /home/ros/workspace/src'
RUN /bin/bash -c '. /opt/ros/kinetic/setup.bash; cd /home/ros/workspace; catkin_make'

#RUN mkdir -p /home/ros/Desktop


# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES \
    ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
    ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics


