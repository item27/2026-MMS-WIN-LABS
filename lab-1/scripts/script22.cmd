@echo off
setlocal EnableExtensions
set /p "MODE=Enter Auto or Manual: "
if /I "%MODE%"=="Auto" (
  netsh interface ipv4 set address name="Lab-Isolated" source=dhcp
  netsh interface ipv4 set dnsservers name="Lab-Isolated" source=dhcp
  echo DHCP enabled for IPv4 and DNS.
) else if /I "%MODE%"=="Manual" (
  netsh interface ipv4 set address name="Lab-Isolated" static 192.168.1.10 255.255.255.0 192.168.1.1
  netsh interface ipv4 set dnsservers name="Lab-Isolated" static 8.8.8.8 primary validate=no
  echo Static IPv4 configuration applied.
) else (
  echo Allowed values: Auto or Manual.
)
endlocal
