## MySQL CLI

Typically, you would use `mysql` client cli as follows,
```
$ mysql -h some.random.hostname.com -P 3306 -u bob -D somedb -p
```

You could also create a `~/.my.cnf` to set default properties, including connection info,

```
[client]
prompt=\\u@\\d>\\_
port = 3306
host = some.random.hostname.com
database = somedb
user = bob
```

You could even add `password` but I wouldn't recommend it. Also, this approach is not useful when you have more than one MySQL database across multiple hosts, ports, etc.

## Managing multiple connections

Unfortunately, mysql still doesn't have an easy way to do this, but if you add the following to your `.bashrc`,
```
function mysqle() { mysql --defaults-group-suffix=$1 --password "${@:2}"; }
```

You can then setup your `~/.my.cnf` as follows,

```
[client]
prompt=\\u@\\d>\\_
port = 3306

[clientsomedb]
host = some.random.hostname.com
database = somedb
user = bob

[clientsuperdb]
host = some.other.random.hostname.com
port = 63306
database = superdb
user = bob
```

As long as you prefix the section with "client", then this will allow you to create as many different sections as you need (for different apps, different environments, whatever).

To connect, just use the shell function from earlier,

```
$ mysqle superdb
```
