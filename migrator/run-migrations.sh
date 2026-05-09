#!/bin/bash

SQLCMD=/opt/mssql-tools/bin/sqlcmd

# CREATE LOGIN requires the password inline. Passing it via sqlcmd -v is unreliable in the
# mssql-tools image, so this server-level object is bootstrapped here. The SQL migrations
# then handle CREATE USER ... FOR LOGIN and GRANT, which need no password.
"$SQLCMD" -S db -U sa -P "$AA_TASK_MSSQL_SA_PASSWORD" -b -Q "
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'smr_app')
    CREATE LOGIN smr_app WITH PASSWORD = '${AA_TASK_APP_PASSWORD}',
        CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;"
if [ $? -ne 0 ]; then
    echo "Failed to bootstrap smr_app login"
    exit 1
fi

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
