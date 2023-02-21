module CheckProof

go 1.19

require (
	github.com/tendermint/go-amino v0.16.0
	github.com/tendermint/iavl v0.12.0
	github.com/tendermint/tendermint v0.31.11
)

require (
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/etcd-io/bbolt v1.3.3 // indirect
	github.com/go-kit/kit v0.12.0 // indirect
	github.com/go-kit/log v0.2.0 // indirect
	github.com/go-logfmt/logfmt v0.6.0 // indirect
	github.com/gogo/protobuf v1.3.2 // indirect
	github.com/golang/protobuf v1.5.2 // indirect
	github.com/golang/snappy v0.0.0-20180518054509-2e65f85255db // indirect
	github.com/jmhodges/levigo v1.0.0 // indirect
	github.com/pkg/errors v0.9.1 // indirect
	github.com/stretchr/testify v1.8.1 // indirect
	github.com/syndtr/goleveldb v1.0.0 // indirect
	go.etcd.io/bbolt v1.3.7 // indirect
	golang.org/x/sys v0.4.0 // indirect
	google.golang.org/protobuf v1.27.1 // indirect
)

replace (
	github.com/etcd-io/bbolt v1.3.6 => go.etcd.io/bbolt v1.3.6
	github.com/gogo/protobuf v1.1.1 => github.com/gogo/protobuf v1.3.2
	github.com/gogo/protobuf v1.3.1 => github.com/gogo/protobuf v1.3.2
)
