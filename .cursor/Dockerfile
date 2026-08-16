# Development image for RH_Manager (Flutter mobile app + dual PostgreSQL/Supabase backend).
# Base already contains Flutter 3.41.8 (matching .github/workflows/build-apk.yml),
# the Android SDK (build-tools, platforms, licenses accepted) and a compatible JDK,
# so `flutter build apk` works out of the box.
FROM ghcr.io/cirruslabs/flutter:3.41.8

# System dependencies:
# - postgresql/-contrib: local "BackendMode.local" database (rh_manager on :5432)
# - the rest are small utilities used by the setup scripts.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql \
        postgresql-contrib \
        ca-certificates \
        curl \
        sudo \
    && rm -rf /var/lib/apt/lists/*

# Supabase CLI: used for migrations and the online "BackendMode.supabase" project.
# NOTE: the full local stack (`supabase start`) additionally requires Docker,
# which is not provided here; local development uses the plain PostgreSQL above.
ARG SUPABASE_CLI_VERSION=v2.114.0
RUN curl -fsSL -o /tmp/supabase.tar.gz \
        "https://github.com/supabase/cli/releases/download/${SUPABASE_CLI_VERSION}/supabase_linux_amd64.tar.gz" \
    && tar -xzf /tmp/supabase.tar.gz -C /usr/local/bin supabase \
    && rm /tmp/supabase.tar.gz \
    && supabase --version
