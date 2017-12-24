## serverreview-benchmark

##### Download

`curl -Ls git.io/bench.sh -o bench.sh; chmod +x bench.sh`

##### Usage

`./bench.sh` `ARG` `PRM(Optional)`

Example: `./bench.sh -b share`

##### Arguments

`./bench.sh -info` # System Information

`/bench.sh -io` # I/O Test

`./bench.sh -cdn` # CDN Download (200MB)

`./bench.sh -northamerica` # North America Download (800MB)

`./bench.sh -europe` # Europe Download (900MB)

`./bench.sh -asia` # Asia Download (400MB)

`./bench.sh -b` # System Info + CDN Download + I/O Test

`./bench.sh -a` # All In One Command

`./bench.sh -help` # Show help

`./bench.sh -about` # Show about

##### Parameters

`share` # upload results (default to hastebin)

`ubuntu` # upload results to ubuntu paste


##### _Credits_

Thanks to `@camarg` for the the original script. Thanks to `@dmmcintyre3` for the modified version. Thanks `@Hidden_Refuge` for update bench-sh-2.
