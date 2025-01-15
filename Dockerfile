FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04

ARG PYTHON_VERSION="3.10"
ARG CONTAINER_TIMEZONE=UTC 

WORKDIR /

RUN mkdir -p /notebooks /notebooks/model/checkpoints/ /notebooks/model/unet/ /notebooks/model/clip/ /notebooks/model/vae/ /notebooks/lora_project/

COPY . /notebooks/

# Update, install packages and clean up
RUN ln -snf /usr/share/zoneinfo/$CONTAINER_TIMEZONE /etc/localtime && echo $CONTAINER_TIMEZONE > /etc/timezone
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends aria2 git git-lfs curl wget gcc g++ bash libgl1 software-properties-common openssh-server nginx google-perftools lsof && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update --yes && \
    apt-get install --yes --no-install-recommends "python${PYTHON_VERSION}" "python${PYTHON_VERSION}-dev" "python${PYTHON_VERSION}-venv" "python${PYTHON_VERSION}-tk" && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Set up Python and pip
RUN ln -s /usr/bin/python${PYTHON_VERSION} /usr/bin/python && \
    rm /usr/bin/python3 && \
    ln -s /usr/bin/python${PYTHON_VERSION} /usr/bin/python3 && \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python get-pip.py

WORKDIR /notebooks/

RUN git clone --recursive https://github.com/vjumpkung/kohya_ss.git

WORKDIR /notebooks/kohya_ss/

# JupyterLab and other python packages
RUN pip install --no-cache-dir jupyterlab jupyter-archive nbformat \
    jupyterlab-git ipywidgets ipykernel ipython pickleshare \
    requests python-dotenv && \
    pip install --no-cache-dir torch==2.5.0+cu124 torchvision==0.20.0+cu124 xformers==0.0.28.post2 --index-url https://download.pytorch.org/whl/cu124 &&\
    pip install --no-cache-dir -r requirements_runpod.txt && \
    pip cache purge

WORKDIR /notebooks/

EXPOSE 8888 6006 7860
CMD jupyter lab --allow-root --ip=0.0.0.0 --no-browser --ServerApp.trust_xheaders=True --ServerApp.disable_check_xsrf=False \
    --ServerApp.allow_remote_access=True --ServerApp.allow_origin='*' --ServerApp.allow_credentials=True --FileContentsManager.delete_to_trash=False \
    --FileContentsManager.always_delete_dir=True --FileContentsManager.preferred_dir=/notebooks --ContentsManager.allow_hidden=True