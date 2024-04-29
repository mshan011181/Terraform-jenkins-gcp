#!/bin/bash

# Define Oracle environment variables
export ORACLE_SID=ORCLCDB
export ORACLE_HOME=/opt/oracle/product/21c/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH

# Define SQL queries
queries=(
    "SELECT name from FROM v\$database;"
    "SELECT username  FROM dba_users;"    
)

# Execute SQL queries using SQL*Plus
for query in "${queries[@]}"; do
    echo "Executing query: $query"
    echo "$query" | sqlplus -S sys/Shan9871 as sysdba
done

