#!/bin/bash

# Derive email from USER env var (corporate machines set USER to the full UPN/email)
echo "Current user: $USER"
email="$USER"

# If USER does not look like an email, prompt for it
if [[ "$email" != *@* ]]; then
    read -rp "Enter your work email address: " email
fi

# Extract the username from the email
username="${email%@*}"
# Replace '.' with a space in the username
username="${username//./ }"
# Convert the username to Pascal Case
username=$(echo "$username" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')

# Print the users details
echo "Username: $username"
echo "Email: $email"
read -rp "Press Enter to continue..."

# Install xcode Command Line Tools
if xcode-select -p &>/dev/null; then
    echo "xcode-select is already installed."
else
    echo "Installing xcode-stuff"
    xcode-select --install
fi

# Create a new SSH key if it doesn't exist
if [ -f ~/.ssh/id_ed25519 ]; then
    echo "SSH key already exists."
else
    echo "Creating a new SSH key..."
    ssh-keygen -t ed25519 -C "$email"
fi

# Add SSH configuration to ~/.ssh/config
ssh_config="$HOME/.ssh/config"

# Create the config file if it does not exist
if [ ! -f "$ssh_config" ]; then
    mkdir -p "$HOME/.ssh"
    touch "$ssh_config"
    chmod 600 "$ssh_config"
fi

# Check if the configuration already exists
if ! grep -q "Host github.com" "$ssh_config"; then
    echo "Adding SSH configuration to $ssh_config..."
    {
        echo "Host github.com"
        echo "  AddKeysToAgent yes"
        echo "  UseKeychain yes"
        echo "  IdentityFile ~/.ssh/id_ed25519"
    } >> "$ssh_config"
else
    echo "SSH configuration for github.com already exists in $ssh_config."
fi

# Check if the SSH key is already added to the ssh-agent
if ssh-add -l 2>/dev/null | grep -q "(ED25519)"; then
    echo "SSH key is already added to the ssh-agent."
else
    echo "Adding SSH key to the ssh-agent..."
    ssh-add --apple-use-keychain ~/.ssh/id_ed25519
fi

# Test if the SSH key is set up correctly
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "SSH key is set up correctly."
else
    echo "SSH key is not set up correctly. Please follow the instructions to add the key to your GitHub account."

    # Copy the SSH public key to your clipboard
    pbcopy < ~/.ssh/id_ed25519.pub

    # Echo instructions to add the SSH public key to GitHub
    echo "To add the SSH public key to your GitHub account:"
    echo "1. Go to GitHub Enterprise"
    echo "2. Click on your profile photo"
    echo "3. Click on Settings"
    echo "4. Click on SSH and GPG keys"
    echo "5. Click on New SSH key"
    echo "6. Paste your SSH public key"
    echo "7. Click on Add SSH key"
    echo "8. Click Configure SSO"
    echo "9. Click Authorize"
    # Open a URL in the default web browser
    open "https://github.com/settings/keys"
    # Pause the script and wait for user input
    read -rp "Press Enter to continue once you have finished setting up your key..."
fi

# Set up Homebrew
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew is already installed."
fi


# Update Homebrew
brew update

# Upgrade installed formulae
brew upgrade

# Install formulae from the Brewfile
brew bundle --file=Brewfile

brew cleanup

# Install Oh My Zsh
if [ -d ~/.oh-my-zsh ]; then
    echo "Oh My Zsh is already installed."
else
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi


# Finder settings
defaults write NSGlobalDomain "AppleShowAllExtensions" -bool "true" 
defaults write com.apple.finder "AppleShowAllFiles" -bool "true"
defaults write com.apple.finder "ShowPathbar" -bool "true"
killall Finder

# Install latest Node using nvm (node version manager)
# Source nvm so it is available in this shell session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install node

# Set up Git profile (after Homebrew so modern git is available)

# Check if git user.name is set
if ! git config --global --get user.name > /dev/null 2>&1; then
    git config --global user.name "$username"
fi

# Check if git user.email is set
if ! git config --global --get user.email > /dev/null 2>&1; then
    git config --global user.email "$email"
fi

# Recommended Git Config Settings
# Based on how core Git developers configure Git
# Safe to run multiple times - just overwrites existing values
# Source: https://blog.gitbutler.com/how-git-core-devs-configure-git

echo "🔧 Applying recommended git config settings..."

# ============================================================
# CLEARLY MAKES GIT BETTER (zero downsides)
# ============================================================

# Display branches/tags in columns
git config --global column.ui auto

# Sort branches by most recent commit, not alphabetically
git config --global branch.sort -committerdate

# Sort tags by version number, not alphabetically
git config --global tag.sort version:refname

# Set default branch name (stops the nag message on git init)
git config --global init.defaultBranch main

# Use the histogram diff algorithm (smarter than the 1986 default)
git config --global diff.algorithm histogram

# Show moved code in different colours from added/removed
git config --global diff.colorMoved plain

# Replace a/ b/ with meaningful prefixes (i=index, w=working dir, c=commit)
git config --global diff.mnemonicPrefix true

# Detect file renames in diffs
git config --global diff.renames true

# Auto-setup remote tracking branch on first push (no more --set-upstream)
git config --global push.autoSetupRemote true

# Push local tags that aren't on the server
git config --global push.followTags true

# Remove remote tracking branches that no longer exist on the server
git config --global fetch.prune true
git config --global fetch.pruneTags true

# Fetch from all remotes
git config --global fetch.all true

# ============================================================
# WHY THE HELL NOT (harmless, occasionally very helpful)
# ============================================================

# Prompt to autocorrect mistyped commands
git config --global help.autocorrect prompt

# Show full diff in commit message editor for context
git config --global commit.verbose true

# Remember and auto-reapply merge conflict resolutions
git config --global rerere.enabled true
git config --global rerere.autoupdate true

# Global gitignore in a predictable location
git config --global core.excludesfile ~/.gitignore

# Make git pull rebase by default instead of merge
git config --global pull.rebase true

# Auto-reorder fixup/squash commits during interactive rebase
git config --global rebase.autoSquash true

# Auto-stash before rebase, re-apply after
git config --global rebase.autoStash true

# Keep stacked branch refs updated during rebase
git config --global rebase.updateRefs true

# ============================================================
# MATTER OF TASTE (uncomment if you want them)
# ============================================================

# Show common ancestor in merge conflicts (needs Git 2.35+)
# Use 'diff3' instead of 'zdiff3' for older Git versions
# git config --global merge.conflictstyle zdiff3

# Filesystem monitor for faster git status (one process per repo)
# git config --global core.fsmonitor true
# git config --global core.untrackedCache true

echo ""
echo "✅ Done! Current git config:"
echo ""
git config --global --list | sort
