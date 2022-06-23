#!/usr/bin/env bash

#Script to automate the starting and stopping of Java Astrolabe application.
#The script should also store the pid
#set -x

check=$(ps -ef | grep java)
regex="java -Xmx6144m -Djava.io"
path=/opt/astrolabe
pid=$(ps -ef | sed -n '/sudo/!{/java -Xmx6144m -Djava\.io\.tmpdir=/s/[^ ]* \+\([^ ]*\).*/\1/p'})
message="No Astrolabe processes were found"
match=$(ps -ef | sed -n "/sed/!{/java/s/.*/$(tput setaf 11)&$(tput sgr 0)/p}")

run_java() {
     nohup java -Xmx6144m -Djava.io.tmpdir="${path}"/tmp -jar "${path}"/Astrolabe.jar > /dev/null 2>&1 &
}

#Start the service function
start() {
    if [[ ! "$check" =~ "$regex" ]]; then
        if [[ "$EUID" = 0 ]]; then
            cd "$path"
            run_java
            if [[ $? -ne 0 ]]; then
                echo "$(tput setaf 1)App did not start$(tput sgr 0)"
                exit 1
            else
                echo "$(tput setaf 2)Java app has successfully started$(tput sgr 0)".
                ps -ef | sed -n "/sudo/ ! {/[^ ]* \+\([^ ]*\).*java -Xmx6144m -Djava.io.tmpdir=.*/s//$(tput setaf 3)&\n$(tput setaf 2)Java is running with PID \1$(tput sgr 0)/p}"
            fi
        else
            sudo -k
            if sudo true; then
                cd "$path"
                sudo nohup java -Xmx6144m -Djava.io.tmpdir="${path}"/tmp -jar "${path}"/Astrolabe.jar > /dev/null 2>&1 &
                if [[ $? -ne 0 ]]; then
                    echo "$(tput setaf 1)App did not start$(tput sgr 0)"
                    exit 1
                else
                    echo "$(tput setaf 2)Java app has successfully started.$(tput sgr 0)"
                    sleep 1
                    ps -ef | sed -n "/sudo/ ! {/[^ ]* \+\([^ ]*\).*java -Xmx6144m -Djava.io.tmpdir=.*/s//$(tput setaf 3)&\n$(tput setaf 2)Java is running with PID \1$(tput sgr 0)/p}"
                fi
            else
                echo "Password Is Incorrect"
                exit 1
            fi
        fi
    else
        echo "$(tput setaf 6)Astrolabe is already running. Aborting startng a second instance...$(tput sgr 0)"
        exit 1
    fi
}

status() {
    ps -ef | sed -n "/sed/!{/java/s/.*/$(tput setaf 11)&$(tput sgr 0)/p}"
    if [[ ! "$match" =~ "java" ]]; then
        echo "$(tput setaf 25)${message}!$(tput sgr 0)"
        exit 0
    fi
}

#Stop the service function
stop() {
    local msg
    msg="$(tput setaf 1)Java app with PID $pid has been successfully killed$(tput sgr 0)"
    if [[ ! "$match" =~ "java" ]]; then
        echo "$(tput setaf 23)$message to kill!$(tput sgr 0)"
        exit 0
    elif [[ "$EUID" = 0 ]]; then
        if kill -9 "$pid"; then
            echo "$msg"
            echo "Please see the status of the app below."
            sleep 2
            ps -ef | grep 'java'
            exit 0
        fi
    else
        sudo -k
        if sudo true; then
            if sudo kill -9 "$pid"; then
                echo "$msg"
                echo "Please see the status of the app below."
                sleep 2
                ps -ef | grep 'java'
                exit 0
            fi
        fi
    fi
}

help() {
    clear
    echo "$(tput setaf 4)This program has been written by Chike Egbuna to automate the starting and stopping of the Java Astrolabe application$(tput sgr 0)"
    echo ""
    echo "astrolabe [OPTIONS...] "
    echo ""
    echo "$(tput sgr 0 1)Unit Commands:$(tput sgr 0)"
    echo "  astrolabe -s             Start Astrolabe"
    echo "  astrolabe -k             Kill/Stop Astrolabe"
    echo "  astrolabe -i             Check Status"
    echo "  astrolabe -h             This Help Menu"
    exit 0
}


if [[ $# -gt 0 ]];then
    #Options
    while getopts 'hski' flag; do
        case "${flag}" in
            h) help ;;
            s) start ;;
            k) stop ;;
            i) status ;;
            *) help
               exit 1 ;;
        esac
     done
else
     help
fi
