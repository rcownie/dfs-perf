
.PHONY: all clean cluster compile distribute jar package

VERSION :=0.1.1
DFS_PERF_MASTER_HOSTNAME :=172.30.0.194

# ssh_cluster should talk to the master node in the cluster
#DFS_PERF_MASTER_HOSTNAME :=$(shell ssh_cluster hostname)

all: jar testgen

clean:
	mvn -q clean
	-rm -f dfs-perf-${VERSION}.tgz

compile:
	mvn -q install

jar: compile


package: jar testgen
	sed s/DFS_PERF_MASTER_HOSTNAME_placeholder/${DFS_PERF_MASTER_HOSTNAME}/ \
	  < conf/dfs-perf-env.sh.template \
	  > conf/dfs-perf-env.sh
	testgen
	cd .. ; \
	tar cfz dfs-perf/package.tgz \
	  dfs-perf/target/dfs-perf-0.1.0-SNAPSHOT-jar-with-dependencies.jar \
	  dfs-perf/bin \
	  dfs-perf/conf \
	  dfs-perf/libexec

cluster_any: package
	ssh_cluster cat < package.tgz ">" package.tgz
	ssh_cluster tar xfz package.tgz

cluster_00 cluster_off:
	ssh_cluster ./autoscale.sh 0

cluster_01: cluster_any
	ssh_cluster dfs-perf/bin/setup_cluster.sh 1

cluster_02: cluster_any
	ssh_cluster dfs-perf/bin/setup_cluster.sh 2

cluster_04: cluster_any
	ssh_cluster dfs-perf/bin/setup_cluster.sh 4

cluster_08: cluster_any
	ssh_cluster dfs-perf/bin/setup_cluster.sh 8

cluster_16: cluster_any
	ssh_cluster dfs-perf/bin/setup_cluster.sh 16

cluster_32: cluster_any
	ssh_cluster dfs-perf/bin/setup_cluster.sh 32

cluster_64: cluster_any
	ssh_cluster dfs-perf/bin/setup_cluster.sh 64

cluster_128: cluster_any
	ssh_cluster dfs-perf/bin/setup_cluster.sh 128

cluster_256: cluster_any
	ssh_cluster dfs-perf/bin/setup_cluster.sh 256

testgen: testgen.cpp
	g++ -o $@ -std=c++11 -O2 testgen.cpp

cluster:
	ssh_cluster cat < dfs-perf-${VERSION}.tgz ">" dfs-perf-${VERSION}.tgz

