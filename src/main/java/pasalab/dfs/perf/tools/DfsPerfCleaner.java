package pasalab.dfs.perf.tools;

import pasalab.dfs.perf.benchmark.DataGen;

import java.io.IOException;

import pasalab.dfs.perf.conf.PerfConf;
import pasalab.dfs.perf.fs.PerfFileSystem;

public class DfsPerfCleaner {
  public static void main(String[] args) {
    try {
      PerfFileSystem fs = PerfFileSystem.get(PerfConf.get().DFS_ADDRESS, null);
      fs.connect();
      fs.delete(PerfConf.get().DFS_DIR, true);
      fs.close();
    } catch (IOException e) {
      e.printStackTrace();
      System.err.println("Failed to clean workspace " + PerfConf.get().DFS_DIR + " on "
          + PerfConf.get().DFS_ADDRESS);
    }
    System.out.println("Clean the workspace " + PerfConf.get().DFS_DIR + " on "
        + PerfConf.get().DFS_ADDRESS);
    
    DataGen dataGen = new DataGen("lz4", 2.0, 0xab583c);
    System.out.format("Testing ...%n");
    double speed = dataGen.benchmarkSpeedMBPerSec();
    System.out.format("Speed %f MB/s%n", speed);           
  }
}
