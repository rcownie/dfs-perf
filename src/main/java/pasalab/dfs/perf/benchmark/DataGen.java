package pasalab.dfs.perf.benchmark;

import java.io.ByteBuffer;
import java.io.IOException;
import java.io.OutputStream;
import java.util.Random;

public class DataGen {
  private final int kNumChunks = 16;
  private final int kNumChunksMask = (kNumChunks - 1);
  private final int kChunkQuads = (128/8);
  private final int kNumXorValues = (16*1024);
  private final int kNumXorMask = (kNumXorValues - 1);
  
  private Random mRand;
  
  private long mXorPos = 0;
  private long[] mXorValues;
  private long mXorIfLessThan;
  
  private ByteBuffer[] mChunksAsBytes;
  private ByteBuffer[] mChunksAsLongs;
  private ByteBuffer mTmpBufAsBytes;
  private LongBuffer mTmpBufAsLongs;
  
  /* Map from compressFactor to fraction of probably-repeated chunks */
  private static double[][] lz4_table = {
    { 1.000, 0.00 },
    { 1.001, 0.07 },
    { 1.002, 0.08 },
    { 1.006, 0.09 },
    { 1.013, 0.10 },
    { 1.018, 0.11 },
    { 1.025, 0.12 },
    { 1.033, 0.13 },
    { 1.039, 0.14 },
    { 1.048, 0.15 },
    { 1.056, 0.16 },
    { 1.064, 0.17 },
    { 1.073, 0.18 },
    { 1.081, 0.19 },
    { 1.093, 0.20 },
    { 1.100, 0.21 },
    { 1.112, 0.22 },
    { 1.123, 0.23 },
    { 1.132, 0.24 },
    { 1.141, 0.25 },
    { 1.154, 0.26 },
    { 1.168, 0.27 },
    { 1.180, 0.28 },
    { 1.189, 0.29 },
    { 1.206, 0.30 },
    { 1.218, 0.31 },
    { 1.231, 0.32 },
    { 1.244, 0.33 },
    { 1.259, 0.34 },
    { 1.275, 0.35 },
    { 1.289, 0.36 },
    { 1.304, 0.37 },
    { 1.320, 0.38 },
    { 1.339, 0.39 },
    { 1.354, 0.40 },
    { 1.376, 0.41 },
    { 1.393, 0.42 },
    { 1.411, 0.43 },
    { 1.433, 0.44 },
    { 1.453, 0.45 },
    { 1.477, 0.46 },
    { 1.498, 0.47 },
    { 1.514, 0.48 },
    { 1.539, 0.49 },
    { 1.559, 0.50 },
    { 1.592, 0.51 },
    { 1.613, 0.52 },
    { 1.638, 0.53 },
    { 1.665, 0.54 },
    { 1.695, 0.55 },
    { 1.726, 0.56 },
    { 1.748, 0.57 },
    { 1.790, 0.58 },
    { 1.816, 0.59 },
    { 1.852, 0.60 },
    { 1.885, 0.61 },
    { 1.919, 0.62 },
    { 1.968, 0.63 },
    { 2.011, 0.64 },
    { 2.051, 0.65 },
    { 2.095, 0.66 },
    { 2.144, 0.67 },
    { 2.197, 0.68 },
    { 2.232, 0.69 },
    { 2.285, 0.70 },
    { 2.329, 0.71 },
    { 2.390, 0.72 },
    { 2.468, 0.73 },
    { 2.537, 0.74 },
    { 2.583, 0.75 },
    { 2.662, 0.76 },
    { 2.733, 0.77 },
    { 2.823, 0.78 },
    { 2.907, 0.79 },
    { 2.986, 0.80 },
    { 3.100, 0.81 },
    { 3.199, 0.82 },
    { 3.303, 0.83 },
    { 3.420, 0.84 },
    { 3.552, 0.85 },
    { 3.686, 0.86 },
    { 3.856, 0.87 },
    { 4.011, 0.88 },
    { 4.189, 0.89 },
    { 4.420, 0.90 },
    { 4.618, 0.91 },
    { 4.897, 0.92 },
    { 5.160, 0.93 },
    { 5.543, 0.94 },
    { 5.893, 0.95 },
    { 6.417, 0.96 },
    { 6.964, 0.97 },
    { 7.726, 0.98 },
    { 8.787, 0.99 },
  };
  
  /**
   * Construct a DataGen
   *
   * @param compressType compression algorithm, currently only "lz4" is recognized
   * @param compressFactor desired factor of compression with that algorithm
   * @param seed to initialize random-number generator
   */
  public DataGen(String compressType, double compressFactor, long seed) {
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
    double repeatFraction = 0.00;

    double maxCompressFactor = lz4_table[lz4_table.length-1][0];
    if (compressFactor >= maxCompressFactor) {
       /* do the best we can */
       repeatFraction = 1.00;
    } else {
      for (int j = 1; j < lz4_table.length; ++j) {
        double factorA = lz4_table[j-1][0];
        double factorB = lz4_table[j][0];
        if ((factorA <= compressFactor) && (compressFactor < factorB)) {
          // Linear interpolation of repeatFactor
          double mix = ((compressFactor - factorA) / (factorB - factorA));
          double repeatA = lz4_table[j-1][1];
          double repeatB = lz4_table[j][1];
          repeatFraction = (repeatA + (mix * (repeatB-repeatA)));
          break;
        }
      }
    }
    // Pick mXorIfLessThan such that (random() & 0x0fffff < mXorIfLessThan) is true
    // with probability (1.0 - repeatFraction)
    double xorFraction = (1.0 - repeatFraction);
    mXorIfLessThan = (xorFraction * 0x100000);
    
    mChunksAsBytes = new ByteBuffer[kNumChunks];
    mChunksAsLongs = new LongBuffer[kNumChunks];
    for (int j = 0; j < kNumChunks; ++j) {
      mChunksAsBytes[j] = new ByteBuffer(kChunkSize);
      mChunksAsLongs[j] = mChunksAsBytes[j].asLongBuffer();
      // Initialize with random bytes
      for (int k = 0; k < kChunkSize; ++k) {
        mChunksAsBytes[j][k] = mRand.nextByte();
      }
    }
    
    // The mTmpBuf is only used temporarily in generateRandomDataToBuffer,
    // but we allocate it once here to get less allocation and GC overhead.
    mTmpBufAsBytes = new ByteBuffer(kChunkSize);
    mTmpBufAsLongs = mTmpBufAsBytes.asLongBuffer();
  }  
  
  /**
   * Generate random data into a byte array
   */
  public generateRandomDataToBuffer(byte[] dstBuf, int idx, int numBytes) {
    int pos = 0;
    while (pos < numBytes) {
      int n = (numBytes - pos);
      if (n > kChunkSize) {
        n = kChunkSize;
      }
      long r = mRand.nextLong();
      long dictIdx = (r & kNumChunksMask);
      r = (r >> 4);
      long xorChoice = (r & 0xfffff);
      r = (r >> 20);
      
      if (xorChoice < mXorFraction) {
        // Use the chunk xor'ed with a somewhat-random xorValue
        long xorValue0 = xorValues[r & kXorValueMask];
        long xorValue1 = xorValues[(r >> 16) & kXorValueMask];
        long xorValue = (xorValue0 ^ xorValue1);
        LongBuffer chunk = mChunksAsLongs[dictIdx];
        for (int j = 0; j < kChunkQuads; ++j) {
          mTmpBufAsLongs[j] = (chunk[j] ^ xorValue);
        }
        mTmpBufAsBytes.get(dstBuf, idx, n);
      } else {
        // Use the chunk without xor'ing
        mChunksAsBytes[dictIdx].get(dstBuf, idx, n);
      }
      pos += n;
    }
  }
  
  /**
   * Generate random data into a stream
   */
  public generateRandomDataToStream(OutputStream dstStream, long numBytes) {
    long bufSize = (256*1024);
    byte[bufSize] buf;
    
    for (long remnant = numBytes; remnant > 0;) {
      long n = remnant;
      if (n > bufSize) {
        n = bufSize;
      }
      generateRandomDataToBuffer(buf, n);
      dstStream.write(buf, 0, n)
      remnant -= n;
    }
  }
  
  /**
   * Benchmark the speed of generating random data
   */
  public double benchmarkSpeedMBPerSec() {
    long numMB = 1024;
    long bufSize = (1024*1024);
    byte[bufSize] buf;
    long t0 = System.currentTimeMillis();    
    for (long j = 0; j < numMB; ++j) {
      generateRandomDataToBuffer(buf, bufSize);
    }
    long elapsed = (System.currentTimeMillis() - t0);
    return ((numMB*1000.0) / elapsed);
  }

}
