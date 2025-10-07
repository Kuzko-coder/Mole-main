#!/bin/bash

# Batch uninstall functionality with minimal confirmations
# Replaces the overly verbose individual confirmation approach
# Note: find_app_files() and calculate_total_size() functions now in lib/common.sh

# Batch uninstall with single confirmation
batch_uninstall_applications() {
    local total_size_freed=0

    if [[ ${#selected_apps[@]} -eq 0 ]]; then
        log_warning "No applications selected for uninstallation"
        return 0
    fi

    # Pre-process: Check for running apps and calculate total impact
    local -a running_apps=()
    local -a sudo_apps=()
    local total_estimated_size=0
    local -a app_details=()

    echo ""

    # Show analyzing message with spinner
    local spinner_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local spinner_idx=0
    local analyzed=0

    for selected_app in "${selected_apps[@]}"; do
        # Update spinner
        local spinner_char="${spinner_chars:$((spinner_idx % 10)):1}"
        ((analyzed++))
        echo -ne "\r🗑️  ${spinner_char} Analyzing... $analyzed/${#selected_apps[@]}" >&2
        ((spinner_idx++))
        IFS='|' read -r epoch app_path app_name bundle_id size last_used <<< "$selected_app"

        # Check if app is running
        if pgrep -f "$app_name" >/dev/null 2>&1; then
            running_apps+=("$app_name")
        fi

        # Check if app requires sudo to delete
        if [[ ! -w "$(dirname "$app_path")" ]] || [[ "$(stat -f%Su "$app_path" 2>/dev/null)" == "root" ]]; then
            sudo_apps+=("$app_name")
        fi

        # Calculate size for summary
        local app_size_kb=$(du -sk "$app_path" 2>/dev/null | awk '{print $1}' || echo "0")
        local related_files=$(find_app_files "$bundle_id" "$app_name")
        local related_size_kb=$(calculate_total_size "$related_files")
        local total_kb=$((app_size_kb + related_size_kb))
        ((total_estimated_size += total_kb))

        # Store details for later use
        # Base64 encode related_files to handle multi-line data safely
        local encoded_files=$(echo "$related_files" | base64)
        app_details+=("$app_name|$app_path|$bundle_id|$total_kb|$encoded_files")
    done

    # Clear spinner line
    echo -ne "\r\033[K" >&2

    # Format size display
    if [[ $total_estimated_size -gt 1048576 ]]; then
        local size_display=$(echo "$total_estimated_size" | awk '{printf "%.2fGB", $1/1024/1024}')
    elif [[ $total_estimated_size -gt 1024 ]]; then
        local size_display=$(echo "$total_estimated_size" | awk '{printf "%.1fMB", $1/1024}')
    else
        local size_display="${total_estimated_size}KB"
    fi

    # Request sudo access if needed (do this before confirmation)
    if [[ ${#sudo_apps[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}🔐 Admin privileges required for: ${BLUE}${sudo_apps[*]}${NC}"
        echo -e "${BLUE}You will be prompted for your password before proceeding...${NC}"
        if ! sudo -v; then
            log_error "Administrator privileges required but not granted"
            return 1
        fi
        # Keep sudo alive during the process
        (while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null) &
        local sudo_keepalive_pid=$!

        # Append keepalive cleanup to existing traps without overriding them
        local _trap_cleanup_cmd="kill $sudo_keepalive_pid 2>/dev/null || true; wait $sudo_keepalive_pid 2>/dev/null || true"
        for signal in EXIT INT TERM; do
            local existing_trap
            existing_trap=$(trap -p "$signal" | awk -F"'" '{print $2}')
            if [[ -n "$existing_trap" ]]; then
                trap "$existing_trap; $_trap_cleanup_cmd" "$signal"
            else
                trap "$_trap_cleanup_cmd" "$signal"
            fi
        done
    fi

    # Show summary and get batch confirmation
    printf '\n'
    local app_total=${#selected_apps[@]}
    echo -e "${YELLOW}📦 Remove ${BLUE}${app_total}${YELLOW} app(s), free about ${GREEN}$size_display${NC}"
    if [[ ${#running_apps[@]} -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Will force-quit: ${RED}${running_apps[*]}${NC}"
    fi
    printf "%b" "${BLUE}Continue? Press Enter to proceed, or q/ESC to cancel:${NC} "
    local confirm_key=""
    IFS= read -r -s -n1 confirm_key || confirm_key=""
    if [[ "$confirm_key" == $'\e' ]]; then
        while IFS= read -r -s -n1 -t 0 rest; do
            [[ -z "$rest" || "$rest" == $'\n' ]] && break
        done
    fi
    echo ""

    local cancel=false
    case "$confirm_key" in
        ""|$'\n'|$'\r') ;;
        $'\e'|"q"|"Q") cancel=true ;;
        *) cancel=true ;;
    esac

    if [[ "$cancel" == true ]]; then
        log_info "Uninstallation cancelled"
        # Clean up sudo keepalive if it was started
        if [[ -n "${sudo_keepalive_pid:-}" ]]; then
            kill "$sudo_keepalive_pid" 2>/dev/null || true
        fi
        return 0
    fi

    echo -e "${PURPLE}⚡ Starting uninstallation in 3 seconds...${NC} ${YELLOW}(Press Ctrl+C to abort)${NC}"
    sleep 1 && echo -e "${PURPLE}⚡ ${BLUE}2${PURPLE}...${NC}"
    sleep 1 && echo -e "${PURPLE}⚡ ${BLUE}1${PURPLE}...${NC}"
    sleep 1
    echo -e "${GREEN}✨ Let's go!${NC}"

    # Force quit running apps first (batch)
    if [[ ${#running_apps[@]} -gt 0 ]]; then
        echo ""
        log_info "Force quitting running applications..."
        for app_name in "${running_apps[@]}"; do
            echo "  • Quitting $app_name..."
            pkill -f "$app_name" 2>/dev/null || true
        done
        echo "  • Waiting 3 seconds for apps to close..."
        sleep 3
    fi

    # Perform uninstallations without individual confirmations
    echo ""
    log_info "Starting batch uninstallation..."
    local success_count=0
    local failed_count=0

    for detail in "${app_details[@]}"; do
        IFS='|' read -r app_name app_path bundle_id total_kb encoded_files <<< "$detail"

        # Decode the related files list
        local related_files=$(echo "$encoded_files" | base64 -d)

        echo -e "${YELLOW}🗑️  Uninstalling: ${BLUE}$app_name${NC}"

        # Check if app is still running (even after force quit)
        if pgrep -f "$app_name" >/dev/null 2>&1; then
            echo -e "  ${YELLOW}⚠️${NC} App is still running, attempting force kill..."
            pkill -9 -f "$app_name" 2>/dev/null || true
            sleep 2
            if pgrep -f "$app_name" >/dev/null 2>&1; then
                echo -e "  ${RED}✗${NC} Failed to remove $app_name"
                echo -e "     ${YELLOW}Reason: Application is still running and cannot be terminated${NC}"
                ((failed_count++))
                continue
            fi
        fi

        # Check if app requires admin privileges to delete
        local needs_sudo=false
        if [[ ! -w "$(dirname "$app_path")" ]] || [[ "$(stat -f%Su "$app_path" 2>/dev/null)" == "root" ]]; then
            needs_sudo=true
        fi

        # Remove the application with appropriate permissions
        local removal_success=false
        local error_msg=""
        if [[ "$needs_sudo" == "true" ]]; then
            if sudo rm -rf "$app_path" 2>/dev/null; then
                removal_success=true
                echo -e "  ${GREEN}✓${NC} Removed application"
            else
                error_msg="Failed to remove with sudo (check permissions or SIP protection)"
            fi
        else
            if rm -rf "$app_path" 2>/dev/null; then
                removal_success=true
                echo -e "  ${GREEN}✓${NC} Removed application"
            else
                error_msg="Failed to remove (check if app is running or protected)"
            fi
        fi

        if [[ "$removal_success" == "true" ]]; then

            # Remove related files
            local files_removed=0
            while IFS= read -r file; do
                if [[ -n "$file" && -e "$file" ]]; then
                    if rm -rf "$file" 2>/dev/null; then
                        ((files_removed++))
                    fi
                fi
            done <<< "$related_files"

            if [[ $files_removed -gt 0 ]]; then
                echo -e "  ${GREEN}✓${NC} Cleaned $files_removed related files"
            fi

            ((total_size_freed += total_kb))
            ((success_count++))
            ((files_cleaned++))
            ((total_items++))

        else
            echo -e "  ${RED}✗${NC} Failed to remove $app_name"
            if [[ -n "$error_msg" ]]; then
                echo -e "     ${YELLOW}Reason: $error_msg${NC}"
            fi
            ((failed_count++))
        fi
    done

    # Show final summary
    echo ""
    echo "===================================================================="
    echo "🎉 UNINSTALLATION COMPLETE!"

    if [[ $success_count -gt 0 ]]; then
        if [[ $total_size_freed -gt 1048576 ]]; then
            local freed_display=$(echo "$total_size_freed" | awk '{printf "%.2fGB", $1/1024/1024}')
        elif [[ $total_size_freed -gt 1024 ]]; then
            local freed_display=$(echo "$total_size_freed" | awk '{printf "%.1fMB", $1/1024}')
        else
            local freed_display="${total_size_freed}KB"
        fi
        echo "🗑️  Apps uninstalled: $success_count | Space freed: ${GREEN}${freed_display}${NC}"
    else
        echo "🗑️  No applications were uninstalled"
    fi

    if [[ $failed_count -gt 0 ]]; then
        echo -e "${RED}⚠️  Failed to uninstall: $failed_count${NC}"
    fi

    echo "===================================================================="
    if [[ $failed_count -gt 0 ]]; then
        log_warning "$failed_count applications failed to uninstall"
    fi

    # Clean up sudo keepalive if it was started
    if [[ -n "${sudo_keepalive_pid:-}" ]]; then
        kill "$sudo_keepalive_pid" 2>/dev/null || true
        wait "$sudo_keepalive_pid" 2>/dev/null || true
    fi

    ((total_size_cleaned += total_size_freed))
}
