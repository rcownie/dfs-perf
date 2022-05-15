package pasalab.dfs.perf.benchmark;

import java.nio.*;
import java.io.IOException;
import java.io.OutputStream;
import java.io.FileOutputStream;
import java.util.Random;

public class DataGen {
  private final int kNumChunks = 16;
  private final int kNumChunksMask = (kNumChunks - 1);
  private final int kChunkQuads = (128/8);
  private final int kChunkSize = (kChunkQuads * 8);
  private final int kNumXorValues = (16*1024);
  private final int kNumXorMask = (kNumXorValues - 1);
  
  private Random mRand;
  
  private long mXorPos = 0;
  private long[] mXorValues;
  private long mXorIfLessThan;
  
  private ByteBuffer[] mChunksAsBytes = new ByteBuffer[kNumChunks];
  private ByteBuffer mTmpBufAsBytes;

  // mWriteBuf is only used temporarily, but we allocate it here
  // to minimize allocate/GC overhead.
  private int mWriteBufSize;
  private byte[] mWriteBuf;
  
  /*
   * Map from compressFactor to fraction of probably-repeated chunks
   *
   * This calibrates the actual compression ratio found from
   * using lz4 to compress files generated with different xorFraction.
   */  
  private static double[][] lz4_table = {
    { 1.000, 1.000 },
    { 1.070, 0.894 },
    { 1.199, 0.789 },
    { 1.336, 0.704 },
    { 1.476, 0.633 },
    { 1.612, 0.576 },
    { 1.746, 0.529 },
    { 1.886, 0.486 },
    { 2.035, 0.448 },
    { 2.177, 0.416 },
    { 2.338, 0.386 },
    { 2.470, 0.363 },
    { 2.627, 0.339 },
    { 2.767, 0.319 },
    { 2.955, 0.297 },
    { 3.117, 0.279 },
    { 3.256, 0.265 },
    { 3.460, 0.248 },
    { 3.628, 0.235 },
    { 3.800, 0.223 },
    { 3.980, 0.211 },
    { 4.172, 0.199 },
    { 5.151, 0.154 },
    { 6.207, 0.121 },
    { 7.442, 0.096 },
    { 8.783, 0.076 },
    { 10.187, 0.061 },
    { 11.900, 0.048 },
    { 13.603, 0.038 },
    { 15.609, 0.030 },
    { 17.556, 0.023 },
    { 19.692, 0.017 },
  };
  
  /**
   * Construct a DataGen
   *
   * @param compressType compression algorithm, currently only "lz4" is recognized
   * @param compressFactor desired factor of compression with that algorithm
   * @param seed to initialize random-number generator
   */
  public DataGen(String compressType, double compressFactor, long seed, long bufferSize) {
    assert(compressType == "lz4");
    mRand = new Random(seed);
    mXorPos = 0;
    mXorValues = new long[kNumXorValues];
    
    for (int j = 0; j < kNumXorValues; ++j) {
      long r0 = mRand.nextLong();
      long r1 = mRand.nextLong();
      mXorValues[j] = (r0 ^ (r1<<32));
    } 
    
    /*
     * Do table lookup with linear interpolation
     */
    double xorFraction = 0.0;

    double maxCompressFactor = lz4_table[lz4_table.length-1][0];
    if (compressFactor >= maxCompressFactor) {
       /* do the best we can */
       xorFraction = 0.0;
    } else {
      for (int j = 1; j < lz4_table.length; ++j) {
        double factorA = lz4_table[j-1][0];
        double factorB = lz4_table[j][0];
        System.out.format("DEBUG: compressFactor %f factorA %f factorB %f%n",
          compressFactor, factorA, factorB);
        if ((factorA <= compressFactor) && (compressFactor < factorB)) {
          // Linear interpolation of repeatFactor
          double mix = ((compressFactor - factorA) / (factorB - factorA));
          double xorA = lz4_table[j-1][1];
          double xorB = lz4_table[j][1];
          xorFraction = (xorA + (mix * (xorB-xorA)));
          System.out.format("DEBUG: xorA %f xorB %f mix %f xorFraction %f%n",
            xorA, xorB, mix, xorFraction);
          break;
        }
      }
    }
    // Pick mXorIfLessThan such that (random() & 0x0fffff < mXorIfLessThan) is true
    // with probability xorFraction
    mXorIfLessThan = (long)(xorFraction * 0x100000);
    
    System.out.format("DEBUG: compressFactor %f xorFraction %f xorIfLessThan %d%n",
      compressFactor,
      xorFraction,
      mXorIfLessThan);
    
    for (int j = 0; j < kNumChunks; ++j) {
      mChunksAsBytes[j] = ByteBuffer.allocate(kChunkSize);
      // Initialize with random bytes
      for (int k = 0; k < kChunkSize; ++k) {
        mChunksAsBytes[j].put(k, (byte)mRand.nextInt());
      }
      mChunksAsBytes[j].limit(kChunkSize);
    }
    
    mTmpBufAsBytes = ByteBuffer.allocate(kChunkSize);
    mTmpBufAsBytes.limit(kChunkSize);
 
    if (bufferSize > 64*1024*1024) {
      bufferSize = 64*1024*1024;
    }
    mWriteBufSize = (int)bufferSize;
    mWriteBuf = new byte[mWriteBufSize];
  }  
  
  /**
   * Generate random data into a byte array
   */
  public void generateRandomDataToBuffer(byte[] dstBuf, int idx, int numBytes) {
    int pos = 0;
    while (pos < numBytes) {
      int n = (numBytes - pos);
      if (n > kChunkSize) {
        n = kChunkSize;
      }
      long r = mRand.nextLong();
      int dictIdx = (int)(r & kNumChunksMask);
      r = (r >> 4);
      int xorChoice = (int)(r & 0xfffff);
      r = (r >> 20);
      
      if (xorChoice < mXorIfLessThan) {
        // Use the chunk xor'ed with a somewhat-random xorValue
        long xorValue0 = mXorValues[(int)r & kNumXorMask];
        long xorValue1 = mXorValues[(int)(r >> 16) & kNumXorMask];
        long xorValue = (xorValue0 ^ xorValue1);
        //System.out.format("DEBUG: dictIdx 0x%x xorValue 0x%x%n", dictIdx, xorValue);
        ByteBuffer chunk = mChunksAsBytes[dictIdx];
        for (int j = 0; j < kChunkQuads; ++j) {
          long val = chunk.getLong(8*j);
          //System.out.format("  [0x%02x] 0x%x%n", 8*j, val^xorValue);
          mTmpBufAsBytes.putLong(8*j, (val ^ xorValue));
        }
        mTmpBufAsBytes.position(0);
        mTmpBufAsBytes.get(dstBuf, idx+pos, n);
      } else {
        // Use the chunk without xor'ing
        //System.out.format("DEBUG: dictIdx 0x%x%n", dictIdx);
        mChunksAsBytes[dictIdx].position(0);
        mChunksAsBytes[dictIdx].get(dstBuf, idx+pos, n);
      }
      pos += n;
    }
  }
  
  /**
   * Generate random data into a stream
   */
  public void generateRandomDataToStream(OutputStream dstStream, int numBytes) {
    for (int remnant = numBytes; remnant > 0;) {
      int n = remnant;
      if (n > mWriteBufSize) {
        n = mWriteBufSize;
      }
      generateRandomDataToBuffer(mWriteBuf, 0, n);
      try {
        dstStream.write(mWriteBuf, 0, n);
      } catch (IOException e) {
      }
      remnant -= n;
    }
  }
  
  /**
   * Benchmark the speed of generating random data
   */
  public double benchmarkSpeedMBPerSec(String fileName) {
    int numMB = 1024;
    int bufSize = (1024*1024);
    byte[] buf = new byte[bufSize];

    try {
      FileOutputStream out = new FileOutputStream(fileName);
      generateRandomDataToStream(out, 8*1024*1024);
      out.close();
    } catch (IOException e) {
    }
    
    long t0 = System.currentTimeMillis();    
    for (int j = 0; j < numMB; ++j) {
      generateRandomDataToBuffer(buf, 0, bufSize);
    }
    long elapsed = (System.currentTimeMillis() - t0);
    return ((numMB*1000.0) / elapsed);
  }

}
