## serverreview-benchmark

##### Download

`curl -Lso bench.sh raw.githubusercontent.com/sayem314/serverreview-benchmark/v3-dev/bench.sh; chmod +x bench.sh`

##### Usage

`./bench.sh` `ARG` `PRM(Optional)`

Example: `./bench.sh -b share`

##### Arguments

`-info` # System Information

`-io` # I/O Test

`-cdn` # CDN Download (200MB)

`-northamerica` # North America Download (800MB)

`-europe` # Europe Download (900MB)

`-asia` # Asia Download (400MB)

`-b` # System Info + CDN Download + I/O Test

`-a` # All In One Command

`-speed` # Test from speedtest.net using speedtest cli

`-help` # Show help

`-about` # Show about

##### Parameters

`share` # upload results (default to hastebin)

`ubuntu` # upload results to ubuntu paste


##### _Credits_

Thanks to `@camarg` for the the original script. Thanks to `@dmmcintyre3` for the modified version. Thanks `@Hidden_Refuge` for update bench-sh-2.
