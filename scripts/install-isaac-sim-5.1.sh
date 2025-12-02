#! /bin/bash -e

# This script is intended to be used with Google Colab.
# Updated for Isaac Sim 5.1.0 (Requires Python 3.11)

# -----------------------------------------------------------------------------

# 1. Setup Python 3.11 environment

wget -O py311.sh https://raw.githubusercontent.com/j3soon/colab-python-version/refs/heads/main/scripts/py311.sh
bash py311.sh

# -----------------------------------------------------------------------------
# 2. System Dependencies (Vulkan & Drivers)
# -----------------------------------------------------------------------------
# Ref: https://docs.isaacsim.omniverse.nvidia.com/latest/installation/requirements.html
apt-get install -y vulkan-tools libglu1
conda install -y gcc=12.1.0 -c conda-forge
# Build tools
apt-get install -y cmake build-essential

# Nvidia specific ICD setup (Crucial for Headless Rendering on Colab)
# Ref: https://github.com/j3soon/docker-vulkan-runtime
cat > /etc/vulkan/icd.d/nvidia_icd.json <<EOF
{
    "file_format_version" : "1.0.0",
    "ICD": {
        "library_path": "libGLX_nvidia.so.0",
        "api_version" : "1.3.194"
    }
}
EOF
mkdir -p /usr/share/glvnd/egl_vendor.d && \
    cat > /usr/share/glvnd/egl_vendor.d/10_nvidia.json <<EOF
{
    "file_format_version" : "1.0.0",
    "ICD" : {
        "library_path" : "libEGL_nvidia.so.0"
    }
}
EOF
cat > /etc/vulkan/implicit_layer.d/nvidia_layers.json <<EOF
{
    "file_format_version" : "1.0.0",
    "layer": {
        "name": "VK_LAYER_NV_optimus",
        "type": "INSTANCE",
        "library_path": "libGLX_nvidia.so.0",
        "api_version" : "1.3.194",
        "implementation_version" : "1",
        "description" : "NVIDIA Optimus layer",
        "functions": {
            "vkGetInstanceProcAddr": "vk_optimusGetInstanceProcAddr",
            "vkGetDeviceProcAddr": "vk_optimusGetDeviceProcAddr"
        },
        "enable_environment": {
            "__NV_PRIME_RENDER_OFFLOAD": "1"
        },
        "disable_environment": {
            "DISABLE_LAYER_NV_OPTIMUS_1": ""
        }
    }
}
EOF
vulkaninfo --summary

# -----------------------------------------------------------------------------
# 3. Install uv and Isaac Sim
# -----------------------------------------------------------------------------
# Install uv for faster pip install
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Isaac Sim 5.1.0
# Ref: https://docs.isaacsim.omniverse.nvidia.com/latest/installation/install_python.html
# Note: Using python3.11 specifically
uv pip install --python $(which python3.11) -qq isaacsim[all,extscache]==5.1.0 --extra-index-url https://pypi.nvidia.com

# -----------------------------------------------------------------------------
# 4. Shader Cache (Commented Out)
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# 4. Shader Cache (Google Drive Method)
# -----------------------------------------------------------------------------
# We use Google Drive to store the cache so you don't have to download/upload to your PC.
# The first time you run this, it will take ~30-40 mins to generate the cache.
# The second time, it will load from Drive in minutes.

# 1. Mount Google Drive
from google.colab import drive
drive.mount('/content/drive')

# Define paths
CACHE_BACKUP_DIR="/content/drive/MyDrive/IsaacSim_5.1_Cache"
SYS_CACHE_DIR="/usr/local/lib/python3.11/site-packages/omni/cache"
OV_CACHE_DIR="/root/.cache/ov"
GL_CACHE_DIR="/root/.cache/nvidia/GLCache"

# 2. Check if we already have the cache on Drive
if [ -d "$CACHE_BACKUP_DIR" ]; then
    echo "Found cached shaders on Google Drive! Restoring..."
    
    # Restore User Cache
    mkdir -p $(dirname $SYS_CACHE_DIR)
    cp -r "$CACHE_BACKUP_DIR/usr-cache/cache" $SYS_CACHE_DIR
    
    # Restore OV Cache
    mkdir -p $(dirname $OV_CACHE_DIR)
    cp -r "$CACHE_BACKUP_DIR/ov-cache/ov" $OV_CACHE_DIR
    
    # Restore GL Cache
    mkdir -p $(dirname $GL_CACHE_DIR)
    cp -r "$CACHE_BACKUP_DIR/glcache/GLCache" $GL_CACHE_DIR
    
    echo "Cache restored. Isaac Sim should start quickly."
else
    echo "No cache found on Drive. Isaac Sim will generate it on first run."
    echo "AFTER you successfully run Isaac Sim for the first time, run the 'Save Cache' block below."
fi

# The cache files for 4.5 are NOT compatible with 5.1.0.
# You must generate new cache on the first run (takes ~30-60 mins).
# If you have a 5.1.0 cache zip, uncomment and update the URL below.

# wget -O glcache.zip <YOUR_5.1.0_CACHE_URL>
# unzip -d / -o glcache.zip
# wget -O usr-cache.zip <YOUR_5.1.0_CACHE_URL>
# unzip -d / -o usr-cache.zip
# wget -O ov-cache.zip <YOUR_5.1.0_CACHE_URL>
# unzip -d / -o ov-cache.zip

# -----------------------------------------------------------------------------
# 5. Verification
# -----------------------------------------------------------------------------
# Download Isaac Sim minimal example
wget -O time_stepping.py https://raw.githubusercontent.com/j3soon/isaac-sim-colab/refs/heads/main/thirdparty/isaacsim/standalone_examples/api/isaacsim.core.api/time_stepping.py

# Set environment variables
export OMNI_KIT_ACCEPT_EULA=YES

# Run minimal example to test installation using Python 3.11
# python3.11 time_stepping.py
