# MySQL CLI

Typically, you would use `mysql` client cli as follows,
```
$ mysql -h tpm-dev-db.clouddqt.capitalone.com -P 3306 -u username -D tpm -p
```

You could also use `~/.my.cnf` to set default properties, including connection info,

```
[client]
prompt=\\u@\\d>\\_
port = 3306
host = tpm-dev-db.clouddqt.capitalone.com
database = tpm
user = tim
```

You could even add `password` but I wouldn't recommend it. Also, this approach is not useful when you have more than one MySQL database across multiple hosts, ports, etc.



```
function mysqle() { mysql --defaults-group-suffix=$1 --password "${@:2}"; }
```
