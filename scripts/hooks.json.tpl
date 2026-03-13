[
  {
    "id": "rebuild",
    "execute-command": "/var/www/cattery/scripts/rebuild.sh",
    "command-working-directory": "/var/www/cattery",
    "trigger-rule": {
      "match": {
        "type": "value",
        "value": "${REBUILD_TOKEN}",
        "parameter": {
          "source": "header",
          "name": "X-Rebuild-Token"
        }
      }
    }
  }
]
