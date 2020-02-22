# nagios-plugins
A collection of check scripts compatible with nagios, nrpe, icinga, icinga2.

## HP/MF DataProtector
Scripts for monitoring DataProtector.
### Requirements

* Ruby >= 1.8.7
* CentOS/RedHat >= 6
* Cell Manager >= 6.XX

### check_hpdp_pool_health
HP DataProtector nagios check for Pool health status

**Example**

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

### check_hpdp_pool_size
HP DataProtector nagios check for Pool usage

**Example**

```
root@dp01:~ # ./check_hpdp_pool_size.rb --help
Usage: check_pool.rb [options]
    -p, --pool <pool_name>           name of pool to check (regex possible)
    -w, --warning <percent warning>  Percent space raising warning
    -c <percent critical>            Percent space raising critical
        --critical
    -f, --filter <filter string>     string to group pools
    -h, --help                       Show this help message
root@dp01:~ #
```

* Check single pool
```
root@dp01:~ # ./check_hpdp_pool_size.rb -p ceph_ma1_1weeks
Pool "ceph_ma1_1weeks": 10236GB Total; 2102GB (21%) Used | 'Pool Size ceph_ma1_1weeks'=2102GB;7677.0;9212.4;0;10236
root@dp01:~ #
```

* check Loadbalanced pools and filter / merge their usage together:
```
root@dp01:~ # ./check_hpdp_pool_size.rb -p ceph_ma._1weeks -f 1weeks
Pool "ceph_ma2_1weeks": 2047GB Total; 0GB (0%) Used | 'Pool Size ceph_ma2_1weeks'=0GB;1535.25;1842.3;0;2047
Pool "ceph_ma3_1weeks": 2047GB Total; 2047GB (100%) Used | 'Pool Size ceph_ma3_1weeks'=2047GB;1535.25;1842.3;0;2047
Pool "ceph_ma1_1weeks": 10236GB Total; 2102GB (21%) Used | 'Pool Size ceph_ma1_1weeks'=2102GB;7677.0;9212.4;0;10236
Pool "1weeks": 14330GB Total; 4148GB (29%) Used | 'Pool Size 1weeks'=4148GB;10747.5;12897.0;0;14330
root@dp01:~ #
```

### check_hpdp_sos_status
HP DataProtector nagios check for StoreOnceSoftware status

**Example**

```
root@dp01:~ # ./check_hpdp_sos_status.rb -h
Usage: check_hpdp_sos_status.rb [options]
    -H, --host <SOS Server>          Name of StoreOnceSoftware Server
    -S, --store <SOS Store>          Name of StoreOnceSoftware Servers Storage
    -L, --limit <percent>            Percent of free space
    -h, --help                       Show this help message
root@dp01:~ # 
```

```
root@dp01:~ # ./check_hpdp_sos_status.rb -H ma1-dp01.backup.example.com -S B2D_ma1 -L 10
OK: B2D_ma1 is Online.
Dedupratio: 4.2 : 1
22.52% of Space left on device
root@dp01:~ # 
```

