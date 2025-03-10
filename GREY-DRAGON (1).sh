#!/bin/bash

# Function to check for necessary tools and install them if missing
check_and_install_tools() {
    for tool in curl jq git python3 pip3 make; do
        if ! command -v "$tool" &> /dev/null; then
            echo "$tool could not be found. Installing $tool..."
            apt-get update && apt-get install -y "$tool"
            if [ $? -ne 0 ]; then
                echo "Failed to install $tool. Please install it manually and try again."
                exit 1
            fi
        fi
    done
}

# Function to list BlackArch tools
list_blackarch_tools() {
    echo "Fetching BlackArch tools list..."
    response=$(curl -s https://blackarch.org/tools.json)
    if jq -e . >/dev/null 2>&1 <<<"$response"; then
        echo "$response" | jq '.[] | .name'
    else
        echo "Failed to retrieve or parse the tools list from BlackArch. Please check your internet connection or try again later."
        exit 1
    fi
}

# Function to search BlackArch tools
search_blackarch_tools() {
    read -p "Enter the tool name to search: " tool_name
    echo "Searching for $tool_name in BlackArch tools..."
    response=$(curl -s https://blackarch.org/tools.json)
    if jq -e . >/dev/null 2>&1 <<<"$response"; then
        echo "$response" | jq --arg tool_name "$tool_name" '.[] | select(.name | contains($tool_name)) | .name'
    else
        echo "Failed to retrieve or parse the tools list from BlackArch. Please check your internet connection or try again later."
        exit 1
    fi
}

# Function to auto-install tool from GitHub
auto_install_tool() {
    read -p "Enter the GitHub URL of the tool: " github_url
    echo "Scanning $github_url for files..."
    repo_name=$(basename "$github_url" .git)
    git clone "$github_url" "/tmp/$repo_name"
    if [ $? -ne 0 ]; then
        echo "Failed to clone the repository. Please check the URL and try again."
        exit 1
    fi

    cd "/tmp/$repo_name" || exit
    if [ -f "setup.py" ]; then
        echo "Found setup.py. Installing using python..."
        python3 setup.py install
    elif [ -f "Makefile" ]; then
        echo "Found Makefile. Installing using make..."
        make && make install
    elif [ -f "requirements.txt" ]; then
        echo "Found requirements.txt. Installing using pip..."
        pip3 install -r requirements.txt
    else
        echo "No recognizable installation files found. Attempting to install manually..."
        cp -r * /usr/local/bin/
    fi

    if [ $? -ne 0 ]; then
        echo "Installation failed. Please check the repository and try again."
        exit 1
    fi

    echo "Tool installed successfully."
    read -p "Do you want to make the tool accessible from anywhere? ▋