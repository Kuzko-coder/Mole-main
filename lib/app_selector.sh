#!/bin/bash
# App selection functionality

set -euo pipefail

# Format app info for display
format_app_display() {
    local display_name="$1" size="$2" last_used="$3"

    # Truncate long names
    local truncated_name="$display_name"
    if [[ ${#display_name} -gt 24 ]]; then
        truncated_name="${display_name:0:21}..."
    fi

    # Format size
    local size_str="Unknown"
    [[ "$size" != "0" && "$size" != "" && "$size" != "Unknown" ]] && size_str="$size"

    printf "%-24s (%s) | %s" "$truncated_name" "$size_str" "$last_used"
}

# Global variable to store selection result (bash 3.2 compatible)
MOLE_SELECTION_RESULT=""

# Main app selection function
select_apps_for_uninstall() {
    if [[ ${#apps_data[@]} -eq 0 ]]; then
        log_warning "No applications available for uninstallation"
        return 1
    fi

    # Build menu options
    local -a menu_options=()
    for app_data in "${apps_data[@]}"; do
        IFS='|' read -r epoch app_path display_name bundle_id size last_used <<< "$app_data"
        menu_options+=("$(format_app_display "$display_name" "$size" "$last_used")")
    done

    echo ""

    # Use paginated menu - result will be stored in MOLE_SELECTION_RESULT
    MOLE_SELECTION_RESULT=""
    paginated_multi_select "🗑️  Select Apps to Remove" "${menu_options[@]}"
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        echo "Cancelled"
        return 1
    fi

    if [[ -z "$MOLE_SELECTION_RESULT" ]]; then
        echo "No apps selected"
        return 1
    fi

    # Build selected apps array (global variable in bin/uninstall.sh)
    # Clear existing selections - compatible with bash 3.2
    selected_apps=()

    # Parse indices and build selected apps array
    # MOLE_SELECTION_RESULT is comma-separated list of indices from the paginated menu
    IFS=',' read -r -a indices_array <<< "$MOLE_SELECTION_RESULT"

    for idx in "${indices_array[@]}"; do
        if [[ "$idx" =~ ^[0-9]+$ ]] && [[ $idx -ge 0 ]] && [[ $idx -lt ${#apps_data[@]} ]]; then
            selected_apps+=("${apps_data[idx]}")
        fi
    done

    return 0
}

# Export function for external use
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This is a library file. Source it from other scripts." >&2
    exit 1
fi