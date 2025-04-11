#!/bin/bash

# 配置参数
LOCAL=(
    "0.0.0.0:10000"
    ":20000"
    "[::]:30000"
)

TARGETS=(
    "192.168.1.1:10000"
    "[2001:4860:4860::8888]:20000"
)

# 服务文件目录
SERVICE_DIR="/etc/systemd/system"
SCRIPT_DIR="/usr/local/bin"
SCRIPT_NAME="socat_forward.sh"
SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT_NAME}"
SERVICE_NAME="socat-forward.service"
CLEANUP_SCRIPT="${SCRIPT_DIR}/socat_cleanup.sh"
CLEANUP_LOG="/var/log/socat_cleanup.log"
CLEANUP_TIMER="${SERVICE_DIR}/socat-cleanup.timer"
CLEANUP_SERVICE="${SERVICE_DIR}/socat-cleanup.service"
LOCK_FILE="/tmp/socat_cleanup.lock"

# 全局日志文件
LOG_FILE="/var/log/socat_cleanup.log"

# 日志函数
log() {
    local log_file="${LOG_FILE:-/var/log/socat_cleanup.log}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    stdbuf -oL echo "[$timestamp] $1" | tee -a "$log_file"
    sync
    if [[ "$1" =~ "Error" ]]; then
        echo "[$timestamp] $1" | logger -t socat_cleanup
    fi
}

# 检查依赖
check_dependencies() {
    local deps=("socat" "tcpdump" "pgrep" "ps")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null; then
            log "Error: Required command '$dep' not found. Please install it."
            exit 1
        fi
    done
    if ! sudo -n true 2>/dev/null; then
        log "Error: This script requires sudo privileges."
        exit 1
    fi
}

# 删除生成的内容
delete_generated_content() {
    log "Starting cleanup of generated content..."

    # 停止服务
    log "Stopping $SERVICE_NAME..."
    sudo systemctl stop "$SERVICE_NAME" 2>/dev/null || log "Warning: Failed to stop $SERVICE_NAME"

    # 禁用服务
    log "Disabling $SERVICE_NAME..."
    sudo systemctl disable "$SERVICE_NAME" 2>/dev/null || log "Warning: Failed to disable $SERVICE_NAME"

    # 删除服务文件
    if [ -f "${SERVICE_DIR}/${SERVICE_NAME}" ]; then
        log "Removing ${SERVICE_DIR}/${SERVICE_NAME}..."
        sudo rm -f "${SERVICE_DIR}/${SERVICE_NAME}" || log "Error: Failed to remove ${SERVICE_DIR}/${SERVICE_NAME}"
    fi

    # 删除脚本文件
    if [ -f "$SCRIPT_PATH" ]; then
        log "Removing $SCRIPT_PATH..."
        sudo rm -f "$SCRIPT_PATH" || log "Error: Failed to remove $SCRIPT_PATH"
    fi

    # 删除清理脚本
    if [ -f "$CLEANUP_SCRIPT" ]; then
        log "Removing $CLEANUP_SCRIPT..."
        sudo rm -f "$CLEANUP_SCRIPT" || log "Error: Failed to remove $CLEANUP_SCRIPT"
    fi

    # 删除清理服务和定时器
    log "Stopping and disabling socat-cleanup.timer..."
    sudo systemctl stop socat-cleanup.timer 2>/dev/null || log "Warning: Failed to stop socat-cleanup.timer"
    sudo systemctl disable socat-cleanup.timer 2>/dev/null || log "Warning: Failed to disable socat-cleanup.timer"

    for file in "$CLEANUP_TIMER" "$CLEANUP_SERVICE"; do
        if [ -f "$file" ]; then
            log "Removing $file..."
            sudo rm -f "$file" || log "Error: Failed to remove $file"
        fi
    done

    # 清理残留的 socat 进程
    log "Cleaning up residual socat processes..."
    for port in "${LOCAL[@]}"; do
        port_num=$(echo "$port" | sed 's/.*:\([0-9]\+\)$/\1/')
        pids=$(pgrep -f "socat.*LISTEN:$port_num" 2>/dev/null)
        if [ -n "$pids" ]; then
            sudo kill -TERM $pids 2>/dev/null || log "Warning: Failed to kill socat processes on port $port_num"
        fi
    done

    # 清理日志
    if [ -f "$CLEANUP_LOG" ]; then
        log "Removing $CLEANUP_LOG..."
        sudo rm -f "$CLEANUP_LOG" || log "Warning: Failed to remove $CLEANUP_LOG"
    fi

    # 清理 logrotate 配置
    LOGROTATE_CONF="/etc/logrotate.d/socat_cleanup"
    if [ -f "$LOGROTATE_CONF" ]; then
        log "Removing $LOGROTATE_CONF..."
        sudo rm -f "$LOGROTATE_CONF" || log "Error: Failed to remove $LOGROTATE_CONF"
    fi

    # 清理锁文件
    if [ -f "$LOCK_FILE" ]; then
        log "Removing $LOCK_FILE..."
        sudo rm -f "$LOCK_FILE" || log "Warning: Failed to remove $LOCK_FILE"
    fi

    # 重新加载 systemd
    log "Reloading systemd daemon..."
    sudo systemctl daemon-reload || log "Error: Failed to reload systemd"

    log "Cleanup completed."
    exit 0
}

# 生成 socat 启动脚本
generate_socat_script() {
    log "Generating socat script at $SCRIPT_PATH"
    if [ ${#LOCAL[@]} -ne ${#TARGETS[@]} ]; then
        log "Error: LOCAL and TARGETS arrays have different lengths"
        exit 1
    fi
    cat << EOF > "$SCRIPT_PATH"
#!/bin/bash

# 清理可能残留的 socat 进程
echo "Cleaning up residual socat processes..."
sleep 1

# 启动所有 socat 实例
EOF

    for i in "${!LOCAL[@]}"; do
        local_entry="${LOCAL[$i]}"
        target="${TARGETS[$i]}"

        if [[ "$local_entry" =~ ^\[::\]:[0-9]+$ ]]; then
            listen_addr="[::]"
            listen_port=$(echo "$local_entry" | sed 's/^\[::\]:\([0-9]\+\)$/\1/')
            listen_type="6"
        elif [[ "$local_entry" =~ ^:[0-9]+$ ]]; then
            listen_addr="0.0.0.0"
            listen_port=$(echo "$local_entry" | sed 's/^:\([0-9]\+\)$/\1/')
            listen_type="4"
        else
            log "Error: Invalid local format: $local_entry"
            continue
        fi

        if [[ "$target" =~ ^\[.*\]:[0-9]+$ ]]; then
            target_addr=$(echo "$target" | sed 's/^\[\(.*\)\]:[0-9]\+$/\1/')
            target_port=$(echo "$target" | sed 's/^.*:\([0-9]\+\)$/\1/')
            target_type="6"
        else
            log "Error: Invalid target format: $target"
            continue
        fi

        cat << EOF >> "$SCRIPT_PATH"
echo "Starting TCP $listen_type -> $target_type, $listen_port -> $target_port"
/usr/bin/socat TCP${listen_type}-LISTEN:${listen_port},fork,reuseaddr,max-children=50 TCP${target_type}:[${target_addr}]:${target_port} &
echo "Starting UDP $listen_type -> $target_type, $listen_port -> $target_port"
/usr/bin/socat UDP${listen_type}-LISTEN:${listen_port},fork,reuseaddr,max-children=50 UDP${target_type}:[${target_addr}]:${target_port} &
EOF
    done

    cat << EOF >> "$SCRIPT_PATH"
wait
EOF

    sudo chmod +x "$SCRIPT_PATH" || { log "Error: Failed to chmod $SCRIPT_PATH"; exit 1; }
    log "Generated script: $SCRIPT_PATH"
}

# 生成清理脚本
generate_cleanup_script() {
    log "Generating cleanup script at $CLEANUP_SCRIPT"
    # 提前生成端口号列表
    SOCAT_PORTS=()
    for entry in "${LOCAL[@]}"; do
        port=$(echo "$entry" | sed 's/.*:\([0-9]\+\)$/\1/')
        SOCAT_PORTS+=("$port")
    done
    # 将端口号列表转换为字符串，用于嵌入脚本
    PORTS_STR=$(printf '%s ' "${SOCAT_PORTS[@]}")

    cat << EOF > "$CLEANUP_SCRIPT"
#!/bin/bash

# 清理脚本：socat_cleanup.sh
# 用途：检查并终止空闲的 socat 子进程，保护父进程不被杀死

IDLE_TIMEOUT=\${IDLE_TIMEOUT:-300}
MONITOR_SECONDS=5

# 日志函数
log() {
    local log_file="\${LOG_FILE:-/var/log/socat_cleanup.log}"
    local timestamp
    timestamp=\$(date '+%Y-%m-%d %H:%M:%S.%3N')
    stdbuf -oL echo "[\$timestamp] \$1" | tee -a "\$log_file"
    sync
}

SOCAT_PORTS=($PORTS_STR)
LOG_FILE="$CLEANUP_LOG"
LOCK_FILE="$LOCK_FILE"

# 检查锁文件，防止重复运行
if [ -z "\$LOCK_FILE" ]; then
    log "Error: LOCK_FILE is not set"
    exit 1
fi
if [ -f "\$LOCK_FILE" ]; then
    log "Error: Cleanup script already running (lock file exists: \$LOCK_FILE)"
    exit 1
fi
touch "\$LOCK_FILE"
trap 'rm -f "\$LOCK_FILE"; exit' EXIT INT TERM

# 检查依赖
if ! command -v tcpdump >/dev/null; then
    log "Error: 'tcpdump' command not found. Please install tcpdump."
    exit 1
fi
if ! command -v pgrep >/dev/null; then
    log "Error: 'pgrep' command not found. Please install procps."
    exit 1
fi
if ! command -v ps >/dev/null; then
    log "Error: 'ps' command not found. Please install procps."
    exit 1
fi

# 找到 socat_forward.sh 的 PID
script_pid=\$(pgrep -f "/bin/bash /usr/local/bin/socat_forward.sh" 2>/dev/null)
if [ -z "\$script_pid" ]; then
    log "Warning: Could not find socat_forward.sh process, assuming systemd parent"
    script_pid=1
fi

log "Starting socat cleanup..."
log "Monitoring ports: \${SOCAT_PORTS[*]}"

killed_count=0
for port in "\${SOCAT_PORTS[@]}"; do
    log "Checking socat processes on port \$port..."
    pids=\$(pgrep -f "socat.*LISTEN:\$port,.*fork" 2>/dev/null)
    if [ -z "\$pids" ]; then
        log "No socat processes found for port \$port"
        continue
    fi

    for pid in \$pids; do
        # 检查 PPID
        ppid=\$(ps -p "\$pid" -o ppid= 2>/dev/null | tr -d ' ')
        if [ -z "\$ppid" ]; then
            log "Warning: Failed to get PPID for PID \$pid, skipping"
            continue
        fi
        # 父进程的 PPID 应为 socat_forward.sh 的 PID 或 1
        if [ "\$ppid" -eq "\$script_pid" ] || [ "\$ppid" -eq 1 ]; then
            log "Skipping parent process PID \$pid (port \$port, PPID \$ppid)"
            continue
        fi

        # 获取进程启动时间
        start_time=\$(ps -p "\$pid" -o start= 2>/dev/null)
        if [ -z "\$start_time" ]; then
            log "Warning: Failed to get start time for PID \$pid"
            continue
        fi
        start_epoch=\$(date -d "\$start_time" +%s 2>/dev/null)
        current_epoch=\$(date +%s)
        elapsed=\$((current_epoch - start_epoch))
        if [ -z "\$elapsed" ] || [ "\$elapsed" -lt 0 ]; then
            log "Warning: Failed to calculate elapsed time for PID \$pid"
            continue
        fi

        # 检查是否为 UDP 进程
        is_udp=\$(ps -p "\$pid" -o cmd= | grep -q "UDP" && echo "yes" || echo "no")

        # 判断是否空闲
        if [ "\$is_udp" = "yes" ]; then
            if [ "\$elapsed" -gt "\$IDLE_TIMEOUT" ]; then
                log "Killing idle UDP socat child process PID \$pid (port \$port, elapsed: \$elapsed seconds)"                sudo kill -TERM "\$pid" 2>/dev/null
                if [ \$? -eq 0 ]; then
                    log "Successfully killed PID \$pid"
                    ((killed_count++))
                else
                    log "Error: Failed to kill PID \$pid"
                fi
            else
                log "Skipping UDP child PID \$pid (port \$port, elapsed: \$elapsed seconds)"
            fi
        else
            has_traffic=0
            sudo timeout "\$MONITOR_SECONDS" tcpdump -i any "tcp port \$port and not (tcp[tcpflags] & tcp-ack != 0 and tcp[tcpflags] & (tcp-push|tcp-fin|tcp-syn|tcp-rst) = 0)" --immediate-mode -c 10 2>/dev/null | grep . >/dev/null && has_traffic=1
            if [ \$has_traffic -eq 0 ] && [ "\$elapsed" -gt "\$IDLE_TIMEOUT" ]; then
                log "Killing idle TCP socat child process PID \$pid (port \$port, elapsed: \$elapsed seconds)"                sudo kill -TERM "\$pid" 2>/dev/null
                if [ \$? -eq 0 ]; then
                    log "Successfully killed PID \$pid"
                    ((killed_count++))
                else
                    log "Error: Failed to kill PID \$pid"
                fi
            else
                log "Skipping TCP child PID \$pid (port \$port, elapsed: \$elapsed seconds, has_traffic: \$has_traffic)"
            fi
        fi
    done
done

if [ "\$killed_count" -gt 5 ]; then
    log "Warning: Killed \$killed_count idle child processes, check configuration"
fi

log "Cleanup completed."
EOF

    sudo chmod +x "$CLEANUP_SCRIPT" || { log "Error: Failed to chmod $CLEANUP_SCRIPT"; exit 1; }
    log "Generated cleanup script: $CLEANUP_SCRIPT"
}

# 生成清理服务和定时器
generate_cleanup_service() {
    log "Generating cleanup service at $CLEANUP_SERVICE"
    cat << EOF > "$CLEANUP_SERVICE"
[Unit]
Description=Socat Cleanup Service

[Service]
ExecStart=$CLEANUP_SCRIPT
Environment="IDLE_TIMEOUT=300"
EOF

    log "Generating cleanup timer at $CLEANUP_TIMER"
    cat << EOF > "$CLEANUP_TIMER"
[Unit]
Description=Run socat cleanup every 5 minutes

[Timer]
OnCalendar=*:0/5
Persistent=true
Unit=socat-cleanup.service

[Install]
WantedBy=timers.target
EOF

    sudo systemctl daemon-reload || { log "Error: Failed to reload systemd for cleanup service"; exit 1; }
    sudo systemctl enable socat-cleanup.timer || { log "Error: Failed to enable socat-cleanup.timer"; exit 1; }
    sudo systemctl start socat-cleanup.timer || { log "Error: Failed to start socat-cleanup.timer"; exit 1; }
    log "Cleanup service and timer enabled"
}

# 生成 logrotate 配置
generate_logrotate() {
    local logrotate_conf="/etc/logrotate.d/socat_cleanup"
    log "Generating logrotate config at $logrotate_conf"
    cat << EOF > "$logrotate_conf"
$CLEANUP_LOG {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0644 root root
}
EOF
    log "Logrotate config generated"
}

# 生成单一服务文件
generate_service() {
    log "Generating service file at ${SERVICE_DIR}/${SERVICE_NAME}"
    cat << EOF > "${SERVICE_DIR}/${SERVICE_NAME}"
[Unit]
Description=Socat TCP and UDP Forwarding Service
After=network.target

[Service]
ExecStart=${SCRIPT_PATH}
Restart=always
User=root
Group=root
KillMode=control-group
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    log "Generated service: ${SERVICE_NAME}"
}

# 停止并删除旧服务
stop_and_remove_old_services() {
    log "Stopping and removing old socat services..."
    local success=true
    for service in ${SERVICE_DIR}/socat-*.service; do
        if [ -f "$service" ]; then
            service_name=$(basename "$service")
            log "Stopping $service_name"
            sudo systemctl stop "$service_name" 2>/dev/null || log "Warning: Failed to stop $service_name"
            log "Disabling $service_name"
            sudo systemctl disable "$service_name" 2>/dev/null || log "Warning: Failed to disable $service_name"
            log "Removing $service"
            sudo rm -f "$service" || { log "Error: Failed to remove $service"; success=false; }
        fi
    done
    log "Cleaning residual socat processes..."
    for port in "${LOCAL[@]}"; do
        port_num=$(echo "$port" | sed 's/.*:\([0-9]\+\)$/\1/')
        pids=$(pgrep -f "socat.*LISTEN:$port_num" 2>/dev/null)
        if [ -n "$pids" ]; then
            sudo kill -TERM $pids 2>/dev/null || log "Warning: Failed to kill socat processes on port $port_num"
        fi
    done
    log "Cleanup completed"
    $success || return 1
    return 0
}

# 检查参数
if [ "$1" == "--del" ]; then
    delete_generated_content
fi

# 主逻辑
log "Starting script execution..."
check_dependencies || { log "Error: Dependency check failed"; exit 1; }
stop_and_remove_old_services || { log "Error: Failed in stop_and_remove_old_services"; exit 1; }

log "Debug: LOCAL and TARGETS content:"
for i in "${!LOCAL[@]}"; do
    log "  ${LOCAL[$i]} -> ${TARGETS[$i]}"
done

generate_socat_script || { log "Error: Failed in generate_socat_script"; exit 1; }
generate_cleanup_script || { log "Error: Failed in generate_cleanup_script"; exit 1; }
generate_cleanup_service || { log "Error: Failed in generate_cleanup_service"; exit 1; }
generate_logrotate || { log "Error: Failed in generate_logrotate"; exit 1; }
generate_service || { log "Error: Failed in generate_service"; exit 1; }

log "Reloading systemd daemon..."
sudo systemctl daemon-reload || { log "Error: Failed to reload systemd"; exit 1; }
log "Enabling ${SERVICE_NAME}..."
sudo systemctl enable "$SERVICE_NAME" || { log "Error: Failed to enable ${SERVICE_NAME}"; exit 1; }
log "Starting ${SERVICE_NAME}..."
sudo systemctl start "$SERVICE_NAME" || { log "Error: Failed to start ${SERVICE_NAME}"; exit 1; }
log "Enabled and started ${SERVICE_NAME}"

log "All services, cleanup script, and timer generated."
