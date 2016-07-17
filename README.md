# check_hpdp_pool_health
HP DataProtector nagios check for Pool health status

# Requirements:
* Plugin is written in ruby and works with Version >= 1.8.7
* Cell Managers OS is CentOS/RedHat Version >= 6

# Example:

```
root@dp01:~ # ./check_hpdp_pool_health.rb -h
Usage: check_hpdp_pool_health.rb [options]
    -p, --pool <pool_name>           name of pool to check (regex possible)
    -w <Mediacount warning>          Number of media left raising warning
        --warning
    -c <Mediacount critical>         Number of media left raising critical
        --critical
    -h, --help                       Show this help message
root@dp01:~ #
```

* Check all pools containing "LTO" in their name
```
root@dp01:~ # ./check_hpdp_pool_health.rb -p LTO
OK: All media in pool "LTO-default" in good shape
OK: All media in pool "LTO_freepool" in good shape
OK: All media in pool "LTO-group1" in good shape
OK: All media in pool "LTO-group2" in good shape
root@dp01:~ #
```

* Check pool with custom mediacount threathold
```
root@dp01:~ # ./check_hpdp_pool_health.rb -p local -c 10
CRITICAL: Pool "local" has less/equal 10 writable media left!
root@dp01:~ # ./check_hpdp_pool_health.rb -p local -w 10
WARNING: Pool "local" has less/equal 10 writable media left!
root@dp01:~ #

```
