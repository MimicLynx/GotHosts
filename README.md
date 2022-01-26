# GotHosts
Simple subnet host discovery tool written in bash. uses nmap and fping to generate a list of active hosts for further enumeration.
***
## Accepts arguments now
You can pass an IP range directly into the script now.

## Help with example usage added
`-h` or invalid options bring up the help now

## Autorecon autostart
`-a` will autostart Autorecon with the found hosts with standard config.
you can add options to Autorecon like so `-a "-v"`.

## Thanks
