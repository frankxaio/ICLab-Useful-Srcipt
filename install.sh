#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# ==============================================================================
# Configuration
# ==============================================================================
REPO_URL="https://github.com/frankxaio/ICLab-Useful-Srcipt.git"
INSTALL_DIR="$HOME/asic-script"
TEMP_DIR="$HOME/temp_git_install_$(date +%s)"

# Specific files/folders to download
TARGET_FOLDER="Script_tcsh"
TARGET_FILE=".tcshrc"

# ANSI Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ==============================================================================
# Functions
# ==============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ==============================================================================
# Main Execution
# ==============================================================================

# 1. Check for Git
if ! command -v git &> /dev/null; then
    log_error "Git is not installed. Please install git first."
    exit 1
fi

# 2. Prepare directories
log_info "Preparing installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
mkdir -p "$TEMP_DIR"

# 3. Clone repository using sparse-checkout (only structure, no files yet)
log_info "Cloning repository structure from $REPO_URL..."
cd "$TEMP_DIR" || exit
git clone --filter=blob:none --no-checkout "$REPO_URL" .

# 4. Configure sparse-checkout to download only specific paths
log_info "Configuring sparse-checkout for: $TARGET_FOLDER and $TARGET_FILE..."
git sparse-checkout init --cone
git sparse-checkout set "$TARGET_FOLDER" "$TARGET_FILE"

# 5. Checkout content (Download actual files)
log_info "Downloading files..."
git checkout main

# 6. Install 'Script_tcsh'
log_info "Installing $TARGET_FOLDER to $INSTALL_DIR..."
if [ -d "$INSTALL_DIR/$TARGET_FOLDER" ]; then
    log_warn "Existing $TARGET_FOLDER found. Overwriting..."
    rm -rf "$INSTALL_DIR/$TARGET_FOLDER"
fi

if [ -d "$TARGET_FOLDER" ]; then
    cp -r "$TARGET_FOLDER" "$INSTALL_DIR/"
else
    log_error "Folder $TARGET_FOLDER not found in the repository!"
    exit 1
fi

# 7. Install '.tcshrc' with User Confirmation
log_info "Processing .tcshrc configuration..."

if [ -f "$TARGET_FILE" ]; then
    echo ""
    echo -e "${YELLOW}-------------------------------------------------------------${NC}"
    echo -e "${YELLOW} WARNING: You are about to overwrite your existing ~/.tcshrc ${NC}"
    echo -e "${YELLOW}-------------------------------------------------------------${NC}"
    echo -e "A new .tcshrc has been downloaded."

    # Interactive input
    read -r -p "Do you want to overwrite your current ~/.tcshrc? (yes/no): " user_response

    # Check user input (case-insensitive for 'yes' or 'y')
    if [[ "$user_response" =~ ^([yY][eE][sS]|[yY])$ ]]; then

        # Backup existing .tcshrc if it exists
        if [ -f "$HOME/.tcshrc" ]; then
            BACKUP_NAME="$HOME/.tcshrc.bak.$(date +%s)"
            cp "$HOME/.tcshrc" "$BACKUP_NAME"
            log_info "Original .tcshrc backed up to: $BACKUP_NAME"
        fi

        # Overwrite
        cp "$TARGET_FILE" "$HOME/.tcshrc"
        log_success "Your ~/.tcshrc has been updated successfully!"

    else
        # User said no
        SAVE_PATH="$INSTALL_DIR/tcshrc_downloaded"
        cp "$TARGET_FILE" "$SAVE_PATH"
        log_info "Skipped overwriting. The new file is saved at: $SAVE_PATH"
    fi

else
    log_warn "File $TARGET_FILE not found in the repository."
fi

# 8. Cleanup
log_info "Cleaning up temporary files..."
cd "$HOME" || exit
rm -rf "$TEMP_DIR"

# 9. Final Message
echo ""
echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN}   Installation Completed Successfully!   ${NC}"
echo -e "${GREEN}======================================================${NC}"
echo -e "1. Scripts are located in: ${YELLOW}$INSTALL_DIR/$TARGET_FOLDER${NC}"
echo -e "2. Please restart your terminal or run '${BLUE}source ~/.tcshrc${NC}' to apply changes."
echo ""