#!/bin/bash

# Script to switch between Local PostgreSQL and Online Supabase environments

CONFIG_FILE="flutter_app/lib/app/config.dart"

echo "Select Backend Mode:"
echo "1) Local PostgreSQL"
echo "2) Online Supabase"
read -p "Choice [1-2]: " choice

if [ "$choice" == "1" ]; then
    sed -i 's/BackendMode mode = BackendMode.supabase/BackendMode mode = BackendMode.local/' $CONFIG_FILE
    echo "Environment switched to LOCAL."
elif [ "$choice" == "2" ]; then
    sed -i 's/BackendMode mode = BackendMode.local/BackendMode mode = BackendMode.supabase/' $CONFIG_FILE
    echo "Environment switched to SUPABASE."
else
    echo "Invalid choice."
    exit 1
fi

echo "Done. Please restart your Flutter app."
