#!/bin/bash

# Function to check for necessary tools and install them if missing
check_and_install_tools() {
    for tool in curl jq; do
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
    curl -s https://blackarch.org/tools.json | jq '.[] | .name'
}

# Function to search BlackArch tools
search_blackarch_tools() {
    read -p "Enter the tool name to search: " tool_name
    echo "Searching for $tool_name in BlackArch tools..."
    curl -s https://blackarch.org/tools.json | jq --arg tool_name "$tool_name" '.[] | select(.name | contains($tool_name)) | .name'
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
    read -p "Do you want to make the tool accessible from anywhere? (y/n): " yn
    case $yn in
        [Yy]* )
            echo "Making the tool accessible from anywhere..."
            ln -s "/usr/local/bin/$repo_name" "/usr/bin/$repo_name"
            echo "Tool is now accessible from anywhere."
            ;;
        [Nn]* ) echo "Skipping making the tool accessible from anywhere." ;;
        * ) echo "Please answer yes or no." ;;
    esac
}

# Main menu
while true; do
    echo "GREY-DRAGON Main Menu:"
    echo "1. List BlackArch tools"
    echo "2. Search BlackArch tools"
    echo "3. Auto-install tool from GitHub"
    echo "4. Exit"
    read -p "Enter your choice: " choice
    case $choice in
        1) list_blackarch_tools ;;
        2) search_blackarch_tools ;;
        3) auto_install_tool ;;
        4) echo "Exiting..."; exit ;;
        *) echo "Invalid choice. Please enter a number between 1 and 4." ;;
    esac
done