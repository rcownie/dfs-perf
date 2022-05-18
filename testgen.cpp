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

void test_SimpleWrite(int filesPerThread, long fileSize, double compressFactor)
{
    Config conf;
    conf.insert("files.per.thread", filesPerThread);
    conf.insert("file.compression.factor", compressFactor);
    conf.insert("file.length.bytes", fileSize);
    
    std::stringstream ss;
    ss << "conf/testsuite/SimpleWrite";
    ss << "_files" << filesPerThread;
    ss << "_size" << (fileSize>>20) << "M";
    if (compressFactor != 1.00) {
        char buf[32];
        sprintf(buf, "%4.2f", compressFactor);
        ss << "_z" << buf;
    }
    ss << ".xml";
    
    std::ofstream out;
    out.open(ss.str(), std::ofstream::out);
    conf.print(out);
    out.close();
}

void test_SimpleRead()
{
}

int main(int argc, char* argv[])
{
    long maxFilesPerThread = 1024;
    long maxMBPerThread = 8*1024;
    long minFileSizeMB = 1;

    // write lots of small files    
    test_SimpleWrite(512, 1<<20, 1.00);
    // write 2GB of data per thread in various ways
    test_SimpleWrite(128, 16<<20, 1.00);
    test_SimpleWrite(64,  32<<20, 1.00);
    test_SimpleWrite(32,  64<<20, 1.00);
    test_SimpleWrite(16, 128<<20, 1.00);
    test_SimpleWrite(8,  256<<20, 1.00);
    test_SimpleWrite(4,  512<<20, 1.00);
    return 0;
}
