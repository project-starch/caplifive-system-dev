# CapliFive System

This repository contains the sources and helper scripts to build and run the
CapliFive system (emulation and FPGA).
The system can run either through QEMU-based emulation or on
FPGA, and consists of
components with the right versions that work together:

- QEMU-based emulator: [hw/qemu](https://github.com/project-starch/caplifive-qemu)
- Software stack and buildroot: [sw/buildroot](https://github.com/project-starch/caplifive-buildroot)
- AnvilHDL compiler: [hw/anvil](https://github.com/kisp-nus/anvil)
- RTL design: [hw/rtl](https://github.com/project-starch/caplifive-cva6)

The documentation provided here is intended to provide consistent and
easy-to-follow instructions for building the whole system from scratch.
For more detail on configuring each component or development setup,
please refer to the README documents of individual components.

## Prerequisites

Operating system: a Debian-based GNU/Linux distribution (instructions
provided in this document were tested on Ubuntu 22.04 LTS)

Recommended packages:

```sh
sudo apt update
sudo apt install -y git build-essential pkg-config meson ninja-build python3 \
	python3-pip clang gcc-multilib g++-multilib bc bison flex libglib2.0-dev \
	libpixman-1-dev libfdt-dev libaio-dev libcap-dev libseccomp-dev  libslirp-dev \
	device-tree-compiler help2man libncurses5-dev openjdk-11-jdk opam dune
```

You also need to install the Rust toolchain:
```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## Obtaining source files

Initialise all submodules contained in this repository:
```sh
git submodule update --init --recursive
source ~/.cargo/env
```

## Building with scripts

The `scripts/` directory provides shell scripts and a Podman `Containerfile` that
automate the build steps described below. Using the container avoids installing
the build dependencies directly on your machine.

### Container setup

Build the image once (requires [Podman](https://podman.io/)):

```sh
scripts/build-image.sh
```

This creates a `caplifive-build:latest` image with all required packages,
the Rust toolchain, and OCaml 5.2 (for Anvil). It also creates a named Podman
volume `caplifive-opam` pre-seeded with the opam state from the image.
The volume is mounted into every container run so that packages installed
by `build-anvil.sh` (e.g. the `anvil` binary) persist across container
invocations. If you rebuild the image, re-run `build-image.sh` to refresh
the volume, then re-run `build-anvil.sh`.

Use `scripts/run-in-container.sh` to run any build script inside the container
with the repository mounted at `/workspace`:

```sh
scripts/run-in-container.sh <command>
```

### QEMU emulation (containerised)

```sh
scripts/run-in-container.sh scripts/setup.sh
scripts/run-in-container.sh scripts/build-qemu.sh
scripts/run-in-container.sh "scripts/build-software.sh --mode qemu"
# Run QEMU in the same container it was built in to avoid shared library
# mismatches (e.g. libslirp). SSH inside the guest is on host port 60022.
scripts/run.sh --container
```

### FPGA synthesis (containerised)

Vivado is bind-mounted into the container so that anvil and Vivado share the
same environment, with no host-side tool installation needed beyond Vivado itself.

```sh
scripts/run-in-container.sh scripts/setup.sh
export VIVADO_HOME=/path/to/vivado
scripts/build-rtl.sh --container   # mounts VIVADO_HOME into the container
scripts/run-in-container.sh "scripts/build-software.sh --mode fpga"
```

### Running scripts locally (without the container)

Each script can also be run directly if the required packages are already
installed. From the repository root:

```sh
scripts/setup.sh
scripts/build-qemu.sh
scripts/build-software.sh --mode qemu   # or --mode fpga
scripts/build-anvil.sh
export VIVADO_HOME=/path/to/vivado
scripts/build-rtl.sh                    # FPGA only; needs VIVADO_HOME and anvil in PATH
scripts/run.sh
```

---

## QEMU-based functional emulation

_If you only want to run the system on FPGA, please skip this part._

### 1) Caplifive-QEMU

```sh
cd hw/qemu
sh configure.sh
make -C build install -j$(nproc)
sed -i 's:caplifive-buildroot:../sw/buildroot:' qemu-args.txt
```

### 2) Software

Build the software stack:
```sh
cd sw/buildroot
make setup DEFCONFIG=$(pwd)/configs/qemu_capstone_defconfig
make build DEFCONFIG=$(pwd)/configs/qemu_capstone_defconfig
```

### 3) Run

You can start the emulator with the provided scripts:

```sh
cd hw/qemu
./start.sh            # start a QEMU instance using the built images
```

## RTL (for running on FPGA)

_If you only want to run the system on Caplifive-QEMU, please skip this part._

This repository also includes an RTL design that can run on FPGA.
It currently supports the Genesys 2 board.
For this part, make sure you have a Genesys 2 board and a Vivado installation
with a suitable licence.

### 1) Anvil (compiler / tooling)

Location: `hw/anvil`

A specific version of the Anvil compiler is needed to build the RTL design for running
on FPGA.

```sh
cd hw/anvil
opam install . --deps-only
eval $(opam env)
dune build --release
opam install .
```

Make sure now that `anvil` is in your `PATH`.

### 2) Bitstream

Location: `hw/rtl`

Point the `VIVADO_HOME` environment variable to the location of your
Vivado installation:
```sh
export VIVADO_HOME=/location/to/vivado
```

Edit `hw/rtl/fpga-env.sh` to point `RISCV` to the location of your RISC-V toolchain.

Next, generate the bitstream (it may take hours):
```sh
cd hw/rtl
bash run-synthesis.sh
```

The generated bitstream can be found at `hw/rtl/corev_apu/fpga/work-fpga/ariane_xilinx.bit`.

Finally, configure the FPGA through the non-volatile SPI flash: connect the JTAG port
of the Genesys 2 board to the host and use openFPGALoader `openFPGALoader -f -b genesys2 <bitstream-file>`.


### 3) Software

The software stack is located at `sw/buildroot`.

First, build the boot image:
```sh
cd sw/buildroot
make setup
make build
make build LINUX_PAYLOAD=1
```

The generated image is located at
`sw/buildroot/build/opensbi-custom/build/platform/generic/firmware/fw_payload.bin`.

Next, write the boot image to a microSD card:
```sh
dd if=<image-file> of=/dev/sd<device> status=progress oflag=sync bs=4M conv=sparse
```

### 4) Run

Insert the microSD card into the SD card reader slot on the Genesys 2 board and connect
the UART port to the host. Open the serial port with a terminal emulator
```sh
screen /dev/ttyUSB0 57600
```

Power on the board. After booting (~10 minutes),
you should be able to interact with the system through the terminal.
