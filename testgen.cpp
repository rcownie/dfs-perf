//
// dfs-perf/testgen.cpp
//
// Richard Cownie, Paradigm4, 2022-05-17
//
// Generate a .xml config file
//
#include <cstdio>
#include <fstream>
#include <iostream>
#include <map>
#include <memory>
#include <sstream>
#include <string>

static const char* getDescription(const std::string& name)
{
    if (name == "basic.files.per.thread") return "the number of global files to write at the beginning for each thread";
    if (name == "block.size.bytes") return "the block size of a file";
    if (name == "buffer.size.bytes") return "the size of the buffer read and write once";
    if (name == "clients.per.thread") return "the number of clients to connect to the file system for each thread";
    if (name == "file.compression.factor") return "compressibility of generated file data";
    if (name == "file.length.bytes") return "the file size in bytes";
    if (name == "files.per.thread") return "the number of files to write for each write thread";
    if (name == "iterations") return" the number of the write-read iteration";
    if (name == "op.second.per.thread") return "the metadata operations time for each thread, in seconds";
    if (name == "read.bytes") return "the read bytes for each skip-and-read operator";
    if (name == "read.files.per.thread") return "the number of files to read for each thread";
    if (name == "read.mode") return "the read mode of read test, should be RANDOM or SEQUENCE";
    if (name == "read.type") return "the ReadType of the read operation, no it only used for Alluxio";
    if (name == "shuffle.mode") return "shuffle mode means it may read remotely";
    if (name == "skip.bytes") return "the skip bytes for each skip-and-read operator";
    if (name == "skip.mode") return "the skip mode, should be FORWARD or RANDOM";
    if (name == "skip.times.per.file") return "the skip-and-read times for each read file";
    if (name == "time.seconds") return "the time to do the global read/write";
    if (name == "write.files.per.thread") return "the number of files to write for each thread";
    if (name == "write.type") return "the WriteType of the write operation, now only used for Alluxio";
    return "unknown property";
}

class Property {
public:
    std::string _name;
    std::string _value;

public:
    Property() {}
    
    Property(const Property& b) = default;
    
    template <typename T>
    Property(const std::string& name, T val) :
      _name(name)
    {
        std::stringstream ss;
        ss << val;
        _value = ss.str();
    }
    
    Property& operator=(const Property& b) = default;
    
    void print(std::ostream& os)
    {
        os << "  <property>\n";
        os << "    <name>" << _name << "</name>\n";
        os << "    <value>" << _value << "</value>\n";
        os << "    <description>" << getDescription(_name) << "</description>\n";
        os << "  </property>\n";
    }
};

class Config {
public:
    std::map<std::string, Property> _props;
    
public:
    template <typename T>
    void insert(const std::string& name, T val)
    {
        _props[name] = Property(name, val);
    }
    
    void print(std::ostream& os)
    {
        os << "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        os << "<configuration>\n";
        for (auto& pair : _props) {
            pair.second.print(os);
        }
        os << "</configuration>\n";        
    }
};

template <typename T>
std::string format(const char* fmt, T val)
{
    char buf[512];
    sprintf(buf, fmt, val);
    return std::string(buf);
}

void test_SimpleWrite(int filesPerThread, long fileSize, double compressFactor)
{
    Config conf;
    conf.insert("block.size.bytes", 128*1024*1024);
    conf.insert("buffer.size.bytes", 4*1024*1024);
    conf.insert("files.per.thread", filesPerThread);
    conf.insert("file.compression.factor", compressFactor);
    conf.insert("file.length.bytes", fileSize);
    conf.insert("write.type", "ASYNC_THROUGH");
    
    std::stringstream ss;
    ss << "conf/testsuite/SimpleWrite";
    ss << "_size" << format("%04dM", fileSize>>20);
    ss << "_files" << format("%03d", filesPerThread);
    if (compressFactor != 1.00) {
        ss << "_z" << format("%4.2f", compressFactor);
    }
    ss << ".xml";
    
    std::ofstream out;
    out.open(ss.str(), std::ofstream::out);
    conf.print(out);
    out.close();
}

void test_SimpleRead(int filesPerThread, long fileSize, double compressFactor, bool isCold, bool isRandom)
{
    Config conf;
    conf.insert("buffer.size.bytes", 4*1024*1024);
    conf.insert("files.per.thread", filesPerThread);
    conf.insert("read.mode", isRandom ? "RANDOM" : "SEQUENCE");
    conf.insert("read.type", "CACHE_PROMOTE");
    
    std::stringstream ss;
    ss << "conf/testsuite/SimpleRead";
    ss << "_size" << format("%04dM", fileSize>>20);
    ss << "_files" << format("%03d", filesPerThread);
    if (compressFactor != 1.00) {
        ss << "_z" << format("%4.2f", compressFactor);
    }
    if (isRandom) {
        ss << "_rnd";
    }
    if (isCold) {
        ss << "_cold";
    }
    ss << ".xml";
    
    std::ofstream out;
    out.open(ss.str(), std::ofstream::out);
    conf.print(out);
    out.close();
}

int main(int argc, char* argv[])
{
    long M = (1024*1024);
    
    // write lots of small files    
    test_SimpleWrite(512, 1*M, 1.00);
    
    // write 8 files per thread w/ varying file size
    test_SimpleWrite(8, 16*M,   1.00);
    test_SimpleWrite(8, 64*M,   1.00);
    test_SimpleWrite(8, 256*M,  1.00);
    test_SimpleWrite(8, 1024*M, 1.00);
    test_SimpleWrite(8, 4096*M, 1.00);

    test_SimpleWrite(1, 8*M,    1.33);
    test_SimpleWrite(1, 32*M,   1.33);
    test_SimpleWrite(1, 128*M,  1.33);
    test_SimpleWrite(1, 512*M,  1.33);
    test_SimpleWrite(1, 2048*M, 1.33);
    
    test_SimpleRead(1,  8*M,    1.33, true, false);
    test_SimpleRead(1,  32*M,   1.33, true, false);
    test_SimpleRead(1,  128*M,  1.33, true, false);
    test_SimpleRead(1,  512*M,  1.33, true, false);
    test_SimpleRead(1,  2048*M, 1.33, true, false);
    
    // write 8 x 1GB files w/ varying compression
    test_SimpleWrite(8, 1024*M, 1.50);
    test_SimpleWrite(8, 1024*M, 2.00);
    test_SimpleWrite(8, 1024*M, 2.50);
    test_SimpleWrite(8, 1024*M, 3.00);
    test_SimpleWrite(8, 1024*M, 4.00);
    
    for (int flags = 0x0; flags <= 0x3; ++flags) {
      test_SimpleRead(512, 1*M,  1.00, flags&0x2, flags&0x1);
      test_SimpleRead(1, 2048*M, 1.00, flags&0x2, flags&0x1);
      test_SimpleRead(8, 16*M,   1.00, flags&0x2, flags&0x1);
      test_SimpleRead(8, 64*M,   1.00, flags&0x2, flags&0x1);
      test_SimpleRead(8, 256*M,  1.00, flags&0x2, flags&0x1);
      test_SimpleRead(8, 1024*M, 1.00, flags&0x2, flags&0x1);
      test_SimpleRead(8, 4096*M, 1.00, flags&0x2, flags&0x1);
      
      test_SimpleRead(8, 1024*M, 1.50, flags&0x2, flags&0x1);
      test_SimpleRead(8, 1024*M, 2.00, flags&0x2, flags&0x1);
      test_SimpleRead(8, 1024*M, 2.50, flags&0x2, flags&0x1);
      test_SimpleRead(8, 1024*M, 3.00, flags&0x2, flags&0x1);
      test_SimpleRead(8, 1024*M, 4.00, flags&0x2, flags&0x1);
    }
    
    return 0;
}
