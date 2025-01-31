FROM osrf/ros:humble-desktop-full-jammy
ENV DEBIAN_FRONTEND=noninteractive

ENV ROS_DISTRO=humble


RUN apt-get update \
    && apt-get install -y curl \
    && curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - \
    && apt-get update \
    && apt install -y python3-colcon-common-extensions \
    && apt-get install -y ros-humble-navigation2 \
    && apt-get install -y ros-humble-robot-localization \
    && apt-get install -y ros-humble-robot-state-publisher \
    && apt install -y ros-humble-perception-pcl \
  	&& apt install -y ros-humble-pcl-msgs \
  	&& apt install -y ros-humble-vision-opencv \
  	&& apt install -y ros-humble-xacro \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt install -y software-properties-common \
    && add-apt-repository -y ppa:borglab/gtsam-release-4.2 \
    && apt-get update \
    && apt install -y libgtsam-dev libgtsam-unstable-dev \
    && rm -rf /var/lib/apt/lists/*

################
# Expose the nvidia driver to allow opengl 
# Dependencies for glvnd and X11.
################
RUN apt-get update \
 && apt-get install -y -qq --no-install-recommends \
  libegl1 \
  libgl1 \
  libglvnd0 \
  libglx0 \
  libx11-6 \
  libxext6 \
  x11-apps \
  x11-utils && \
  apt-get autoremove -y && \
  apt-get clean -y && \
  rm -rf /var/lib/apt/lists/*

# Env vars for the nvidia-container-runtime.
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute
ENV QT_X11_NO_MITSHM 1

ARG USERNAME=autoware
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create a non-root user
RUN groupadd --gid $USER_GID $USERNAME \
  && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
  # Add sudo support for the non-root user
  && apt-get update \
  && apt-get install -y sudo \
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
  && chmod 0440 /etc/sudoers.d/$USERNAME \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

# Set up autocompletion for user
RUN apt-get update && apt-get install -y git-core bash-completion \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

ENV DEBIAN_FRONTEND=
ENV AMENT_CPPCHECK_ALLOW_SLOW_VERSIONS=1

# Set up auto-source of workspace for ros user
ARG WORKSPACE=/workspaces/lio-sam-iv

# Autoware is now installed on /opt/autoware, we need to source it, we also put all the other sources in the bashrc_local
RUN echo "if [ -f /opt/ros/${ROS_DISTRO}/setup.bash ]; then source /opt/ros/${ROS_DISTRO}/setup.bash; fi" >> /home/$USERNAME/.bashrc_local \
  && echo "if [ -f /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash ]; then source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash; fi" >> /home/$USERNAME/.bashrc_local \
  && echo "if [ -f ${WORKSPACE}/install/setup.bash ]; then source ${WORKSPACE}/install/setup.bash; fi" >> /home/$USERNAME/.bashrc_local

  # Now we source the bashrc_local in the bashrc 
RUN echo "source /home/$USERNAME/.bashrc_local" >> /home/$USERNAME/.bashrc

# Set the username for the container, Allows using autoware and the bashrc setup in te CI pipelines
USER autoware

