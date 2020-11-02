FROM winterwindsroboticsdocker/dev-base:v0.1.0

# Install Gazebo 9, which ROS1 melodic requires. (Current version is 11.)
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D2486D2DD83DB69272AFE98867170598AF249743 \
 && echo deb http://packages.osrfoundation.org/gazebo/ubuntu-stable $(. /etc/os-release && echo "${VERSION_CODENAME}") main > /etc/apt/sources.list.d/gazebo-stable.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
      gazebo9 \
      libgazebo9-dev \
 && rm -rf /var/lib/apt/lists/*

# Install ROS 1 melodic.
RUN apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 \
 && echo "deb http://packages.ros.org/ros/ubuntu $(. /etc/os-release && echo "${VERSION_CODENAME}") main" > /etc/apt/sources.list.d/ros-latest.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
      build-essential \
      python-catkin-tools \
      ros-melodic-controller-manager \
      ros-melodic-desktop-full \
      ros-melodic-gazebo-ros-control \
      ros-melodic-gazebo-ros-pkgs \
      ros-melodic-hector-gazebo-plugins \
      ros-melodic-joint-state-controller \
      ros-melodic-joint-state-publisher \
      ros-melodic-joint-state-publisher-gui \
      ros-melodic-effort-controllers \
      ros-melodic-position-controllers \
      ros-melodic-velocity-controllers \
 && rm -rf /var/lib/apt/lists/*

# Ensure ROS commands are available in every new shell without having to explicitly source the setup file.
RUN echo "source /opt/ros/melodic/setup.bash" >> /home/wwr/.bashrc
