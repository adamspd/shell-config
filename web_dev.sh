#!/usr/bin/env bash
#   ---------------------------------------
#   WEB DEVELOPMENT
#   ---------------------------------------

# Apache shortcuts
alias apacheEdit='sudo vim /etc/httpd/httpd.conf'      # Edit httpd.conf
alias apacheRestart='sudo apachectl graceful'          # Restart Apache
alias editHosts='sudo vim /etc/hosts'                  # Edit /etc/hosts file
alias herr='tail /var/log/httpd/error_log'             # Tail HTTP error logs
alias apacheLogs="less +F /var/log/apache2/error_log"  # Show apache error logs

# Web debugging
alias checksite="wget --spider --server-response"      # Check HTTP response of a website
alias openports="sudo netstat -tulpn | grep LISTEN"    # Show all open ports
alias servehere="python3 -m http.server"               # Serve current directory via HTTP

# Get HTTP headers
httpHeaders() { 
    curl -I -L "$@" 
}

# Debug HTTP timing
httpDebug() { 
    curl "$@" -o /dev/null -w "dns: %{time_namelookup} connect: %{time_connect} pretransfer: %{time_pretransfer} starttransfer: %{time_starttransfer} total: %{time_total}\n" 
}

# Stop a process running on a specific port
killport() {
    local port=$1
    if [[ -z "$port" ]]; then
        echo "Usage: killport PORT_NUMBER"
        return 1
    fi
    
    local pid=$(lsof -i :"$port" | awk 'NR>1 {print $2}' | uniq)
    if [[ -n "$pid" ]]; then
        echo "Killing process $pid running on port $port"
        kill -9 "$pid"
        echo "Process killed"
    else
        echo "No process found running on port $port"
    fi
}

# Web performance testing
runLighthouse() {
    local url=$1
    if [[ -z "$url" ]]; then
        echo "Usage: runLighthouse URL"
        return 1
    fi
    
    if ! command -v lighthouse &> /dev/null; then
        echo "Lighthouse not found. Install with: npm install -g lighthouse"
        return 1
    fi
    
    lighthouse --chrome-flags="--headless" "$url"
}

# HTTP monitoring
alias watch_apache="watch -n 1 'sudo apache2ctl status'"  # Watch Apache status
alias phplogs="tail -f /var/log/php/php_errors.log"     # Tail PHP error logs
alias nginx_test="sudo nginx -t"                        # Test nginx config
alias nginx_reload="sudo systemctl reload nginx"         # Reload nginx
alias nginx_restart="sudo systemctl restart nginx"       # Restart nginx
alias nginx_stop="sudo systemctl stop nginx"             # Stop nginx

# Lighthouse CLI
alias lighthouse="lighthouse --chrome-flags='--headless'"  # Run Lighthouse headless

# Frontend tools
alias npmd="npm run dev"                                # npm run dev
alias npms="npm start"                                  # npm start
alias npmb="npm run build"                              # npm run build
alias npmt="npm run test"                               # npm run test

# Database shortcuts
alias mysqlc="mysql -u root -p"                         # MySQL console
alias postgresqlc="psql -U postgres"                    # PostgreSQL console
alias mongoc="mongo"                                    # MongoDB console
alias mysql_start="sudo systemctl start mysql"
alias mysql_stop="sudo systemctl stop mysql"
alias mysql_cli="mysql -u root -p"
alias pg_start="sudo systemctl start postgresql"
alias pg_stop="sudo systemctl stop postgresql"
alias pg_cli="psql -U postgres"

# Web security testing
alias ssllabs="ssllabs-scan"                            # SSL Labs scan
alias headers="curl -I"                                 # Show HTTP headers

# URL encoding/decoding
urlencode() {
    python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))" "$1"
}

urldecode() {
    python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1]))" "$1"
}

# Base64 encoding/decoding
b64encode() {
    echo -n "$1" | base64
}

b64decode() {
    echo -n "$1" | base64 -d
}

# JSON pretty print
json_pretty() {
    python3 -m json.tool
}

# Stop Grails application on a port
stop_grails() {
    if [[ $# -eq 1 ]]; then
        PORT=$1
        pid=$(lsof -i :"$PORT" | awk '{if(NR>1)print}' | awk '{print $2}');
        if [[ -n "$pid" ]]; then
            printf "PID java application that'll be killed: %s\n" "$pid";
            kill -9 "$pid" >/dev/null;
            printf "Success !\n"
        else
            printf "There's no process running with port %s\n" "$PORT"
        fi
    else
        printf "Bad usage\nUsage: stop_grails port\n"
    fi
}
