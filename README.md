# docker-startup-check

This bash script will look for docker containers that have exited and attempt to start them unless they exited gracefully (Exited(0))

## config
schedule in crontab with `crontab -e`

example running the script every 5 minutes:
```
*/5 * * * * /path/to/docker-startup-check.sh
```