#!/bin/bash

# Default parameters to interract with database, change if need.
host='localhost'
port='5432'
dbname='postgres'
username='postgres'

filename=
query=

called_command="${1}"

# Parse command lime arguments.
while :; do
    case $2 in
        -h|--host) 
            if [ "$3" ]; then host=$3; shift; fi
        ;;
        -p|--port)
            if [ "$3" ]; then port=$3; shift; fi         
        ;;
        -db|--dbname)
            if [ "$3" ]; then dbname=$3; shift; fi          
        ;;
        -U|--username)
            if [ "$3" ]; then username=$3; shift; fi          
        ;;
        -f|--filename)
            if [ "$3" ]; then filename=$3; shift; fi 
        ;;
        -q|--query)
	    if [ "$3" ]; then query=$3; shift; fi
	    ;;
        *) break
    esac
    shift
done

# Create database backup.
cmd_dump_db() {
    pg_dump --dbname="${dbname}" \
        --host="${host}" \
        --port="${port}" \
        --username="${username}" \
        | gzip > "${dbname}"-"$(date +%d-%m-%y_%H-%M)".sql.gz
}

# Restore database from file.
cmd_restore_db() {
    if [[ -e "${filename}" ]]; then
        pg_restore --dbname="${dbname}" \
            --host="${host}" \
            --port="${port}" \
            --username="${username}" \
            "${filename}"
    else
        echo "Dump file does not exist."
    fi
}

# Retreive data from table to .csv file
cmd_to_csv() {
    if [[ -n "${query}" ]]; then
        psql --dbname="${dbname}" \
            --host="${host}" \
            --port="${port}" \
            --username="${username}" \
            --tuples-only \
            --no-align \
            --field-separator="," \
            --command="${query}" \
            > "${dbname}"-"$(date +%d-%m-%y_%H-%M)".csv
    else
        echo "Query were not specified."
    fi
}

# Launch specified commands.
case "${called_command}" in
    dump_db|restore_db|to_csv)
        "cmd_${called_command}"
        ;;
    *)
        echo "Error! Unknown command."
        exit 1
        ;;
esac


