FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04

ARG PYTHON_VERSION="3.10"
ARG CONTAINER_TIMEZONE=UTC 

WORKDIR /notebooks

# Create necessary directories in one layer
RUN mkdir -p model/stable_diffusion_ckpt/ model/unet/ model/clip/ model/vae/ lora_project/

COPY . .

# Combine RUN commands and use --no-install-recommends consistently
# Remove unnecessary packages and clean up in the same layer
RUN ln -snf /usr/share/zoneinfo/$CONTAINER_TIMEZONE /etc/localtime && echo $CONTAINER_TIMEZONE > /etc/timezone && \
    apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    build-essential \
    aria2 \
    git \
    git-lfs \
    curl \
    wget \
    gcc \
    g++ \
    bash \
    libgl1 \
    software-properties-common \
    openssh-client \
    # Remove openssh-server (client is usually sufficient) and google-perftools
    && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    "python${PYTHON_VERSION}" \
    "python${PYTHON_VERSION}-dev" \
    "python${PYTHON_VERSION}-tk" \
    && \
    # Set up Python and pip in the same layer
    ln -s /usr/bin/python${PYTHON_VERSION} /usr/bin/python && \
    rm -f /usr/bin/python3 && \
    ln -s /usr/bin/python${PYTHON_VERSION} /usr/bin/python3 && \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python get-pip.py && \
    rm get-pip.py && \
    # Clean up in the same layer to reduce image size
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Install Rust only if absolutely necessary for your requirements
# If you can avoid it, remove this block
# RUN curl https://sh.rustup.rs -sSf | bash -s -- -y --profile minimal && \
#     export PATH="/root/.cargo/bin:${PATH}" && \
# Clone the repository with minimal depth
RUN git clone --branch sd3-vjumpkung --single-branch --depth 1 --recurse-submodules https://github.com/vjumpkung/kohya_ss.git && \
    cd kohya_ss && \
    git submodule update --remote && \
    # Install Python packages with no cache
    pip install --no-cache-dir \
    jupyterlab \
    jupyter-archive \
    nbformat \
    jupyterlab-git \
    ipywidgets \
    ipykernel \
    # Remove unnecessary packages: ipython, pickleshare
    python-dotenv \
    nvitop \
    gdown && \
    pip install --no-cache-dir -r requirements_runpod.txt && \
    pip cache purge && \
    # Clean up git repos if not needed at runtime
    cd /notebooks && \
    rm -rf .git kohya_ss/.git

# ENV PATH="/root/.cargo/bin:${PATH}"

EXPOSE 8888 6006 7860

CMD ["jupyter", "lab", "--allow-root", "--ip=0.0.0.0", "--no-browser", \
    "--ServerApp.trust_xheaders=True", "--ServerApp.disable_check_xsrf=False", \
    "--ServerApp.allow_remote_access=True", "--ServerApp.allow_origin='*'", \
    "--ServerApp.allow_credentials=True", "--FileContentsManager.delete_to_trash=False", \
    "--FileContentsManager.always_delete_dir=True", "--FileContentsManager.preferred_dir=/notebooks", \
    "--ContentsManager.allow_hidden=True", "--LabServerApp.copy_absolute_path=True", \
    "--ServerApp.token=''", "--ServerApp.password=''"]