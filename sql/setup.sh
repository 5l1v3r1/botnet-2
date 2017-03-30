# as root
createuser -P squid
createdb -O squid squid
psql squid < pg_ext_setup.sql
psql -h localhost -U squid squid < pg_schema.sql
psql -h localhost -U squid squid < pg_data.sql
psql -h localhost -U squid squid < pg_view.sql
