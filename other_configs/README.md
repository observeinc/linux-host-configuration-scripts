# Additional configurations

## Telegraf ethtool plugin

The ethtool output plugin collects additional metrics from network interfaces. This is particularly useful to collect the advanced network performance metrics from ENA interfaces on Amazon Linux.

To use, copy the `telegraf-ethtool.conf` file into the `/etc/telegraf/telegraf.d/` directory, then restart telegraf.
