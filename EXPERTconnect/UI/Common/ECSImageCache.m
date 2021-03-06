//
//  ECSImageCache.m
//  EXPERTconnect
//
//  Copyright (c) 2015 Humanify, Inc. All rights reserved.
//

#import "ECSImageCache.h"
#import "EXPERTconnect.h"
#import "ECSUtilities.h"

NSString *const ECSImageCacheImageDownloadedNotification = @"ECSImageCacheImageDownloadedNotification";
NSString *const ECSImageCacheImageDownloadFailedNotification = @"ECSImageCacheImageDownloadFailedNotification";

NSString *const ECSImageCacheImageUrlKey = @"ECSImageCacheImageUrlKey";
NSString *const ECSImageDownloadFailedMessageKey = @"ECSImageDownloadFailedMessageKey";

@interface ECSImageCache()

@property (strong, nonatomic) NSMutableArray *imagePathsDownloading;

@end

@implementation ECSImageCache

- (UIImage *)imageForPath:(NSString *)path
{
    UIImage *image = nil;
    if (!IsNullOrEmpty(path))
    {
        if ([path hasPrefix:@"http"] || [path hasPrefix:@"https"])
        {
            image = [self objectForKey:path];
        }
        else
        {
            image = [UIImage imageNamed:path inBundle:[NSBundle mainBundle] compatibleWithTraitCollection:nil];
            
            if (!image)
            {
                image = [UIImage imageNamed:path inBundle:[NSBundle bundleForClass:[ECSImageCache class]] compatibleWithTraitCollection:nil];
            }
            
            // Cocoapods
            if (!image) {
                NSBundle *bundle = [NSBundle bundleForClass:[EXPERTconnect class]];
                NSURL *bundleURL = [[bundle resourceURL] URLByAppendingPathComponent:@"EXPERTconnect.bundle"];
                NSBundle *resourceBundle = [NSBundle bundleWithURL:bundleURL];
                
                image = [UIImage imageNamed:path inBundle:resourceBundle compatibleWithTraitCollection:nil];
            }
        }
    }
    
    return image;
}

- (void)downloadImageForPath:(NSString *)path
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:path]];

    [self downloadImageWithRequest:request];
}

- (void)downloadImageWithRequest:(NSURLRequest *)request
{
    
    
    __weak typeof(self) weakSelf = self;
    
    NSString *path = [[request URL] absoluteString];
    
    __block BOOL shouldDownload = YES;
    [self.imagePathsDownloading enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isEqualToString:path])
        {
            shouldDownload = NO;
            *stop = YES;
        }
    }];
    
    if (!shouldDownload)
    {
        return;
    }
    
    [self.imagePathsDownloading addObject:path];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data && !error)
        {
            UIImage *image = [UIImage imageWithData:data];
            
            if (image)
            {
                [weakSelf setObject:image forKey:path];
                [[NSNotificationCenter defaultCenter] postNotificationName:ECSImageCacheImageDownloadedNotification object:nil userInfo:@{ECSImageCacheImageUrlKey: path}];
            } else  {
                // kwashington [08/24/2015] - Handle Image Not Found!
                NSError* error;
                NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:kNilOptions
                                                                       error:&error];
                
                NSString* message = [NSString stringWithFormat:@"%@: %@ [%@]", [json objectForKey:@"error"], [json objectForKey:@"exception"], [json objectForKey:@"message"]];
                [[NSNotificationCenter defaultCenter] postNotificationName:ECSImageCacheImageDownloadFailedNotification object:nil userInfo:@{ECSImageDownloadFailedMessageKey: message}];
            }
        }
    }];
    
    [dataTask resume];
    
    
}

@end
