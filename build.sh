#!/bin/bash

# Function to check if a package is installed
check_package() {
    if ! dpkg -s "$1" >/dev/null 2>&1; then
        echo "$1 is not installed."
        return 1
    fi
    return 0
}

# Check for required packages
required_packages=(binutils gcc make)
missing_packages=()

for package in "${required_packages[@]}"; do
    if ! check_package "$package"; then
        missing_packages+=("$package")
    fi
done

# If there are missing packages, try to install them
if [ ${#missing_packages[@]} -ne 0 ]; then
    echo "The following packages need to be installed: ${missing_packages[*]}"
    if [ "$EUID" -ne 0 ]; then
        echo "Please enter your password to install the missing packages."
        if sudo -v; then
            sudo apt-get update
            sudo apt-get -y install "${missing_packages[@]}"
        else
            echo "Unable to obtain sudo privileges. Please install the missing packages manually."
            exit 1
        fi
    else
        apt-get update
        apt-get -y install "${missing_packages[@]}"
    fi
fi

# Build SDK
echo "Building SDK..."
cd libPS4 || { echo "Unable to enter libPS4 subdirectory"; exit 1; }
make
cd ..

# Set local environment variable
export PS4SDK="$PWD"

echo "SDK built and environment variable set locally"
echo "To use this SDK in your current shell, run:"
echo "export PS4SDK=\"$PWD\""
