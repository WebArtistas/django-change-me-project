#!/bin/bash
# ============================================================
# Rename this Django template project to your new project name.
#
# Usage:
#   ./rename-project.sh my-new-api
#
# This will replace:
#   change-me-project  -> my-new-api           (kebab-case)
#   change_me_project  -> my_new_api           (snake_case)
#   ChangeMeProject    -> MyNewApi             (PascalCase)
# ============================================================

set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <new-project-name>"
  echo "Example: $0 my-cool-api"
  exit 1
fi

OLD_NAME="change-me-project"
NEW_NAME="$1"

# Derive variants
OLD_UNDERSCORE="${OLD_NAME//-/_}"
NEW_UNDERSCORE="${NEW_NAME//-/_}"
OLD_PASCAL=$(echo "$OLD_NAME" | sed -r 's/(^|-)(\w)/\U\2/g')
NEW_PASCAL=$(echo "$NEW_NAME" | sed -r 's/(^|-)(\w)/\U\2/g')

echo "Renaming project:"
echo "  kebab:  $OLD_NAME -> $NEW_NAME"
echo "  snake:  $OLD_UNDERSCORE -> $NEW_UNDERSCORE"
echo "  pascal: $OLD_PASCAL -> $NEW_PASCAL"
echo ""

# Replace in all text files (excluding .git, venv, __pycache__)
echo "Replacing in files..."
find . -type f \
  -not -path '*/.git/*' \
  -not -path '*/venv/*' \
  -not -path '*/.venv/*' \
  -not -path '*/__pycache__/*' \
  -not -name 'rename-project.sh' \
  -exec grep -lI "$OLD_NAME\|$OLD_UNDERSCORE\|$OLD_PASCAL" {} + 2>/dev/null | while read -r file; do
    sed -i "s/$OLD_PASCAL/$NEW_PASCAL/g" "$file"
    sed -i "s/$OLD_UNDERSCORE/$NEW_UNDERSCORE/g" "$file"
    sed -i "s/$OLD_NAME/$NEW_NAME/g" "$file"
  done

echo ""
echo "Done! Project renamed from '$OLD_NAME' to '$NEW_NAME'."
echo ""
echo "Next steps:"
echo "  1. python -m venv venv && source venv/bin/activate"
echo "  2. pip install -r requirements/dev.txt"
echo "  3. python manage.py migrate"
echo "  4. python manage.py runserver"
