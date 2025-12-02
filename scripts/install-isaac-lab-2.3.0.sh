#! /bin/bash -e

# This script is intended to be used with a specially modified Colab notebook.
# It installs Isaac Lab v2.3.0 which is compatible with Isaac Sim 4.5.0.

# Confirm that Isaac Sim is installed
which isaacsim

# Install system dependencies
# Ref: https://isaac-sim.github.io/IsaacLab/main/source/setup/installation/pip_installation.html
apt-get install -y cmake build-essential

# Install PyTorch
# Note: Isaac Sim 4.5.0 generally pairs with Torch 2.4/2.5. 
# We stick to 2.5.1 as it is the latest stable supported by the Lab pip workflow.
uv pip install -qq torch==2.5.1 torchvision==0.20.1 --index-url https://download.pytorch.org/whl/cu118

# Clone Isaac Lab
git clone https://github.com/isaac-sim/IsaacLab.git
cd IsaacLab

# Checkout the latest stable release (v2.3.0) compatible with Isaac Sim 4.5
# Ref: https://github.com/isaac-sim/IsaacLab/releases
git checkout v2.3.0

# Install Isaac Lab
./isaaclab.sh --install

# Set environment variables
# Ref: https://docs.isaacsim.omniverse.nvidia.com/latest/installation/install_python.html#running-isaac-sim
export OMNI_KIT_ACCEPT_EULA=YES

# (Optional) Verify installation by printing the version
python -c "import omni.isaac.lab; print(f'Isaac Lab Version: {omni.isaac.lab.__version__}')"
