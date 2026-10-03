#!/bin/bash

# ============================================================
# NETWORK MACHINE
# Agent Network V1
# Prototype Bash
# ============================================================

BASE_DIR="$HOME/network-machine"

REGISTRY="$BASE_DIR/registry/agents.db"
MESSAGES="$BASE_DIR/messages"
TRACES="$BASE_DIR/traces"

mkdir -p "$BASE_DIR"
mkdir -p "$MESSAGES"
mkdir -p "$TRACES"
mkdir -p "$BASE_DIR/registry"

# ============================================================
# UTILITAIRES
# ============================================================

timestamp() {
    date +%s
}

generate_trace_id() {
    printf "%s-%s\n" "$(date +%s)" "$RANDOM"
}

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

# ============================================================
# REGISTRE DES AGENTS
# ============================================================

register_agent() {

    local AGENT_ID="$1"
    local CAPABILITY="$2"

    mkdir -p "$MESSAGES/$AGENT_ID"

    # Supprimer ancienne déclaration
    sed -i.bak "/^$AGENT_ID|/d" "$REGISTRY" 2>/dev/null

    echo "$AGENT_ID|$CAPABILITY|online" >> "$REGISTRY"

    log "Agent enregistré : $AGENT_ID"
    log "Capacité          : $CAPABILITY"
}

# ============================================================
# HEARTBEAT
# ============================================================

heartbeat() {

    local AGENT_ID="$1"

    if grep -q "^$AGENT_ID|" "$REGISTRY"; then

        sed -i.bak "s/^$AGENT_ID|[^|]*|[^|]*/$AGENT_ID|$(get_capability "$AGENT_ID")|online/" "$REGISTRY"

    fi
}

# ============================================================
# CAPACITÉ
# ============================================================

get_capability() {

    local AGENT_ID="$1"

    grep "^$AGENT_ID|" "$REGISTRY" |
        head -1 |
        cut -d'|' -f2
}

# ============================================================
# TROUVER UN AGENT PAR CAPACITÉ
# ============================================================

find_agent() {

    local CAPABILITY="$1"

    grep "|$CAPABILITY|" "$REGISTRY" |
        grep "|online$" |
        head -1 |
        cut -d'|' -f1
}

# ============================================================
# ENVOI DIRECT
# ============================================================

send_message() {

    local FROM="$1"
    local TO="$2"
    local TRACE_ID="$3"
    local EVENT="$4"
    local DATA="$5"

    local MESSAGE_DIR="$MESSAGES/$TO"

    mkdir -p "$MESSAGE_DIR"

    local MESSAGE_FILE="$MESSAGE_DIR/${TRACE_ID}.msg"

    cat > "$MESSAGE_FILE" <<EOF
trace_id=$TRACE_ID
from=$FROM
to=$TO
timestamp=$(timestamp)
event=$EVENT
data=$DATA
EOF

    log "$FROM → $TO"
    log "TRACE : $TRACE_ID"
    log "EVENT : $EVENT"

    trace "$TRACE_ID" "$FROM" "$TO" "$EVENT"
}

# ============================================================
# TRACE DISTRIBUÉE
# ============================================================

trace() {

    local TRACE_ID="$1"
    local FROM="$2"
    local TO="$3"
    local EVENT="$4"

    local TRACE_FILE="$TRACES/$TRACE_ID.log"

    echo "$(date '+%Y-%m-%d %H:%M:%S') | $FROM | $TO | $EVENT" \
        >> "$TRACE_FILE"
}

# ============================================================
# AGENT CONNECTION
# ============================================================

connection_agent() {

    local TRACE_ID="$1"

    log "CONNECTION AGENT"
    log "Observation d'une connexion réseau."

    local PROCESS="node"
    local IP="142.250.74.14"
    local PORT="443"

    log "Processus : $PROCESS"
    log "Destination : $IP:$PORT"

    local DNS_AGENT

    DNS_AGENT=$(find_agent "dns.resolve")

    if [[ -z "$DNS_AGENT" ]]; then

        log "DNS agent indisponible."

        send_message \
            "connection-01" \
            "memory-01" \
            "$TRACE_ID" \
            "connection.observed" \
            "$PROCESS|$IP|$PORT"

        return

    fi

    send_message \
        "connection-01" \
        "$DNS_AGENT" \
        "$TRACE_ID" \
        "dns.resolve.request" \
        "$PROCESS|$IP|$PORT"
}

# ============================================================
# AGENT DNS
# ============================================================

dns_agent() {

    local MESSAGE="$1"

    local TRACE_ID
    TRACE_ID=$(grep '^trace_id=' "$MESSAGE" | cut -d'=' -f2)

    local DATA
    DATA=$(grep '^data=' "$MESSAGE" | cut -d'=' -f2-)

    local PROCESS
    PROCESS=$(echo "$DATA" | cut -d'|' -f1)

    local IP
    IP=$(echo "$DATA" | cut -d'|' -f2)

    local PORT
    PORT=$(echo "$DATA" | cut -d'|' -f3)

    log "DNS AGENT"
    log "Recherche : $IP"

    # Prototype.
    # Plus tard : vraie résolution DNS inverse.

    local DOMAIN="example.com"

    log "Résultat : $DOMAIN"

    local MEMORY_AGENT

    MEMORY_AGENT=$(find_agent "history.store")

    if [[ -z "$MEMORY_AGENT" ]]; then

        log "Memory agent indisponible."

        return

    fi

    send_message \
        "dns-01" \
        "$MEMORY_AGENT" \
        "$TRACE_ID" \
        "connection.enriched" \
        "$PROCESS|$IP|$PORT|$DOMAIN"
}

# ============================================================
# AGENT MEMORY
# ============================================================

memory_agent() {

    local MESSAGE="$1"

    local TRACE_ID
    TRACE_ID=$(grep '^trace_id=' "$MESSAGE" | cut -d'=' -f2)

    local DATA
    DATA=$(grep '^data=' "$MESSAGE" | cut -d'=' -f2-)

    log "MEMORY AGENT"

    local MEMORY_FILE="$BASE_DIR/memory.db"

    mkdir -p "$BASE_DIR"

    if grep -q "$DATA" "$MEMORY_FILE" 2>/dev/null; then

        log "Comportement connu."

        STATUS="known"

    else

        echo "$(date +%s)|$DATA" >> "$MEMORY_FILE"

        log "Nouvelle observation mémorisée."

        STATUS="new"

    fi

    local SECURITY_AGENT

    SECURITY_AGENT=$(find_agent "security.analyze")

    if [[ -z "$SECURITY_AGENT" ]]; then

        log "Security agent indisponible."

        return

    fi

    send_message \
        "memory-01" \
        "$SECURITY_AGENT" \
        "$TRACE_ID" \
        "behavior.analyze" \
        "$STATUS|$DATA"
}

# ============================================================
# AGENT SECURITY
# ============================================================

security_agent() {

    local MESSAGE="$1"

    local TRACE_ID
    TRACE_ID=$(grep '^trace_id=' "$MESSAGE" | cut -d'=' -f2)

    local DATA
    DATA=$(grep '^data=' "$MESSAGE" | cut -d'=' -f2-)

    STATUS=$(echo "$DATA" | cut -d'|' -f1)

    log "SECURITY AGENT"

    if [[ "$STATUS" == "new" ]]; then

        log "ÉVÉNEMENT : nouveau comportement réseau."

        CONCLUSION="Nouvelle communication détectée. Elle doit être corrélée avec le contexte avant toute conclusion."

    else

        log "Comportement déjà connu."

        CONCLUSION="Communication correspondant à un comportement précédemment observé."

    fi

    echo
    echo "=========================================="
    echo "CONCLUSION"
    echo "=========================================="
    echo "$CONCLUSION"
    echo
    echo "TRACE : $TRACE_ID"
    echo "=========================================="

    trace \
        "$TRACE_ID" \
        "security-01" \
        "local" \
        "analysis.completed"
}

# ============================================================
# TRAITEMENT DES MESSAGES
# ============================================================

process_messages() {

    for AGENT_DIR in "$MESSAGES"/*
    do

        [[ ! -d "$AGENT_DIR" ]] && continue

        AGENT=$(basename "$AGENT_DIR")

        for MESSAGE in "$AGENT_DIR"/*.msg
        do

            [[ ! -f "$MESSAGE" ]] && continue

            case "$AGENT" in

                dns-01)
                    dns_agent "$MESSAGE"
                    ;;

                memory-01)
                    memory_agent "$MESSAGE"
                    ;;

                security-01)
                    security_agent "$MESSAGE"
                    ;;

            esac

            rm -f "$MESSAGE"

        done

    done
}

# ============================================================
# INITIALISATION
# ============================================================

initialize() {

    touch "$REGISTRY"

    register_agent \
        "connection-01" \
        "connections.observe"

    register_agent \
        "dns-01" \
        "dns.resolve"

    register_agent \
        "memory-01" \
        "history.store"

    register_agent \
        "security-01" \
        "security.analyze"
}

# ============================================================
# LANCEMENT
# ============================================================

case "$1" in

    init)

        initialize

        ;;

    observe)

        initialize

        TRACE_ID=$(generate_trace_id)

        echo
        echo "=========================================="
        echo " NETWORK MACHINE"
        echo " OBSERVATION"
        echo "=========================================="
        echo

        connection_agent "$TRACE_ID"

        process_messages

        echo
        echo "Observation terminée."
        echo "TRACE : $TRACE_ID"

        ;;

    agents)

        echo
        echo "AGENTS"
        echo "------"

        cat "$REGISTRY"

        ;;

    trace)

        TRACE_ID="$2"

        if [[ -f "$TRACES/$TRACE_ID.log" ]]; then

            cat "$TRACES/$TRACE_ID.log"

        else

            echo "Trace inconnue."

        fi

        ;;

    *)

        echo
        echo "Usage:"
        echo
        echo "  ./machine.sh init"
        echo "  ./machine.sh agents"
        echo "  ./machine.sh observe"
        echo "  ./machine.sh trace TRACE_ID"
        echo

        ;;

esac
