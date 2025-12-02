#! /bin/bash -e

# This script installs Isaac Sim 4.5.0 on Google Colab (Python 3.10)

# 1. Setup Python 3.10 environment (Colab default is usually 3.10, but this ensures it)
wget -O py310.sh https://raw.githubusercontent.com/j3soon/colab-python-version/main/scripts/py310.sh
bash py310.sh

# 2. Set up Vulkan & System dependencies
apt-get install -y vulkan-tools libglu1
conda install -y gcc=12.1.0 -c conda-forge

# Verify Library dependencies
ldd --version

# Configure NVIDIA Vulkan ICD (Crucial for Cloud Rendering)
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

# 3. Install 'uv' for faster pip operations
curl -LsSf https://astral.sh/uv/install.sh | sh

# 4. Install Isaac Sim 4.5.0
# Ref: https://docs.isaacsim.omniverse.nvidia.com/4.5.0/installation/install_python.html
uv pip install -qq isaacsim[all]==4.5.0 --extra-index-url https://pypi.nvidia.com
uv pip install -qq isaacsim[extscache]==4.5.0 --extra-index-url https://pypi.nvidia.com

# 5. Download Shader Caches (Specific to Sim 4.5 + T4/L4 GPUs often found on Colab)
# These prevent the long "compiling shaders" wait on startup.
wget -O glcache.zip https://github.com/j3soon/isaac-sim-colab/releases/download/v0.0.2/glcache_pip-4.5_python-script_T5-gpu.zip
unzip -d / -o glcache.zip
wget -O usr-cache.zip https://github.com/j3soon/isaac-sim-colab/releases/download/v0.0.2/usr-cache_pip-4.5_python-script_T5-gpu.zip
unzip -d / -o usr-cache.zip
wget -O ov-cache.zip https://github.com/j3soon/isaac-sim-colab/releases/download/v0.0.2/ov-cache_pip-4.5_python-script_T5-gpu.zip
unzip -d / -o ov-cache.zip

# 6. Setup Minimal Example
wget -O time_stepping.py https://raw.githubusercontent.com/j3soon/isaac-sim-colab/refs/heads/main/thirdparty/isaacsim/standalone_examples/api/isaacsim.core.api/time_stepping.py

export OMNI_KIT_ACCEPT_EULA=YES
