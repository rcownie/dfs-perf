
.PHONY: all clean compile jar package

VERSION :=0.1.1

all: jar testgen

clean:
	mvn clean
	-rm -f dfs-perf-${VERSION}.tgz

compile:
	mvn install

jar: compile

package:
	cd .. ; \
	tar cvfz dfs-perf/dfs-perf-${VERSION}.tgz \
	  dfs-perf/target/dfs-perf-0.1.0-SNAPSHOT-jar-with-dependencies.jar \
	  dfs-perf/bin \
	  dfs-perf/conf \
	  dfs-perf/libexec

testgen: testgen.cpp
	g++ -o $@ -std=c++11 -O2 testgen.cpp

cluster:
	ssh_cluster cat < dfs-perf-${VERSION}.tgz ">" dfs-perf-${VERSION}.tgz

