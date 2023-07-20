#! /bin/bash
TMP_DIR=$(pwd)/tmp
rm -rf ${TMP_DIR}
mkdir -p ${TMP_DIR}

for i in {2..6}; do
	sed 's^NUMBER^'"${i}"'^g' static-client.tmpl >${TMP_DIR}/static-client-${i}.yaml
	sed 's^NUMBER^'"${i}"'^g' static-server.tmpl >${TMP_DIR}/static-server-${i}.yaml
done
