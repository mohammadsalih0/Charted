FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install required system packages and Java 17
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk \
    ca-certificates \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set Environment Variables
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV ANDROID_HOME=/opt/android-sdk
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${FLUTTER_HOME}/bin"

# Install Android SDK Command Line Tools and required platforms
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools \
    && curl -sSLo /tmp/cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    && unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools \
    && mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest \
    && rm /tmp/cmdline-tools.zip \
    && yes | sdkmanager --licenses > /dev/null \
    && sdkmanager "platforms;android-36" "build-tools;36.0.0" "platform-tools"

# Install Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable ${FLUTTER_HOME} \
    && flutter config --no-analytics \
    && flutter precache --android \
    && flutter doctor -v
