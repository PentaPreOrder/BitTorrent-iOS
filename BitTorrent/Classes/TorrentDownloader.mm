#import "TorrentDownloader.h"
#import "TorrentInfo.h"

#import <objc/runtime.h>
#import <fstream>

#import "boost/make_shared.hpp"
#import "libtorrent/entry.hpp"
#import "libtorrent/bencode.hpp"
#import "libtorrent/session.hpp"
#import "libtorrent/torrent_info.hpp"
#import "libtorrent/torrent_status.hpp"
#import "libtorrent/create_torrent.hpp"
#import "libtorrent/session_handle.hpp"
#import "libtorrent/extensions/metadata_transfer.hpp"
#import "libtorrent/extensions/ut_metadata.hpp"
#import "libtorrent/extensions/ut_pex.hpp"

using namespace libtorrent;
namespace lt = libtorrent;

@interface BTDownloadInfo ()
- (instancetype)initWithStatus:(torrent_status)status;
@end

@interface TorrentDownloader ()
@property (nonatomic,assign) BOOL downloading;
@end

@implementation TorrentDownloader

- (instancetype)initWithTorrent:(NSString *)url {
    if (self = [super init]) {
        _torrentInfo = [TorrentInfo infoWithfile:url];
        for (BTFile *file in self.torrentInfo.files) {
            self.progressPrint = YES;
            file.selected = (file.isPadFile || file.hidden) ? NO : YES;
        }
    }
    return self;
}

- (void)startDownload {
    if (!self.downloading) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            error_code ec;
            std::pair<int,int> p1(6881, 6891);
            lt::session s;
            s.listen_on(p1, ec);
            add_torrent_params p;
            NSString *tmp = NSTemporaryDirectory();
            p.save_path = [tmp cStringUsingEncoding:NSUTF8StringEncoding];
            p.ti = boost::make_shared<torrent_info>(std::string([self.torrentInfo.torrentPath cStringUsingEncoding:NSUTF8StringEncoding]), boost::ref(ec), 0);
            if (ec) {
                fprintf(stderr, "%s\n", ec.message().c_str());
                return;
            }
            lt::torrent_handle h = s.add_torrent(p, ec);
            if (ec) {
                fprintf(stderr, "%s\n", ec.message().c_str());
                return;
            }
            
            for (int i = 0; i < self.torrentInfo.files.count; i++) {
                h.file_priority(i, self.torrentInfo.files[i].selected ? 7 : 0);
            }
            
            while (!h.is_seed()) {
                libtorrent::torrent_status status = h.status();
                
                std::vector<boost::int64_t> progress;
                h.file_progress(progress);
                for (int i = 0; i < self.torrentInfo.files.count; i++) {
                    BTFile *file = self.torrentInfo.files[i];
                    if (file.selected) file.progress = (double)progress[i] / (double)file.size;
                }
                
                if (self.progressPrint) {
                    NSArray *statusStr = @[@"queued",@"checking",@"downloading metadata",@"downloading",@"finished",@"seeding",@"allocating",@"checking fastresume"];
                    NSLog(@" %@ %.2f%% (download rate: %.1fkb/s  upload rate: %.1fkB/s  peers: %d)",statusStr[status.state],status.progress*100,status.download_rate/1000.0,status.upload_rate/1000.0,status.num_peers);
                    for (BTFile *file in self.torrentInfo.files) {
                        if (file.selected) NSLog(@"%@ <%.2f%%>",file.name,file.progress*100);
                    }
                }
                
                if ([self.delegate respondsToSelector:@selector(btDownloader:progressDidUpdate:)]) {
                    BTDownloadInfo *info = [[BTDownloadInfo alloc] initWithStatus:status];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate btDownloader:self progressDidUpdate:info];
                    });
                }
                if (status.progress >= 1) {
                    if ([self.delegate respondsToSelector:@selector(btDownloaderDidFinishDownload:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate btDownloaderDidFinishDownload:self];
                            self.downloading = NO;
                        });
                    }
                    break;
                }
                [NSThread sleepForTimeInterval:1];
            }
        });
    }
    self.downloading = YES;
}


@end
                         
@implementation BTDownloadInfo
- (instancetype)initWithStatus:(libtorrent::torrent_status)status {
    if (self = [super init]) {
        self.state = (BTDownloadInfoType)status.state;
        self.progress = status.progress;
        self.downloadSpeed = status.download_rate;
        self.uploadSpeed = status.upload_rate;
        self.peer = status.num_peers;
    }
    return self;
}
@end

@implementation BTFile (BTFileSelection)
- (BOOL)selected {
    return ((NSNumber *)objc_getAssociatedObject(self, @selector(setSelected:))).boolValue;
}
- (void)setSelected:(BOOL)selected {
    objc_setAssociatedObject(self, _cmd, @(selected), OBJC_ASSOCIATION_ASSIGN);
}
@end

@implementation TorrentMaker
+ (void)downloadTorrentFromMagnet:(NSString *)magnet complete:(void (^)(NSString *))complete {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        error_code ec;
        std::pair<int,int> p1(6881,6891);
        lt::session s;
        s.add_extension(&libtorrent::create_ut_metadata_plugin);
        s.add_extension(&libtorrent::create_metadata_plugin);
        s.add_extension(&libtorrent::create_ut_pex_plugin);
        const std::pair<std::string, int> utNode("router.utorrent.com",6881);
        s.add_dht_router(utNode);
        const std::pair<std::string, int> btNode("router.bittorrent.com",6881);
        s.add_dht_router(btNode);
        const std::pair<std::string, int> trNode("dht.transmissionbt.com",6881);
        s.add_dht_router(trNode);
        const std::pair<std::string, int> aeNode("dht.aelitis.com",6881);
        s.add_dht_router(aeNode);
        const std::pair<std::string, int> commetNode("router.bitcomet.com",6881);
        s.add_dht_router(commetNode);
        s.start_dht();
        s.start_lsd();
        s.start_upnp();
        s.start_natpmp();
        s.listen_on(p1, ec);
        if (ec) {
            fprintf(stderr, "%s\n", ec.message().c_str());
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(nil);
            });
            return;
        }
        add_torrent_params p;
        
        NSString *tmp = NSTemporaryDirectory();
        p.save_path = [tmp cStringUsingEncoding:NSUTF8StringEncoding];
        std::string sUrl([magnet cStringUsingEncoding:NSUTF8StringEncoding]);
        p.url = sUrl;
        lt::torrent_handle h = s.add_torrent(p, ec);
        if (ec) {
            fprintf(stderr, "%s\n", ec.message().c_str());
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(nil);
            });
            return;
        }
        while (!h.has_metadata()) {
            libtorrent::torrent_status status = h.status();
            NSLog(@"torrent downloading (rate: %.1fkb/s peers: %d)",status.download_rate/1000.0,status.num_peers);
            [NSThread sleepForTimeInterval:1];
        }
        s.pause();
        
        torrent_info tf = h.get_torrent_info();
        create_torrent torrent = lt::create_torrent(tf);
        entry e = torrent.generate();
        std::vector<char> buffer;
        bencode(std::back_inserter(buffer), e);
        std::string str(buffer.begin(), buffer.end());
        
        NSString *path = [NSString stringWithFormat:@"%@%s.torrent",tmp,tf.name().c_str()];
        std::ofstream fout([path cStringUsingEncoding:NSUTF8StringEncoding],std::ios::trunc);
        int flag = 0;
        if (fout.is_open()) {
            fout << str << std::endl;
            fout.close();
        }else flag = EOF;
        
        s.remove_torrent(h);
        dispatch_async(dispatch_get_main_queue(), ^{
            complete(flag == EOF ? nil : path);
        });
    });
}


@end
