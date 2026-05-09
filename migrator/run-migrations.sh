#!/bin/bash

SQLCMD=/opt/mssql-tools/bin/sqlcmd

shopt -s nullglob
files=(/migrations/*.sql)
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
    echo "No migration scripts found in /migrations/. Nothing to do."
    exit 0
fi

for f in "${files[@]}"; do
    echo "Applying: $f"
    "$SQLCMD" -S db -U sa -P "$AA_TASK_MSSQL_SA_PASSWORD" -b -i "$f"
    if [ $? -ne 0 ]; then
        echo "Migration failed: $f"
        exit 1
    fi
    echo "Applied: $f"
done

exit 0
