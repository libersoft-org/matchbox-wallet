# Matchbox Wallet

[![Created Badge](https://badges.pufler.dev/created/libersoft-org/matchbox-wallet)](https://badges.pufler.dev) [![Updated Badge](https://badges.pufler.dev/updated/libersoft-org/matchbox-wallet)](https://badges.pufler.dev) [![Visits Badge](https://badges.pufler.dev/visits/libersoft-org/matchbox-wallet)](https://badges.pufler.dev)

## Table of contents

- [**About**](#about)
- [**Screenshot**](#screenshot)
- [**Installation**](#installation)
- [**License**](#license)
- [**Contribution**](#contribution)
- [**Donations**](#donations)
- [**Star history**](#star-history)

## About

Official website: **https://matchbox.libersoft.org**

This is the crypto wallet software for Matchbox device.

## Screenshot

![Matchbox](./screenshot.webp)

## Installation

### Prerequisites

Before building the Matchbox Wallet, ensure you have the following dependencies installed:

#### System Dependencies
- **Qt6** (Core, Quick, Svg, Multimedia) - GUI framework
- **Node.js development libraries** - For embedded JavaScript runtime
- **CMake 3.16+** - Build system
- **C++17 compatible compiler** (GCC 7+, Clang 5+, MSVC 2019+)

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install qt6-base-dev qt6-declarative-dev qt6-svg-dev qt6-multimedia-dev \
                 libnode-dev nodejs-dev cmake build-essential pkg-config
```

#### Fedora/RHEL/CentOS
```bash
sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtsvg-devel qt6-qtmultimedia-devel \
                 nodejs-devel cmake gcc-c++ pkgconfig
```

#### Arch Linux
```bash
sudo pacman -S qt6-base qt6-declarative qt6-svg qt6-multimedia nodejs npm cmake gcc pkgconf
```

#### macOS
```bash
brew install qt@6 node cmake
export PATH="/opt/homebrew/opt/qt@6/bin:$PATH"
```

#### Windows
1. Install [Qt6](https://www.qt.io/download) with Qt Creator
2. Install [Node.js](https://nodejs.org/) (includes development headers)  
3. Install [CMake](https://cmake.org/download/)
4. Install Visual Studio 2019+ or MinGW-w64

### Building from Source

1. **Clone the repository:**
   ```bash
   git clone https://github.com/libersoft-org/matchbox-wallet.git
   cd matchbox-wallet
   ```

2. **Install JavaScript dependencies:**
   ```bash
   cd src/js
   npm install
   cd ../..
   ```

3. **Build the project:**
   ```bash
   mkdir build && cd build
   cmake ..
   cmake --build .
   ```

   Or use the provided build scripts:
   ```bash
   # Linux/macOS
   ./build.sh
   
   # Windows
   build.bat
   ```

4. **Run the wallet:**
   ```bash
   # From build directory
   ./wallet
   
   # Or use start script
   ./start.sh
   ```

### Development Setup

For development with embedded Node.js runtime:

1. The wallet loads JavaScript from `src/js/index.js`
2. You can install additional npm packages in `src/js/`
3. JavaScript runtime supports full Node.js module system
4. Available JavaScript actions: `ping`, `hash`, `generateKeyPair`, `generateRandomBytes`, `hmac`

### Troubleshooting

- **Node.js headers not found**: Ensure `nodejs-dev` or equivalent package is installed
- **Qt6 not found**: Set `CMAKE_PREFIX_PATH` to Qt6 installation directory
- **Build fails on ARM**: Use the provided ARM cross-compilation script: `./build-arm64.sh`

For detailed installation instructions, see [**INSTALL.md**](./INSTALL.md).

## License

- This software is developed under the license called [**Unlicense**](./LICENSE).

## Contribution

If you are interested in contributing to the development of this project, we would love to hear from you! Developers can reach out to us through one of the contact methods listed on [**our contacts page**](https://libersoft.org/contacts). We prefer communication through our Telegram chat group, but feel free to use any method that suits you.
In addition to direct communication, you are welcome to contribute by submitting issues or pull requests on our project repository. Your insights and contributions are valuable to us. We look forward to collaborating with you!

## Donations

Donations are important to support the ongoing development and maintenance of our open source projects. Your contributions help us cover costs and support our team in improving our software. We appreciate any support you can offer.

To find out how to donate our projects, please navigate here:

[![Donate](https://raw.githubusercontent.com/libersoft-org/documents/main/donate.png)](https://libersoft.org/donations)

Thank you for being a part of our projects' success!

## Star history

[![Star History Chart](https://api.star-history.com/svg?repos=libersoft-org/yellow-matchbox-wallet&type=Date)](https://star-history.com/#libersoft-org/yellow-matchbox-wallet&Date)
