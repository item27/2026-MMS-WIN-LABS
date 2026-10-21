@echo off
dsquery user "OU=unit-for-delete,DC=GMAKMA,DC=local" -limit 0 | dsrm -noprompt
