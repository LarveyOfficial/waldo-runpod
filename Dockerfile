# Dockerfile

FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04

# Set the working directory to /app
WORKDIR /app

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system utilities needed to download and install Miniconda (mimicking install.sh)
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Download and install Miniconda, as this is the project's specified package manager
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh

# Add Conda to the system's PATH environment variable
ENV PATH /opt/conda/bin:$PATH

# Copy all project files into the container. This makes environment.yml available.
COPY . .

# Create the Conda environment using the project's exact environment.yml file.
# This is the single source of truth and the most critical step from install.sh.
# Conda will handle the installation of Python, ffmpeg, and the correct CUDA-enabled PyTorch.
RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
RUN conda env create -f environment.yml

# Expose port 5000, as specified in run.sh and the README
EXPOSE 5000

# This is the final command to run the application. It mimics the logic from run.sh.
# 1. Activates the 'cs2-detect-env' Conda environment.
# 2. Downloads the specified model from Hugging Face using the flexible Hub variables.
# 3. Runs the main application with the necessary arguments to make it accessible in a container.
CMD [ "/bin/bash", "-c", "source activate cs2-detect-env && huggingface-cli download $HF_REPO $HF_FILENAME --local-dir deepcheat/VideoMAEv2/output --local-dir-use-symlinks False && python main.py --share --server_name 0.0.0.0 --server_port 5000" ]