//
//  ViewController.m
//  Example
//
//  Created by xinglei on 2020/9/10.
//  Copyright © 2020 xinglei. All rights reserved.
//

#import "ViewController.h"
#import <BitTorrent/TorrentDownloader.h>
#import <BitTorrent/TorrentInfo.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"train_to_busan" ofType:@"torrent"];
    /*
    TorrentInfo *info = [TorrentInfo infoWithfile:path];
    [TorrentMaker downloadTorrentFromMagnet:info.magnet complete:^(NSString *torrentPath) {
        NSLog(@"torrent: %@", torrentPath);
    }];
    */
    TorrentDownloader *downloader = [[TorrentDownloader alloc] initWithTorrent:path];
    [downloader startDownload];
}

@end
