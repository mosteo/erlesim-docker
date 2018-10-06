FROM ubuntu:16.04

RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu xenial main" > /etc/apt/sources.list.d/ros-latest.list'

RUN apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116 && apt-get update

RUN apt-get update && apt-get install -y --no-install-recommends \
        pkg-config \
        libxau-dev \
        libxdmcp-dev \
        libxcb1-dev \
        libxext-dev \
        libx11-dev \
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
	libtool \
	libtool-bin \
	automake \ 
	autoconf \
	libexpat1-dev \
	python-rosinstall \
	libeigen3-dev \
	ros-kinetic-ros-base \
	ros-kinetic-octomap-msgs \
	ros-kinetic-joy \
	ros-kinetic-geodesy \
	ros-kinetic-octomap-ros \
	ros-kinetic-mavlink \
	ros-kinetic-control-toolbox \
	ros-kinetic-transmission-interface \
	ros-kinetic-joint-limits-interface \
	ros-kinetic-image-common \
	ros-kinetic-vision-opencv \
	ros-kinetic-geometry \
	ros-kinetic-driver-common \
	ros-kinetic-ros-control \
	ros-kinetic-robot \
	unzip \
	net-tools \
	vim \
	nedit \
	joe \
	xterm \
	sudo && \
    rm -rf /var/lib/apt/lists/*

RUN rosdep init
RUN rosdep update

RUN pip install wheel
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

RUN mkdir /var/run/sshd
RUN mkdir -p /home/ros

# Create a ROS workspace for the ROS user.
RUN mkdir -p /home/ros/workspace/src
RUN /bin/bash -c '. /opt/ros/kinetic/setup.bash; catkin_init_workspace /home/ros/workspace/src'
RUN /bin/bash -c '. /opt/ros/kinetic/setup.bash; cd /home/ros/workspace; catkin_make'
RUN mkdir -p /home/ros/Desktop
RUN echo "source /home/ros/workspace/devel/setup.bash" >> ~/.bashrc

# Download and Install ArUco 1.3.0
RUN mkdir -p /home/ros/Downloads
RUN wget http://webdiis.unizar.es/~riazuelo/data/aruco-1.3.0.tgz -P /home/ros/Downloads
RUN tar -xvzf /home/ros/Downloads/aruco-1.3.0.tgz -C /home/ros/Downloads/
RUN mkdir /home/ros/Downloads/aruco-1.3.0/build && cd /home/ros/Downloads/aruco-1.3.0/build && cmake .. && make && echo ros | sudo -S make install

# Compile a specific branch of ardupilot
RUN mkdir -p /home/ros/simulation && cd /home/ros/simulation && git clone https://github.com/erlerobot/ardupilot -b gazebo
RUN cd /home/ros/simulation/ardupilot && make

# Getting latest version of JSBSim (optional step)
RUN cd /home/ros/simulation && git clone git://github.com/tridge/jsbsim.git 
RUN cd /home/ros/simulation/jsbsim && ./autogen.sh --enable-libraries && make -j2 && echo ros | sudo -S make install

# Download ROS workspace for the ROS user.
RUN mkdir -p /home/ros/workspace/src
RUN cd /home/ros/workspace/src && git clone https://github.com/catkin/catkin_simple.git
RUN cd /home/ros/workspace/src && git clone https://github.com/ethz-asl/glog_catkin.git
RUN mv /home/ros/workspace/src/glog_catkin/fix-unused-typedef-warning.patch /home/ros/workspace/src
RUN ["/bin/bash", "-c", "source /home/ros/workspace/devel/setup.bash && cd /home/ros/workspace && catkin_make"]
RUN rm /home/ros/workspace/src/fix-unused-typedef-warning.patch
RUN cd /home/ros/workspace/src && git clone https://github.com/erlerobot/ardupilot_sitl_gazebo_plugin 
RUN cd /home/ros/workspace/src && git clone https://github.com/tu-darmstadt-ros-pkg/hector_gazebo/ 
RUN cd /home/ros/workspace/src && git clone https://github.com/erlerobot/rotors_simulator -b sonar_plugin 
RUN cd /home/ros/workspace/src && git clone https://github.com/PX4/mav_comm.git 
RUN cd /home/ros/workspace/src && git clone https://github.com/erlerobot/mavros.git
RUN cd /home/ros/workspace/src && git clone https://github.com/ros-simulation/gazebo_ros_pkgs.git -b indigo-devel
RUN cd /home/ros/workspace/src && git clone https://github.com/erlerobot/gazebo_cpp_examples
RUN cd /home/ros/workspace/src && git clone https://github.com/erlerobot/gazebo_python_examples
RUN wget http://webdiis.unizar.es/~riazuelo/data/drcsim.tgz -P /home/ros/workspace/src
RUN tar -xvzf /home/ros/workspace/src/drcsim.tgz -C /home/ros/workspace/src
RUN rm /home/ros/workspace/src/drcsim.tgz

# Install Gazebo using Ubuntu packages
RUN echo ros | sudo -S sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list'
RUN ["/bin/bash", "-c", "set -o pipefail && wget -O - http://packages.osrfoundation.org/gazebo.key | sudo -S apt-key add -"]
RUN echo ros | sudo -S apt-get update
RUN echo ros | sudo -S apt-get remove .*gazebo.* '.*sdformat.*' '.*ignition-math.*' && echo ros |  sudo -S apt-get update && echo ros | sudo -S apt-get install gazebo7 libgazebo7-dev -y

# Compile the workspace
RUN ["/bin/bash", "-c", "source /home/ros/workspace/devel/setup.bash && cd /home/ros/workspace && catkin_make  --pkg mav_msgs mavros_msgs gazebo_msgs"]
RUN ["/bin/bash", "-c", "source /home/ros/workspace/devel/setup.bash && cd /home/ros/workspace && catkin_make  -j 4"]

# Download Gazebo models
RUN mkdir -p /home/ros/.gazebo/models && cd /home/ros && git clone https://github.com/erlerobot/erle_gazebo_models && mv erle_gazebo_models/* /home/ros/.gazebo/models && rm -r erle_gazebo_models
RUN cp -r /home/ros/.gazebo /root

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES \
    ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
    ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics


