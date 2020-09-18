# Docker Image for bipaaccount

An incomplete image for the account management app for bipaa based on the Symfony framework.
The code itself is not here, it needs to be mounted to proper dirs.

## Configuring the Container

The following environment variables are available:

```
UPLOAD_LIMIT: 20M # Maximum size of uploaded files
MEMORY_LIMIT: 128M # Maximum memory used by PHP

ENABLE_OP_CACHE: 1 # To enable/disable the PHP opcache
```
