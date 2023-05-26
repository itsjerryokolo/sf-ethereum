go install -v ../../../cmd/fireeth && fireeth start firehose \
    --config-file= \
    --common-live-blocks-addr= \
    --common-merged-blocks-store-url="$COMMON_MERGED_BLOCKS" \
    --common-first-streamable-block=0 \
    --common-one-block-store-url="$ONE_BLOCK_STORE_URL" \
    --firehose-grpc-listen-addr=:9001 \
    --substreams-client-endpoint= \
    --substreams-client-insecure=true \
    --substreams-client-plaintext=false \
    --substreams-enabled=true \
    --substreams-tier2=true \
    --substreams-rpc-cache-chunk-size=100 \
    --substreams-sub-request-block-range-size=0 \
    --substreams-sub-request-parallel-jobs=10 \
    --substreams-cache-save-interval=100 \
    --substreams-rpc-endpoints="$ETH_MAINNET_RPC"
