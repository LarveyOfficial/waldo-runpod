# Dockerfile

# Start with a full NVIDIA CUDA development image. This provides the complete
# CUDA toolkit and compilers that Conda needs to correctly resolve GPU dependencies.
FROM nvidia/cuda:12.1.1-devel-ubuntu22.04

# Set the working directory to /app
WORKDIR /app

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system utilities needed to download and install Miniconda
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Download and install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh

# Add Conda to the system's PATH environment variable
ENV PATH /opt/conda/bin:$PATH

# --- Multi-Step Conda Installation ---
# This process is more robust than a single 'conda env create' command.
RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
# Step 1: Create a base environment with just Python 3.9, as specified.
RUN conda create -n cs2-detect-env python=3.9 --yes

# Step 2: Install the most critical and complex packages: PyTorch and its CUDA toolkit.
# We explicitly tell Conda to use the 'pytorch' and 'nvidia' channels for this.
RUN conda install -n cs2-detect-env -c pytorch -c nvidia \
    pytorch=2.3.1 \
    torchvision=0.18.1 \
    torchaudio=2.3.1 \
    pytorch-cuda=12.1 \
    --yes

# Step 3: Copy the project files so we can install the remaining dependencies.
COPY . .

# Step 4: Install the rest of the Conda packages from environment.yml.
# This is now much easier for the solver because PyTorch is already installed.
RUN conda install -n cs2-detect-env -c conda-forge \
    ffmpeg=6.1.1 \
    opencv=4.10.0 \
    av=12.3.0 \
    librosa=0.11.0 \
    timm=0.4.12 \
    einops=0.8.1 \
    triton=3.1.0 \
    flask=3.1.0 \
    numpy=1.26.4 \
    pandas=2.3.1 \
    scipy=1.13.1 \
    matplotlib=3.9.2 \
    pillow=11.3.0 \
    scikit-learn \
    deepspeed=0.17.4 \
    requests \
    validators \
    pylint \
    pytube \
    absl-py=2.1.0 \
    grpcio=1.71.0 \
    pip \
    --yes

# Step 5: Install the remaining pip packages from environment.yml.
RUN conda run -n cs2-detect-env pip install --no-cache-dir \
    decord \
    soundfile \
    tensorboard==2.9.0 \
    tensorboardX==2.6.2 \
    protobuf==3.20.3 \
    huggingface-hub[cli]

# Expose port 5000 for the web interface
EXPOSE 5000

# This is the final command to run the application.
# It activates the Conda environment and then runs the startup sequence.
CMD [ "/bin/bash", "-c", "source activate cs2-detect-env && huggingface-cli download $HF_REPO $HF_FILENAME --local-dir deepcheat/VideoMAEv2/output --local-dir-use-symlinks False && python main.py --share --server_name 0.0.0.0 --server_port 5000" ]