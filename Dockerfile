FROM nvidia/cuda:12.3.2-cudnn9-devel-ubuntu20.04

# Configure NVIDIA and base dependencies
RUN apt-key adv --fetch-keys "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/3bf863cc.pub" && \
    apt-get update && apt-get install -y sudo wget kmod

# NVIDIA driver installation
ARG nvidia_binary_version="545.29.06"
ARG nvidia_binary="NVIDIA-Linux-x86_64-${nvidia_binary_version}.run"
RUN wget -q https://download.nvidia.com/XFree86/Linux-x86_64/${nvidia_binary_version}/${nvidia_binary} && \
    chmod +x ${nvidia_binary} && \
    ./${nvidia_binary} --accept-license --ui=none --no-kernel-module --no-questions && \
    rm -rf ${nvidia_binary}

# Environment variables
ENV DISPLAY=:0 \
    QT_X11_NO_MITSHM=1 \
    QT_DEBUG_PLUGINS=1 \
    QT_QPA_PLATFORM=xcb \
    LANG=en_US.UTF-8 \
    DEBIAN_FRONTEND=noninteractive

# ROS Noetic installation
RUN apt-get update && apt-get install -y locales curl && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    sh -c 'echo "deb http://packages.ros.org/ros/ubuntu focal main" > /etc/apt/sources.list.d/ros-latest.list' && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y \
        python-tk \
        build-essential \
        ros-noetic-joy \
        ros-noetic-tf2-sensor-msgs \
        ros-noetic-rosbash \
        ros-noetic-rviz \
        ros-noetic-teleop-twist-joy \
        ros-noetic-teleop-twist-keyboard \
        ros-noetic-laser-proc \
        ros-noetic-rgbd-launch \
        ros-noetic-depthimage-to-laserscan \
        ros-noetic-rosserial-arduino \
        ros-noetic-rosserial-python \
        ros-noetic-rosserial-server \
        ros-noetic-rosserial-client \
        ros-noetic-rosserial-msgs \
        ros-noetic-amcl \
        ros-noetic-map-server \
        ros-noetic-move-base \
        ros-noetic-urdf \
        ros-noetic-robot-state-publisher \
        ros-noetic-xacro \
        ros-noetic-compressed-image-transport \
        ros-noetic-rqt-image-view \
        ros-noetic-gmapping \
        ros-noetic-navigation \
        ros-noetic-interactive-markers \
        ros-noetic-realsense2-camera \
        tmux wget nano

# Additional dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        git \
        libglew-dev \
        cmake \
        libeigen3-dev \
        libepoxy-dev \
        ninja-build \
        ros-noetic-hector-trajectory-server \
        python3-catkin-tools \
        libopencv-dev \
        x11-apps \
        mesa-utils \
        libgl1-mesa-glx \
        libgl1-mesa-dri \
        xauth \
        dbus-x11 \
        libxcb-xinerama0 \
        libxcb-icccm4 \
        libxcb-image0 \
        libxcb-keysyms1 \
        libxcb-render-util0 \
        libxcb-shape0 \
        libxcb-xkb1 && \
    rm -rf /var/lib/apt/lists/*

# Create workspace and install Pangolin
WORKDIR /ASCC_CONTAINER
RUN git clone https://github.com/stevenlovegrove/Pangolin.git && \
    cd Pangolin && \
    mkdir build && cd build && \
    cmake -DBUILD_PANGOLIN_LIBOPENEXR=OFF .. && \
    make -j$(nproc) && \
    make install

# Install ORB_SLAM3_ROS (without being affected by volume mounts)
RUN mkdir -p /opt/orb_slam3_ros && \
    cd /opt/orb_slam3_ros && \
    git clone https://github.com/thien94/orb_slam3_ros.git && \
    cd orb_slam3_ros && \
    find . -name "CMakeLists.txt" -exec sed -i 's/-Werror//g' {} \; && \
    cd /ASCC_CONTAINER && \
    mkdir -p src && \ 
    ln -s /opt/orb_slam3_ros/orb_slam3_ros src/orb_slam3_ros && \
    catkin config --extend /opt/ros/noetic && \
    catkin build -j2 --no-status

# Install Miniconda and NeRFStudio
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda clean --all --yes && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc
ENV PATH /opt/conda/bin:$PATH

RUN conda create -y --name nerfstudio python=3.10 && \
    echo "conda activate nerfstudio" >> ~/.bashrc

# Install NeRF Bridge
RUN git clone -b ros1 https://github.com/javieryu/nerf_bridge.git && \
    cd nerf_bridge && \
    pip install -U --no-cache-dir gdown --pre && \
    gdown "https://drive.google.com/u/1/uc?id=1-7x7qQfB7bIw2zV4Lr6-yhvMpjXC84Q5&confirm=t" && \
    . /opt/conda/etc/profile.d/conda.sh && \
    conda activate nerfstudio && \
    pip install nerfstudio==0.3.4 && \
    pip uninstall torch torchvision torchaudio -y && \
    pip install rospkg torchvision==0.14.1 numpy==1.26.4 rawpy==0.20 tyro==0.5.3

# Setup entrypoint
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]