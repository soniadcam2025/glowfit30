@echo off
echo Starting SSH tunnel: localhost:5433 -> VPS PostgreSQL 127.0.0.1:5432
echo.
echo Enter SSH password when prompted.
ssh -L 5433:127.0.0.1:5432 sprsadmin@139.84.149.147
