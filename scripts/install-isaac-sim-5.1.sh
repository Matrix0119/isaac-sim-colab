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
