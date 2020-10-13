#import "TorrentInfo.h"

#import "libtorrent/entry.hpp"
#import "libtorrent/bencode.hpp"
#import "libtorrent/torrent_info.hpp"
#import "libtorrent/announce_entry.hpp"
#import "libtorrent/bdecode.hpp"
#import "libtorrent/magnet_uri.hpp"

using namespace libtorrent;

@interface Tracker ()
- (instancetype)initWithCppTracker:(std::vector<announce_entry>::const_iterator)cTracker;
@end

@interface BTFile ()
- (instancetype)initWithFileStorage:(file_storage const&)st index:(int)i;
@end

@interface BTFilePiecesInfo ()
- (instancetype)initWithPeerRequest:(peer_request)pr pieceLength:(int)pl;
@end

@implementation TorrentInfo

#pragma mark - Public
+ (instancetype)infoWithfile:(NSString *)path {
    TorrentInfo *info = [[TorrentInfo alloc] initWithPath:path];
    return info;
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _torrentPath = path;
        
        std::vector<char> buf;
        if ([self readFile:path buf:&buf] != 0) return nil;
        
        bdecode_node e;
        if ([self decode:&buf node:&e] != 0) return nil;
        
        int error;
        torrent_info t = [self makeTorrentInfo:&e buf:&buf error:&error];
        if (error != 0) return nil;
        
        [self parseDHTNode:t];
        [self parseTrackers:t];
        [self parseBaseInfo:t];
        [self parseFiles:t];
        
    }
    return self;
}

- (void)dump {
    printf("\n\n----- torrent file info -----\n\n" "DHT nodes:\n");
    for (DHTNode *node in self.dhtNodes) {
        printf("%s: %d\n", [node.nodeID cStringUsingEncoding:NSUTF8StringEncoding], node.distance);
    }
    puts("\ntrackers:");
    for (Tracker *tracker in self.trackers) {
        printf("%2d: %s\n", tracker.tier, [tracker.url cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    printf("\n\n");
    printf("piece count: %d\n", self.piecesCount);
    printf("piece size: %d\n", self.pieceSize);
    printf("hash: %s\n", [self.infoHash cStringUsingEncoding:NSUTF8StringEncoding]);
    printf("comment: %s\n", [self.comment cStringUsingEncoding:NSUTF8StringEncoding]);
    printf("creator: %s\n", [self.creator cStringUsingEncoding:NSUTF8StringEncoding]);
    printf("magnet: \n %s\n", [self.magnet cStringUsingEncoding:NSUTF8StringEncoding]);
    printf("name: %s\n", [self.name cStringUsingEncoding:NSUTF8StringEncoding]);
    printf("file count: %lu\n", (unsigned long)self.files.count);
    printf("<----- file list: -----> \n\n");
    for (BTFile *file in self.files) {
        printf(" %8" PRIx64 " %11" PRId64 " %c%c%c%c [ %5d, %5d ] %7u %s %s %s%s\n",
               file.offset,
               file.size,
               (file.isPadFile ? 'p' : '-'),
               (file.executable ? 'x' : '-'),
               (file.hidden ? 'h' : '-'),
               (![file.symlink isEqualToString:@""] ? 'l' : '-'),
               file.firstPiece,
               file.lastPiece,
               file.mtime,
               [file.fileHash cStringUsingEncoding:NSUTF8StringEncoding],
               [file.name cStringUsingEncoding:NSUTF8StringEncoding],
               ![file.symlink isEqualToString:@""] ? "-> " : "",
               [file.symlink cStringUsingEncoding:NSUTF8StringEncoding]);
    }
}

#pragma mark - Private
- (int)readFile:(NSString *)url buf:(std::vector<char> *)buf {
    error_code ec;
    std::string *path = new std::string([url UTF8String]);
    switch (load_file(*path, *buf, ec, 40 * 1000000)) {
        case -1:fprintf(stderr, "file read error\n");
        case -2:fprintf(stderr, "file too big, aborting\n");
        case -3:fprintf(stderr, "failed to load file: %s\n", ec.message().c_str());
            return 1;
    }
    return 0;
}

- (int)decode:(std::vector<char> *)buf node:(bdecode_node *)e {
    error_code ec;
    int pos = -1;
    
    int item_limit = 1000000;
    int depth_limit = 1000;
    printf("start decode ... max depth: %d max item: %d\n", depth_limit, item_limit);
    if (bdecode(&(*buf)[0], &(*buf)[0] + (*buf).size(), *e, ec, &pos, depth_limit, item_limit) != 0) {
        fprintf(stderr, "decode failed: '%s' position: %d\n", ec.message().c_str(), pos);
        return 1;
    }
    return 0;
}

- (torrent_info)makeTorrentInfo:(bdecode_node *)e buf:(std::vector<char> *)buf error:(int *)errorTag {
    error_code ec;
    torrent_info t(*e, ec);
    if (ec) {
        fprintf(stderr, "%s\n", ec.message().c_str());
        *errorTag = 1;
        return t;
    }
    *errorTag = 0;
    (*e).clear();
    std::vector<char>().swap(*buf);
    return t;
}

- (void)parseDHTNode:(torrent_info)t {
    typedef std::vector< std::pair<std::string, int> > node_vec;
    node_vec const& nodes = t.nodes();
    NSMutableArray *ocNodes = [[NSMutableArray alloc] init];
    for (node_vec::const_iterator i = nodes.begin(), end(nodes.end()); i != end; ++i) {
        DHTNode *node = [[DHTNode alloc] init];
        node.nodeID = [NSString stringWithCString:i->first.c_str() encoding:NSUTF8StringEncoding];
        node.distance = i->second;
        [ocNodes addObject:node];
    }
    _dhtNodes = ocNodes;
}

- (void)parseTrackers:(torrent_info)t {
    NSMutableArray *trackers = [[NSMutableArray alloc] init];
    for (std::vector<announce_entry>::const_iterator i = t.trackers().begin(); i != t.trackers().end(); ++i) {
        Tracker *tracker = [[Tracker alloc] initWithCppTracker:i];
        [trackers addObject:tracker];
    }
    _trackers = trackers;
}

- (void)parseBaseInfo:(torrent_info)t {
    char ih[41];
    to_hex((char const*)&t.info_hash()[0], 20, ih);
    _piecesCount = t.num_pieces();
    _pieceSize = t.piece_length();
    _infoHash = [NSString stringWithCString:ih encoding:NSUTF8StringEncoding];
    _comment = [NSString stringWithCString:t.comment().c_str() encoding:NSUTF8StringEncoding];
    _creator = [NSString stringWithCString:t.creator().c_str() encoding:NSUTF8StringEncoding];
    _magnet = [NSString stringWithCString:make_magnet_uri(t).c_str() encoding:NSUTF8StringEncoding];
    _name = [NSString stringWithCString:t.name().c_str() encoding:NSUTF8StringEncoding];
}

- (void)parseFiles:(torrent_info)t {
    file_storage const& st = t.files();
    NSMutableArray *btfiles = [[NSMutableArray alloc] init];
    for (int i = 0; i < st.num_files(); ++i) {
        BTFile *btfile = [[BTFile alloc] initWithFileStorage:st index:i];
        [btfiles addObject:btfile];
    }
    _files = btfiles;
}

int load_file(std::string const& filename, std::vector<char>& v, libtorrent::error_code& ec, int limit = 8000000) {
    ec.clear();
    FILE* f = fopen(filename.c_str(), "rb");
    if (f == NULL) {
        ec.assign(errno, boost::system::system_category());
        return -1;
    }
    
    int r = fseek(f, 0, SEEK_END);
    if (r != 0) {
        ec.assign(errno, boost::system::system_category());
        fclose(f);
        return -1;
    }
    long s = ftell(f);
    if (s < 0) {
        ec.assign(errno, boost::system::system_category());
        fclose(f);
        return -1;
    }
    
    if (s > limit) {
        fclose(f);
        return -2;
    }
    
    r = fseek(f, 0, SEEK_SET);
    if (r != 0) {
        ec.assign(errno, boost::system::system_category());
        fclose(f);
        return -1;
    }
    
    v.resize(s);
    if (s == 0){
        fclose(f);
        return 0;
    }
    
    r = (int)fread(&v[0], 1, v.size(), f);
    if (r < 0) {
        ec.assign(errno, boost::system::system_category());
        fclose(f);
        return -1;
    }
    
    fclose(f);
    
    if (r != s) return -3;
    
    return 0;
}

@end

@implementation DHTNode

@end

@implementation Tracker
- (instancetype)initWithCppTracker:(std::vector<announce_entry>::const_iterator)cTracker {
    if (self = [super init]) {
        self.tier = cTracker->tier;
        self.url = [NSString stringWithCString:cTracker->url.c_str() encoding:NSUTF8StringEncoding];
    }
    return self;
}
@end

@implementation BTFile
- (instancetype)initWithFileStorage:(const libtorrent::file_storage &)st index:(int)i {
    if (self = [super init]) {
        int flags = st.file_flags(i);
        _offset = st.file_offset(i);
        _size = st.file_size(i);
        _isPadFile = flags & file_storage::flag_pad_file;
        _executable = flags & file_storage::flag_executable;
        _hidden = flags & file_storage::flag_hidden;
        _firstPiece = st.map_file(i, 0, 0).piece;
        _lastPiece = st.map_file(i, (std::max)(boost::int64_t(st.file_size(i))-1, boost::int64_t(0)), 0).piece;
        _mtime = boost::uint32_t(st.mtime(i));
        _fileHash = [NSString stringWithCString:st.hash(i) != sha1_hash(0) ? to_hex(st.hash(i).to_string()).c_str() : "" encoding:NSUTF8StringEncoding];
        _name = [NSString stringWithCString:st.file_path(i).c_str() encoding:NSUTF8StringEncoding];
        _symlink = [NSString stringWithCString:(flags & file_storage::flag_symlink) ? st.symlink(i).c_str() : "" encoding:NSUTF8StringEncoding];
        _piecesInfo = [[BTFilePiecesInfo alloc] initWithPeerRequest:st.map_file(i, 0, int(st.file_size(i))) pieceLength:st.piece_length()];
    }
    return self;
}
@end

@implementation BTFilePiecesInfo
- (instancetype)initWithPeerRequest:(libtorrent::peer_request)pr pieceLength:(int)pl {
    if (self = [super init]) {
        _startPiece = pr.piece;
        _endPiece = _startPiece + (pr.length / pl);
        _startPieceOffset = pr.start;
        _length = pr.length;
    }
    return self;
}
@end
