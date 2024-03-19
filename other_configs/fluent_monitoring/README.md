# Instructions for adding fluent bit monitoring

In fluent-bit.conf - in the SERVICE stanza fo the following:
- set http server to On ```http_server  On```
- add multiline parser ```parsers_file parsers_multiline.conf```

## Manual configuration - For all platforms
Add the following files to to the /etc/fluent-bit directory and restart fluent-bit service:
- linux-host-configuration-scripts/other_configs/fluent_monitoring/observe-monitoring-all-platforms.conf file
- linux-host-configuration-scripts/other_configs/fluent_monitoring/parsers_multiline.conf

```

export OBSERVE_TOKEN="[OBSERVE_TOKEN]"
export OBSERVE_ENDPOINT=[URL]  # "https://[OBSERVE_CUSTOMER_ID].collect.observeinc.com"
OBSERVE_ENVIRONMENT="${${OBSERVE_ENDPOINT}#https://}"

sed -i "s/REPLACE_WITH_CUSTOMER_INGEST_TOKEN/${OBSERVE_TOKEN}/g" ./*

sed -i "s/REPLACE_WITH_OBSERVE_ENVIRONMENT/${OBSERVE_ENVIRONMENT}/g" ./*

sudo service fluent-bit restart
```

## Manual configuration - Linux only - input specific metrics
Do steps above but also add the following files to  /etc/fluent-bit:
- linux-host-configuration-scripts/other_configs/fluent_monitoring/observe-monitoring-linux-only.conf

