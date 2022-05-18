package pasalab.dfs.perf.benchmark.simplewrite;

import java.io.IOException;
import java.util.List;

import org.apache.log4j.Logger;

import pasalab.dfs.perf.basic.PerfThread;
import pasalab.dfs.perf.basic.TaskConfiguration;
import pasalab.dfs.perf.benchmark.DataGen;
import pasalab.dfs.perf.benchmark.ListGenerator;
import pasalab.dfs.perf.benchmark.Operators;
import pasalab.dfs.perf.conf.PerfConf;
import pasalab.dfs.perf.fs.PerfFileSystem;

public class SimpleWriteThread extends PerfThread {
  private static final Logger LOG = Logger.getLogger("SimpleWriteThread");
  
  private int mBufferSize;
  private long mFileLength;
  private PerfFileSystem mFileSystem;
  private List<String> mWriteFiles;

  private boolean mSuccess;
  private double mThroughput; // in MB/s

  public boolean getSuccess() {
    return mSuccess;
  }

  public double getThroughput() {
    return mThroughput;
  }

  public void run() {
    LOG.info("run() ...");
    long timeMs = System.currentTimeMillis();
    long writeBytes = 0;
    mSuccess = true;
    for (String fileName : mWriteFiles) {
      try {
        LOG.info("writeSingleFile fileName " + fileName);
        Operators.writeSingleFile(mFileSystem, fileName, mFileLength, mDataGen);
        LOG.info("writeSingleFile done");
        writeBytes += mFileLength;
      } catch (IOException e) {
        LOG.error("Failed to write file " + fileName, e);
        mSuccess = false;
      }
    }
    timeMs = System.currentTimeMillis() - timeMs;
    mThroughput = (writeBytes / 1024.0 / 1024.0) / (timeMs / 1000.0);
    LOG.info("run() done");
  }

  @Override
  public boolean setupThread(TaskConfiguration taskConf) {
    LOG.info("setupThread() ...");
    mBufferSize = taskConf.getIntProperty("buffer.size.bytes");
    mFileLength = taskConf.getLongProperty("file.length.bytes");
    mDataGen = new DataGen("lz4", taskConf.getDoubleProperty("file.compression.factor"),
      System.currentTimeMillis(), mBufferSize);
    try {
      LOG.info("connect ...");
      mFileSystem = Operators.connect(PerfConf.get().DFS_ADDRESS, taskConf);
      String writeDir = taskConf.getProperty("write.dir");
      int filesNum = taskConf.getIntProperty("files.per.thread");
      LOG.info("generateWriteFiles filesNum " + filesNum);
      mWriteFiles = ListGenerator.generateWriteFiles(mId, filesNum, writeDir);
    } catch (IOException e) {
      LOG.error("Failed to setup thread, task " + mTaskId + " - thread " + mId, e);
      return false;
    }
    mSuccess = false;
    mThroughput = 0;
    LOG.info("setupThread() done");
    return true;
  }

  @Override
  public boolean cleanupThread(TaskConfiguration taskConf) {
    try {
      Operators.close(mFileSystem);
    } catch (IOException e) {
      LOG.warn("Error when close file system, task " + mTaskId + " - thread " + mId, e);
    }
    return true;
  }

}
