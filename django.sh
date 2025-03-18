#!/usr/bin/env bash
#   ---------------------------------------
#   DJANGO DEVELOPMENT
#   ---------------------------------------

# Django Management Command Enhancements

# General Django manage.py command
function pm {
    python3 manage.py "$@"
}

# Run server with optional port and address
function pmr {
    local port=${1:-8000}
    local addr=${2:-127.0.0.1}
    python3 manage.py runserver "$addr:$port"
}

# Delete all non-initial migrations files with confirmation
function cleanupMg {
    find . -path "*/migrations/*" -not -name "__init__.py" -print
    read -rp "Delete these files? [y/N] " confirm && [[ $confirm == [yY] ]] && find . -path "*/migrations/*" -not -name "__init__.py" -delete
}

# Make messages for a specified language
# Usage: pm_make [locale]
# Example: pm_make es
function pm_make {
    local locale=${1:-en}
    python3 manage.py makemessages -l "$locale"
}

# pmt: Run Django tests with optional arguments
# Usage: pmt [keepdb] [failfast] [liveserver]
function pmt {
    local cmd="python3 manage.py test"
    [[ $1 == "keepdb" ]] && cmd="$cmd --keepdb" && shift
    [[ $1 == "failfast" ]] && cmd="$cmd --failfast" && shift
    [[ $1 == "liveserver" ]] && cmd="$cmd --liveserver=localhost:8082" && shift
    $cmd "$@"
}

# Other aliases
alias pmcs='python3 manage.py createsuperuser'
alias pmmm='python3 manage.py makemigrations'
alias pmm='python3 manage.py migrate'
alias pmc='python3 manage.py collectstatic --no-input'
alias pms='python3 manage.py shell'
alias pm_compile='python3 manage.py compilemessages'

# Reset database
function pmdbreset {
    read -rp "This will DELETE your database. Are you sure? [y/N] " confirm
    if [[ $confirm == [yY] ]]; then
        find . -path "*/migrations/*.py" -not -name "__init__.py" -delete
        find . -path "*/migrations/*.pyc" -delete
        python3 manage.py reset_db --noinput
        python3 manage.py makemigrations
        python3 manage.py migrate
        echo "Database reset complete."
    else
        echo "Operation cancelled."
    fi
}

# Create a new Django app with proper structure
function pmapp {
    local app_name=$1
    if [[ -z "$app_name" ]]; then
        echo "Usage: pmapp <app_name>"
        return 1
    fi

    python3 manage.py startapp "$app_name"

    # Create directories for better organization
    mkdir -p "$app_name/templates/$app_name"
    mkdir -p "$app_name/static/$app_name/css"
    mkdir -p "$app_name/static/$app_name/js"
    mkdir -p "$app_name/tests"

    # Create initial test files
    touch "$app_name/tests/__init__.py"
    touch "$app_name/tests/test_models.py"
    touch "$app_name/tests/test_views.py"

    echo "Created Django app '$app_name' with enhanced structure"
}

# Generate a fixtures file from current database
function pmfixture {
    local app_name=$1
    local model_name=$2

    if [[ -z "$app_name" || -z "$model_name" ]]; then
        echo "Usage: pmfixture <app_name> <model_name>"
        return 1
    fi

    python3 manage.py dumpdata "$app_name.$model_name" --indent 2 > "$app_name/fixtures/$model_name.json"
    echo "Created fixture for $app_name.$model_name"
}

# Usage examples:
# pm runserver 8000 (default usage)
# pmr 8080 0.0.0.0 (run on port 8080 and all interfaces)
# cleanupMg (delete migration files after confirmation)
# pm_make es (make messages for Spanish)
# pmt failfast (run tests and stop on first failure)
