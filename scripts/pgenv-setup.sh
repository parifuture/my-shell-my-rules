#!/usr/bin/env bash
# Bootstrap local postgres (pgenv) with the build flags + extensions this machine needs.
# Idempotent: safe to re-run. Installs postgres 17.9, builds pgvector from source against
# pgenv's postgres (brew's pgvector is linked to brew's postgres, wrong install), enables
# uuid-ossp + citext + vector in template1 so all future databases inherit them, and
# creates a login role matching the current macOS user.
#
# Requires: brew and a git-cloned pgenv at ~/.pgenv (README has the clone step).

set -euo pipefail

PG_VERSION="${PG_VERSION:-17.9}"
PGENV_ROOT="$HOME/.pgenv"

if [[ ! -d "$PGENV_ROOT" ]]; then
  echo "error: $PGENV_ROOT not found — clone pgenv first (see README)" >&2
  exit 1
fi

# Brew build deps. icu4c is keg-only, util-linux provides libuuid (required for
# uuid-ossp on macOS — see note below).
brew list pkg-config  >/dev/null 2>&1 || brew install pkg-config
brew list icu4c       >/dev/null 2>&1 || brew install icu4c
brew list util-linux  >/dev/null 2>&1 || brew install util-linux

export PATH="$PGENV_ROOT/bin:$PGENV_ROOT/pgsql/bin:$PATH"

# Build-time flags.
# ICU: keg-only, point the compiler/linker at it.
# util-linux: provides libuuid for postgres's --with-uuid=e2fs. This is the only
# macOS-compatible option — `--with-uuid=bsd` fails because macOS's libc BSD UUID
# functions don't match the signatures postgres expects ("BSD UUID functions are
# not present"), and `--with-uuid=ossp` (via brew's ossp-uuid) fails because its
# header defines `uuid_t` which collides with the macOS SDK's own `uuid_t` typedef
# in <sys/_types/_uuid_t.h>.
export PKG_CONFIG_PATH="/opt/homebrew/opt/icu4c@78/lib/pkgconfig:/opt/homebrew/opt/util-linux/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export LDFLAGS="-L/opt/homebrew/opt/icu4c@78/lib -L/opt/homebrew/opt/util-linux/lib"
export CPPFLAGS="-I/opt/homebrew/opt/icu4c@78/include -I/opt/homebrew/opt/util-linux/include"

# Build if not already built. pgenv auto-generates a fresh config file on build
# and overrides shell-exported PGENV_CONFIGURE_OPTIONS, so we seed the config
# file directly before invoking build.
if [[ ! -d "$PGENV_ROOT/pgsql-$PG_VERSION" ]]; then
  echo "==> Building postgres $PG_VERSION (this compiles from source, several minutes)..."
  mkdir -p "$PGENV_ROOT/config"
  cat > "$PGENV_ROOT/config/$PG_VERSION.conf" <<EOF
export PGENV_MAKE='/usr/bin/make'
declare -a PGENV_MAKE_OPTIONS=([0]="-j3")
export PGENV_MAKE_OPTIONS
declare -ax PGENV_CONFIGURE_OPTIONS=([0]="--with-uuid=e2fs")
export PGENV_CONFIGURE_OPTIONS
EOF
  pgenv build "$PG_VERSION"
fi

# Activate — starts the server and runs initdb on first use.
pgenv use "$PG_VERSION"

# Wait until the server is actually accepting connections.
for i in {1..20}; do
  if psql -U postgres -d postgres -c '\q' 2>/dev/null; then break; fi
  sleep 0.5
done

# Create a login role matching the current user, if missing.
# pgenv's initdb only creates the `postgres` superuser — unlike brew's postgres
# formula which creates one per current macOS user.
psql -U postgres -d postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$USER';" | grep -q 1 \
  || psql -U postgres -d postgres -c \
       "CREATE ROLE \"$USER\" WITH LOGIN SUPERUSER CREATEDB CREATEROLE;"

# Build and install pgvector from source against pgenv's postgres, if not already present.
# We cannot use brew's pgvector — it's built against brew's postgres headers and drops its
# .so into brew's postgres lib dir, which pgenv's postgres never sees. So we clone, compile
# with PG_CONFIG pointed at pgenv, and install straight into the pgenv install tree.
PGVECTOR_CONTROL="$PGENV_ROOT/pgsql-$PG_VERSION/share/extension/vector.control"
if [[ ! -f "$PGVECTOR_CONTROL" ]]; then
  echo "==> Building pgvector from source against pgenv postgres..."
  PGVECTOR_SRC="$(mktemp -d)/pgvector"
  git clone --depth 1 https://github.com/pgvector/pgvector.git "$PGVECTOR_SRC"
  make -C "$PGVECTOR_SRC" PG_CONFIG="$PGENV_ROOT/pgsql/bin/pg_config"
  make -C "$PGVECTOR_SRC" PG_CONFIG="$PGENV_ROOT/pgsql/bin/pg_config" install
  rm -rf "$PGVECTOR_SRC"
fi

# Enable extensions in template1 so every future database inherits them automatically.
# Backstage (and many other apps) rely on uuid-ossp for uuid_generate_v4() etc.
psql -U postgres -d template1 <<'SQL'
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
SQL

echo "==> postgres $PG_VERSION ready. Extensions in template1:"
psql -U postgres -d template1 -c \
  "SELECT extname, extversion FROM pg_extension WHERE extname IN ('uuid-ossp','citext','vector','pg_trgm') ORDER BY extname;"
