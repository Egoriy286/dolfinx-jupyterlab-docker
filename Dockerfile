```dockerfile
# ============================================================
# DOLFINx 0.10 + JupyterLab + PyVista + VTK + ParaView
# + Xvfb + Mesa/OpenGL
#
# База:
#   DOLFINx 0.10.0-r1
# ============================================================

FROM ghcr.io/fenics/dolfinx/dolfinx:v0.10.0-r1

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

# ------------------------------------------------------------
# 1. Системные пакеты
# ------------------------------------------------------------
#
# Xvfb                  - виртуальный X-сервер
# Mesa                  - software OpenGL
# libgl                - OpenGL runtime
# EGL/GLX              - OpenGL context
# ParaView              - GUI + VTK
# Qt                    - зависимости GUI
# X11                   - базовые библиотеки
#
# ------------------------------------------------------------

RUN apt-get update && apt-get install -y \
    sudo \
    git \
    nano \
    vim \
    wget \
    curl \
    ca-certificates \
    \
    xvfb \
    xauth \
    \
    mesa-utils \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    libegl1-mesa \
    libegl1 \
    libglx-mesa0 \
    libopengl0 \
    libglu1-mesa \
    \
    libx11-6 \
    libx11-xcb1 \
    libxext6 \
    libxrender1 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxinerama1 \
    libxcursor1 \
    libxcomposite1 \
    libxdamage1 \
    libxss1 \
    \
    libsm6 \
    libice6 \
    libfontconfig1 \
    libfreetype6 \
    \
    libxcb1 \
    libxcb-glx0 \
    libxcb-render0 \
    libxcb-shm0 \
    libxcb-xfixes0 \
    libxcb-randr0 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-icccm4 \
    libxcb-util1 \
    libxcb-xinerama0 \
    libxcb-shape0 \
    \
    qtbase5-dev \
    qt5-default \
    \
    paraview \
    python3-paraview \
    \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# 2. Пользователь
# ------------------------------------------------------------

RUN useradd -m -s /bin/bash fenics && \
    echo "fenics ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/apt-get" \
    > /etc/sudoers.d/fenics && \
    chmod 0440 /etc/sudoers.d/fenics

# ------------------------------------------------------------
# 3. Python
# ------------------------------------------------------------

RUN python3 -m pip install --no-cache-dir --upgrade pip && \
    python3 -m pip install --no-cache-dir \
        jupyterlab \
        notebook \
        ipywidgets \
        matplotlib \
        numpy \
        scipy \
        pandas \
        meshio \
        pyvista \
        vtk \
        trame \
        trame-vtk \
        trame-vuetify

# ------------------------------------------------------------
# 4. Каталоги
# ------------------------------------------------------------

RUN mkdir -p /workspace /tmp/.X11-unix && \
    chown -R fenics:fenics /workspace

# ------------------------------------------------------------
# 5. Графические переменные
# ------------------------------------------------------------

ENV DISPLAY=:99

# Software OpenGL / Mesa
ENV LIBGL_ALWAYS_SOFTWARE=1
ENV MESA_GL_VERSION_OVERRIDE=3.3
ENV MESA_GLSL_VERSION_OVERRIDE=330

# Qt внутри контейнера
ENV QT_X11_NO_MITSHM=1

# ------------------------------------------------------------
# 6. Скрипт запуска Xvfb
# ------------------------------------------------------------

RUN cat > /usr/local/bin/start-xvfb.sh <<'EOF'
#!/bin/bash

set -e

export DISPLAY=:99

# Проверяем, не запущен ли уже Xvfb
if ! pgrep -x Xvfb > /dev/null; then
    echo "Starting Xvfb on ${DISPLAY}..."

    Xvfb ${DISPLAY} \
        -screen 0 1920x1080x24 \
        -ac \
        +extension GLX \
        +render \
        -noreset \
        >/tmp/xvfb.log 2>&1 &

    # Небольшое ожидание запуска X-сервера
    sleep 2
fi

echo "DISPLAY=${DISPLAY}"

exec "$@"
EOF

RUN chmod +x /usr/local/bin/start-xvfb.sh

# ------------------------------------------------------------
# 7. Пользователь fenics
# ------------------------------------------------------------

USER fenics
WORKDIR /workspace

# ------------------------------------------------------------
# 8. Jupyter
# ------------------------------------------------------------

EXPOSE 8888

CMD ["/usr/local/bin/start-xvfb.sh", \
     "jupyter", "lab", \
     "--ip=0.0.0.0", \
     "--port=8888", \
     "--no-browser", \
     "--allow-root", \
     "--NotebookApp.token=student123"]
```
