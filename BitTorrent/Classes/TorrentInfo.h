#import <Foundation/Foundation.h>

@class DHTNode,Tracker,BTFile,BTFilePiecesInfo,BTBitfield;

@interface TorrentInfo : NSObject

@property (nonatomic,copy,readonly) NSString *torrentPath;

@property (nonatomic,copy,readonly) NSString *name;
@property (nonatomic,copy,readonly) NSString *creator;
@property (nonatomic,copy,readonly) NSString *comment;
@property (nonatomic,copy,readonly) NSString *magnet;
@property (nonatomic,copy,readonly) NSString *infoHash;
@property (nonatomic,assign,readonly) int piecesCount;
@property (nonatomic,assign,readonly) int pieceSize;
@property (nonatomic,strong,readonly) NSArray<DHTNode *> *dhtNodes;
@property (nonatomic,strong,readonly) NSArray<Tracker *> *trackers;
@property (nonatomic,strong,readonly) NSArray<BTFile *> *files;

+ (instancetype)infoWithfile:(NSString *)path;

- (void)dump;

@end

@interface DHTNode : NSObject
@property (nonatomic,copy) NSString *nodeID;
@property (nonatomic,assign) int distance;
@end

@interface Tracker : NSObject
@property (nonatomic,assign) uint8_t tier;
@property (nonatomic,copy) NSString *url;
@end


@interface BTFile : NSObject
@property (nonatomic,copy,readonly) NSString *name;
@property (nonatomic,assign,readonly) int64_t offset;
@property (nonatomic,assign,readonly) int64_t size;
@property (nonatomic,assign,readonly) BOOL isPadFile;
@property (nonatomic,assign,readonly) BOOL executable;
@property (nonatomic,assign,readonly) BOOL hidden;
@property (nonatomic,assign,readonly) int firstPiece;
@property (nonatomic,assign,readonly) int lastPiece;
@property (nonatomic,assign,readonly) uint32_t mtime;
@property (nonatomic,copy,readonly) NSString *fileHash;
@property (nonatomic,copy,readonly) NSString *symlink;
@property (nonatomic,strong,readonly) BTFilePiecesInfo *piecesInfo;

@property (nonatomic,assign) float progress;
@end

@interface BTFilePiecesInfo : NSObject
@property (nonatomic,assign,readonly) int startPiece;
@property (nonatomic,assign,readonly) int endPiece;
@property (nonatomic,assign,readonly) int startPieceOffset;
@property (nonatomic,assign,readonly) int length;
@end
