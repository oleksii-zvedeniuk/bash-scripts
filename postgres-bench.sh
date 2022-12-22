#!/bin/bash

# Script for PostgreSQL queries benchmarking.
# Added support for pre-run and post-run database setup.
# Store queries you want to run in .sql files in directory with the following structure:
#
# .
# |<first query name>.sql
# |<second query name>.sql
# |__setup-scripts/
#    |__pre-<first query name>.sql
#    |__post-<first query name>.sql
#
# Store DB scripts for pre-run and post-run setup into files with pre- and post- prefixes respectively.
# DB setup scripts should be stored in /setup-scripts directory.


# Start of editable section. Change parameters if needed.

# Database connection parameters.
host=
port=
username=
dbname=

# pgbench parameters.
transactions_amount=10

# Individual parameters.
result_filename="$(date +%d-%m-%y_%H-%M-%S)_${dbname}_pgbench.txt"
scripts_abs_path= # Full path to directory containing sql scripts.

# End of editable section.


setup_db() {
    setup_filename="${scripts_abs_path}/setup-scripts/${1}"

    if [[ -e "${setup_filename}" ]]; then
        psql \
            --host="${host}" \
            --port="${port}" \
            --dbname="${dbname}" \
            --username="${username}" \
            --file="${setup_filename}"
    fi
}


pgbench -i \
    --host="${host}" \
    --username="${username}" \
    --unlogged-tables \
    "${dbname}"

for filename in "${scripts_abs_path}/"*.sql; do
    base_name="$(basename "${filename}")"
    setup_db "pre-${base_name}"

    echo "Running benchmark for $base_name query..."
    pgbench \
        --host="${host}" \
        --port="${port}" \
        --username="${username}" \
        --transactions="${transactions_amount}" \
        --file="${filename}" \
        "${dbname}" \
        >> "${result_filename}"
    echo '' >> "${result_filename}"

    setup_db "post-${base_name}"
done

pgbench -i \
    --host="${host}" \
    --username="${username}" \
    -I d \
    "${dbname}"
