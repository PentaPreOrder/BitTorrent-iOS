#import <Foundation/Foundation.h>
#import "TorrentInfo.h"

@protocol TorrentDownloaderDelegate;

@interface TorrentDownloader : NSObject

@property (nonatomic,weak) id<TorrentDownloaderDelegate> delegate;

@property (nonatomic,strong,readonly) TorrentInfo *torrentInfo;

@property (nonatomic,assign) BOOL progressPrint;
@property (nonatomic,assign,readonly) BOOL downloading;

- (instancetype)initWithTorrent:(NSString *)url;
- (void)startDownload;

@end


@class BTDownloadInfo;
@protocol TorrentDownloaderDelegate <NSObject>

- (void)btDownloader:(TorrentDownloader *)downloader progressDidUpdate:(BTDownloadInfo *)downloadInfo;
- (void)btDownloaderDidFinishDownload:(TorrentDownloader *)downloader;

@end

typedef NS_ENUM(NSUInteger, BTDownloadInfoType) {
    BTDownloadInfoTypeQueued,
    BTDownloadInfoTypeChecking,
    BTDownloadInfoTypeDownloadingMetadata,
    BTDownloadInfoTypeDownloading,
    BTDownloadInfoTypeFinished,
    BTDownloadInfoTypeSeeding,
    BTDownloadInfoTypeCheckingFastresume
};

@interface BTDownloadInfo : NSObject
@property (nonatomic,assign) BTDownloadInfoType state;
@property (nonatomic,assign) float progress;
@property (nonatomic,assign) int downloadSpeed;
@property (nonatomic,assign) int uploadSpeed;
@property (nonatomic,assign) int peer;
@end

@interface BTFile (BTFileSelection)
@property (nonatomic,assign) BOOL selected;
@end


@interface TorrentMaker : NSObject
+ (void)downloadTorrentFromMagnet:(NSString *)magnet complete:(void(^)(NSString *torrentPath))complete;
@end
