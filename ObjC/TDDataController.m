//
//  TDDataController.m
//  The Dissonant
//
//  Created by Jonathan Gerber on 11/8/13.
//  Copyright (c) 2013 Malingo Studios. All rights reserved.
//

#import "TDDataController.h"
#import "TDCategory.h"
#import "TDPost.h"
#import "TDAppDelegate.h"
#import "TDAuthor.h"
#import "NSString+XMLEntities.m"
#include <sys/xattr.h>

@interface TDDataController ()
@property (nonatomic) NSURLConnection *recentPosts;
@property (nonatomic) NSMutableData *recentPostsData;
@property (nonatomic) NSURLConnection *categoryPosts;
@property (nonatomic) NSMutableData *categoryPostsData;
@property (nonatomic) BOOL isLoading;

@end

@implementation TDDataController

- (NSOperationQueue *)imageDownloadQueue {
    if (!_imageDownloadQueue) {
        _imageDownloadQueue = [[NSOperationQueue alloc] init];
        _imageDownloadQueue.maxConcurrentOperationCount = 4;
    }
    return _imageDownloadQueue;
}

- (void)fetchRecentPosts
{
    if (!self.isLoading) {
        self.isLoading = YES;
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://thedissonant.com/api/get_recent_posts?count=100"]];
        self.recentPosts = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    } else {
        NSLog(@"loading");
    }
}

- (void)fetchPostsForCategory:(TDCategory *)category
{
    if (!self.isLoading) {
        self.isLoading = YES;
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://thedissonant.com/api/get_category_posts?id=%d&count=100", category.guid.intValue]]];
        self.categoryPosts = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    } else {
        NSLog(@"loading");
    }
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if (connection == self.recentPosts) {
        self.recentPostsData = [[NSMutableData alloc] init];
    } else if (connection == self.categoryPosts) {
        self.categoryPostsData = [[NSMutableData alloc] init];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (connection == self.recentPosts) {
        [self.recentPostsData appendData:data];
    } else if (connection == self.categoryPosts) {
        [self.categoryPostsData appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSMutableDictionary *result;
    
    if (connection == self.recentPosts) {
        NSString *stringWithData = [[NSString alloc] initWithData:self.recentPostsData encoding:NSUTF8StringEncoding];
        result = [NSJSONSerialization JSONObjectWithData:[stringWithData dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    } else {
        result = [NSJSONSerialization JSONObjectWithData:self.categoryPostsData options:NSJSONReadingMutableContainers error:nil];
    }
    
    if ([[result objectForKey:@"status"] isEqualToString: @"ok"]) {
        NSArray *posts = [result objectForKey:@"posts"];
        NSMutableArray *postsWithImagesToDownload = [[NSMutableArray alloc] initWithCapacity:posts.count];
        for (NSDictionary *post in posts) {
            
            NSString *content = [post objectForKey:@"content"];
            NSDictionary *custom_fields = [post objectForKey:@"custom_fields"];
            
            NSString *dateStr = [post objectForKey:@"date"]; //"2013-11-08 20:59:19";
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSDate *date = [dateFormat dateFromString:dateStr];
            int guid = [[post objectForKey:@"id"] intValue];
            NSString *permalink = [post objectForKey:@"url"];
            NSDictionary *thumbnails = [post objectForKey:@"thumbnail_images"];
            NSDictionary *smallImageDict = [thumbnails objectForKey:@"thumbnail"];
            NSString *smallImage = [smallImageDict objectForKey:@"url"];
            NSString *thumbnail = [[thumbnails objectForKey:@"medium"] objectForKey:@"url"];
            /*
             "thumbnail_images" =     {
             full =         {
             height = 200;
             url = "http://thedissonant.com/wp-content/uploads/2013/11/Midlake-Antiphon-608x608-e1383973280868.jpg";
             width = 200;
             };
             large =         {
             height = 200;
             url = "http://thedissonant.com/wp-content/uploads/2013/11/Midlake-Antiphon-608x608-e1383973280868.jpg";
             width = 200;
             };
             medium =         {
             height = 300;
             url = "http://thedissonant.com/wp-content/uploads/2013/11/Midlake-Antiphon-608x608-300x300.jpg";
             width = 300;
             };
             "post-thumbnail" =         {
             height = 270;
             url = "http://thedissonant.com/wp-content/uploads/2013/11/Midlake-Antiphon-608x608-604x270.jpg";
             width = 604;
             };
             thumbnail =         {
             height = 150;
             url = "http://thedissonant.com/wp-content/uploads/2013/11/Midlake-Antiphon-608x608-150x150.jpg";
             width = 150;
             };
             };
             */
            
            
            NSString *title = [post objectForKey:@"title"];
            title = [title stringByDecodingXMLEntities];
            TDPost *newPost = [self postWithGUID:guid];
            if (!newPost) {
                newPost = [NSEntityDescription insertNewObjectForEntityForName:@"TDPost" inManagedObjectContext:[[TDAppDelegate appDelegate] managedObjectContext]];
                [newPost setGuid:[NSNumber numberWithInteger:guid]];
                

            }
            BOOL shouldDownload = NO;
            if (([thumbnail length] && ![thumbnail isEqualToString:newPost.remoteImage]) || [newPost.image length] == 0) {
                shouldDownload = YES;
                [newPost setRemoteImage:thumbnail];
            }
            if (([smallImage length] && ![smallImage isEqualToString:newPost.remoteSmallImage]) || [newPost.smallImage length] == 0) {
                [newPost setRemoteSmallImage:smallImage];
                shouldDownload = YES;
                
            }
            if (shouldDownload == YES) {
                [postsWithImagesToDownload addObject:newPost];
            }
            content = [content stringByDecodingXMLEntities];
            [newPost setContent:content];
            [newPost setUrl:permalink];
                if ([[custom_fields objectForKey:@"youtube_link"] count] > 0) {
                    NSString *youTubeLink = [[custom_fields objectForKey:@"youtube_link"] objectAtIndex:0];
                    if (![youTubeLink isEqualToString:newPost.youtube]) {
                        [newPost setYoutube:youTubeLink];
                    }
                }
                if ([[custom_fields objectForKey:@"listen_on_soundcloud"] count] > 0) {
                    NSString *youTubeLink = [[custom_fields objectForKey:@"listen_on_soundcloud"] objectAtIndex:0];
                    if (![youTubeLink isEqualToString:newPost.listenOnSoundCloud]) {
                        [newPost setListenOnSoundCloud:youTubeLink];
                    }
                }
                if ([[custom_fields objectForKey:@"listen_on_itunes"] count] > 0) {
                    NSString *youTubeLink = [[custom_fields objectForKey:@"listen_on_itunes"] objectAtIndex:0];
                    if (![youTubeLink isEqualToString:newPost.listenOnItunes]) {
                        [newPost setListenOnItunes:youTubeLink];
                    }
                }
                if ([[custom_fields objectForKey:@"listen_on_rhapsody"] count] > 0) {
                    NSString *youTubeLink = [[custom_fields objectForKey:@"listen_on_rhapsody"] objectAtIndex:0];
                    if (![youTubeLink isEqualToString:newPost.listenOnRhapsody]) {
                        [newPost setListenOnRhapsody:youTubeLink];
                    }
                }
                if ([[custom_fields objectForKey:@"listen_on_spotify"] count] > 0) {
                    NSString *youTubeLink = [[custom_fields objectForKey:@"listen_on_spotify"] objectAtIndex:0];
                    if (![youTubeLink isEqualToString:newPost.listenOnSpotify]) {
                        [newPost setListenOnSpotify:youTubeLink];
                    }
                }
                if ([[custom_fields objectForKey:@"listen_on_youtube"] count] > 0) {
                    NSString *youTubeLink = [[custom_fields objectForKey:@"listen_on_youtube"] objectAtIndex:0];
                    if (![youTubeLink isEqualToString:newPost.listenOnYouTube]) {
                        [newPost setListenOnYouTube:youTubeLink];
                    }
                }
                if ([[custom_fields objectForKey:@"listen_on_pandora"] count] > 0) {
                    NSString *youTubeLink = [[custom_fields objectForKey:@"listen_on_pandora"] objectAtIndex:0];
                    if (![youTubeLink isEqualToString:newPost.listenOnPandora]) {
                        [newPost setListenOnPandora:youTubeLink];
                    }
                }
                if ([[custom_fields objectForKey:@"listen_on_rdio"] count] > 0) {
                    NSString *youTubeLink = [[custom_fields objectForKey:@"listen_on_rdio"] objectAtIndex:0];
                    if (![youTubeLink isEqualToString:newPost.listenOnRdio]) {
                        [newPost setListenOnRdio:youTubeLink];
                    }
                }
                if ([[custom_fields objectForKey:@"listen_on_google_play"] count] > 0) {
                    NSString *youTubeLink = [[custom_fields objectForKey:@"listen_on_google_play"] objectAtIndex:0];
                    if (![youTubeLink isEqualToString:newPost.listenOnGooglePlay]) {
                        [newPost setListenOnGooglePlay:youTubeLink];
                    }
                }
                if ([[custom_fields objectForKey:@"listen_on_iheartradio"] count] > 0) {
                    NSString *youTubeLink = [[custom_fields objectForKey:@"listen_on_iheartradio"] objectAtIndex:0];
                    if (![youTubeLink isEqualToString:newPost.listenOnIHeartRadio]) {
                        [newPost setListenOnIHeartRadio:youTubeLink];
                    }
                }
                if ([[custom_fields objectForKey:@"listen_on_deezer"] count] > 0) {
                    NSString *youTubeLink = [[custom_fields objectForKey:@"listen_on_deezer"] objectAtIndex:0];
                    if (![youTubeLink isEqualToString:newPost.listenOnDeezer]) {
                        [newPost setListenOnDeezer:youTubeLink];
                    }
                }
                if ([[custom_fields objectForKey:@"listen_on_slacker"] count] > 0) {
                    NSString *youTubeLink = [[custom_fields objectForKey:@"listen_on_slacker"] objectAtIndex:0];
                    if (![youTubeLink isEqualToString:newPost.listenOnSlacker]) {
                        [newPost setListenOnSlacker:youTubeLink];
                    }
                }
            if (![title isEqualToString:newPost.title]) {
                [newPost setTitle:title];
            }
            if (date != newPost.date) {
                [newPost setDate:date];
            }

            NSDictionary *author = [post objectForKey:@"author"];
            int authorGuid = [[author objectForKey:@"id"] intValue];
            NSString *slug = [author objectForKey:@"slug"];
            TDAuthor *newAuthor = [self authorWithGUID:authorGuid];
            if (!newAuthor) {
                newAuthor = [NSEntityDescription insertNewObjectForEntityForName:@"TDAuthor" inManagedObjectContext:[[TDAppDelegate appDelegate] managedObjectContext]];
                [newAuthor setGuid:[NSNumber numberWithInt:authorGuid]];
                
                [newAuthor setRemoteImage:[NSString stringWithFormat:@"http://thedissonant.com/author/%@/?isAuthor=1", slug]];
                [self downloadImageForAuthor:newAuthor];
            }
            
            [newAuthor setSlug:slug];
            NSString *bio = [[author objectForKey:@"description"] stringByDecodingXMLEntities];
            NSString *name = [[author objectForKey:@"name"] stringByDecodingXMLEntities];
            if (![bio isEqualToString:newAuthor.bio]) {
                [newAuthor setBio:bio];
            }
            if (![name isEqualToString:newAuthor.displayname]) {
                [newAuthor setDisplayname:name];
            }
            
            [newPost setAuthor:newAuthor];

            NSArray *categories = [post objectForKey:@"categories"];
            for (NSDictionary *category in categories) {
                int catGuid = [[category objectForKey:@"id"] intValue];
                TDCategory *cat = [self categoryWithGUID:catGuid];
                if (cat) {
                    if (![newPost.categories containsObject:cat]) {
                        [newPost addCategoriesObject:cat];
                    }
                }
            }
           
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self downloadImagesForPosts:postsWithImagesToDownload];
        });
        
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        NSDate *lastFetch = [NSDate date];
        [defs setObject:lastFetch forKey:@"lastFetch"];
        [defs synchronize];
         [[TDAppDelegate appDelegate] saveContext];
    }
    self.isLoading = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LoadingFinished" object:nil];
}

- (void)downloadImageForAuthor:(TDAuthor *) author
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *urlString = author.remoteImage;
    if ([urlString hasPrefix:@"http"]) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:urlString]];
            NSString *stringFromData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if ([stringFromData hasPrefix:@"http"]) {
                NSURL *url = [NSURL URLWithString:stringFromData];
                NSString *path = [docsPath stringByAppendingPathComponent:[url lastPathComponent]];
                if (![fileManager fileExistsAtPath:path]) {

                    [self.imageDownloadQueue addOperationWithBlock:^{
                        NSString *path = [docsPath stringByAppendingPathComponent:[url lastPathComponent]];
                        NSData *data = [NSData dataWithContentsOfURL:url];
                        if (data) {
                            [data writeToFile:path atomically:YES];
                            [self addSkipBackupAttributeToItemAtURL:[NSURL URLWithString:path]];
                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                [author setImage:path];
                                [[TDAppDelegate appDelegate] saveContext];
                            });
                        }
                    }];
                } else {
                    [author setImage:path];
                    [[TDAppDelegate appDelegate] saveContext];
                }
            }
        });
    }

}
- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    const char* filePath = [[URL path] fileSystemRepresentation];
    
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    
    int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    return result == 0;
}

- (void)downloadImagesForPosts:(NSArray *)posts
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    
    for (TDPost *post in posts)
    {
        NSString *urlString = post.remoteImage;
        if ([urlString hasPrefix:@"http"]) {
            NSURL *url = [NSURL URLWithString:urlString];
            NSString *path = [docsPath stringByAppendingPathComponent:[url lastPathComponent]];
            if (![fileManager fileExistsAtPath:path]) {
//                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                    NSString *path = [docsPath stringByAppendingPathComponent:[url lastPathComponent]];
//                    NSData *data = [NSData dataWithContentsOfURL:url];
//                    if (data) {
//                        [data writeToFile:path atomically:YES];
//                        [post setImage:path];
//                        [[TDAppDelegate appDelegate] saveContext];
//                    }
//                });
                
                [self.imageDownloadQueue addOperationWithBlock:^{
                    NSString *path = [docsPath stringByAppendingPathComponent:[url lastPathComponent]];
                    NSData *data = [NSData dataWithContentsOfURL:url];
                    if (data) {
                        [data writeToFile:path atomically:YES];
                         [self addSkipBackupAttributeToItemAtURL:[NSURL URLWithString:path]];
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            [post setImage:path];
                            [[TDAppDelegate appDelegate] saveContext];
                        });
                    }
                }];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [post setImage:path];
                    [[TDAppDelegate appDelegate] saveContext];
                });
            }
        }
        NSString *urlString2 = post.remoteSmallImage;
        if ([urlString2 hasPrefix:@"http"]) {
            NSURL *url = [NSURL URLWithString:urlString2];
            NSString *path = [docsPath stringByAppendingPathComponent:[url lastPathComponent]];
            if (![fileManager fileExistsAtPath:path]) {
//                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                    NSString *path = [docsPath stringByAppendingPathComponent:[url lastPathComponent]];
//                    NSData *data = [NSData dataWithContentsOfURL:url];
//                    if (data) {
//                        [data writeToFile:path atomically:YES];
//                        [post setSmallImage:path];
//                        [[TDAppDelegate appDelegate] saveContext];
//                        dispatch_async(dispatch_get_main_queue(), ^(void){
//                            [[NSNotificationCenter defaultCenter] postNotificationName:@"imageDownloaded" object:nil];
//                        });
//                    }
//                });
                [self.imageDownloadQueue addOperationWithBlock:^{
                    NSString *path = [docsPath stringByAppendingPathComponent:[url lastPathComponent]];
                    NSData *data = [NSData dataWithContentsOfURL:url];
                    if (data) {
                        [data writeToFile:path atomically:YES];
                         [self addSkipBackupAttributeToItemAtURL:[NSURL URLWithString:path]];
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            [post setSmallImage:path];
                            [[TDAppDelegate appDelegate] saveContext];
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"imageDownloaded" object:nil];
                        });
                    }
                }];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [post setSmallImage:path];
                    [[TDAppDelegate appDelegate] saveContext];
                });
            }
        }
        
    }
    
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"error: %@", error);
    self.isLoading = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LoadingFinished" object:nil];
}

- (NSArray *)categories
{
    NSManagedObjectContext *moc = [[TDAppDelegate appDelegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"TDCategory" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    [request setSortDescriptors:@[sorter]];
    NSError *error;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    
    return array;
    
}

- (TDCategory *)categoryWithGUID:(int)guid
{
    NSManagedObjectContext *moc = [[TDAppDelegate appDelegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"TDCategory" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"guid == %i", guid];
    [request setPredicate:pred];
    NSError *error;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    
    return ([array count] > 0) ? [array objectAtIndex:0] : nil;
    
}

- (TDAuthor *)authorWithGUID:(int)guid
{
    NSManagedObjectContext *moc = [[TDAppDelegate appDelegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"TDAuthor" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"guid == %i", guid];
    [request setPredicate:pred];
    NSError *error;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    
    return ([array count] > 0) ? [array objectAtIndex:0] : nil;
    
}

- (TDPost *)postWithGUID:(int)guid
{
    NSManagedObjectContext *moc = [[TDAppDelegate appDelegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"TDPost" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"guid == %i", guid];
    [request setPredicate:pred];
    NSError *error;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    
    return ([array count] > 0) ? [array objectAtIndex:0] : nil;
}

//- (NSArray *)posts
//{
//    NSManagedObjectContext *moc = [[TDAppDelegate appDelegate] managedObjectContext];
//    NSEntityDescription *entityDescription = [NSEntityDescription
//                                              entityForName:@"TDPost" inManagedObjectContext:moc];
//    NSFetchRequest *request = [[NSFetchRequest alloc] init];
//    [request setEntity:entityDescription];
//    NSError *error;
//    NSArray *array = [moc executeFetchRequest:request error:&error];
//    
//    return ([array count] > 0) ? array : nil;
//}

- (NSFetchedResultsController *)frcForPosts
{
    NSManagedObjectContext *moc = [[TDAppDelegate appDelegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"TDPost" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [request setSortDescriptors:@[sorter]];
    [request setFetchBatchSize:20];
    
    NSFetchedResultsController *frc =
    [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                        managedObjectContext:moc sectionNameKeyPath:nil
                                                   cacheName:nil];
    
    return frc;
}

- (NSFetchedResultsController *)frcForFavorites
{
    NSManagedObjectContext *moc = [[TDAppDelegate appDelegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"TDPost" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [request setSortDescriptors:@[sorter]];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"isFavorite == %d", YES];
    [request setPredicate:pred];
    [request setFetchBatchSize:20];
    
    NSFetchedResultsController *frc =
    [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                        managedObjectContext:moc sectionNameKeyPath:nil
                                                   cacheName:nil];
    
    return frc;
}

- (NSFetchedResultsController *)frcForCategory:(TDCategory *)category
{
    NSManagedObjectContext *moc = [[TDAppDelegate appDelegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"TDPost" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [request setSortDescriptors:@[sorter]];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"ANY categories.guid == %d", category.guid.intValue];
    [request setPredicate:pred];
    [request setFetchBatchSize:20];
    
    NSFetchedResultsController *frc =
    [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                        managedObjectContext:moc sectionNameKeyPath:nil
                                                   cacheName:nil];
    
    return frc;
}

- (NSArray *)categoriesForCells
{
    NSMutableArray *mutableRetVal = [[NSMutableArray alloc] init];
    NSManagedObjectContext *moc = [[TDAppDelegate appDelegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"TDCategory" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    [request setSortDescriptors:@[sorter]];
    NSError *error;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    
    if (!error) {
        for (TDCategory *category in array) {
            //TODO: Get post image
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            if ([category.name length]) {
                [dict setObject:category.name forKey:@"name"];
            }
            if (category.guid) {
                [dict setObject:category.guid forKey:@"guid"];
            }
            NSEntityDescription *entityDescription2 = [NSEntityDescription
                                                      entityForName:@"TDPost" inManagedObjectContext:moc];
            NSFetchRequest *request2 = [[NSFetchRequest alloc] init];
            [request2 setEntity:entityDescription2];
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"ANY categories.guid == %d", category.guid.intValue];
            [request2 setPredicate:pred];
            [request2 setFetchLimit:5];
            NSSortDescriptor *sorter2 = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
            [request2 setSortDescriptors:@[sorter2]];
            NSError *error2;
            NSArray *array2 = [moc executeFetchRequest:request2 error:&error2];
            for (TDPost *post in array2) {
                if (![post.smallImage hasPrefix:@"http"] && [post.smallImage length]) {
                    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                        [dict setObject:post.image forKey:@"image"];
                    } else {
                        [dict setObject:post.smallImage forKey:@"image"];
                    }
                    
                    break;
                }
            }
            [mutableRetVal addObject:dict];
        }
    }
    return [NSArray arrayWithArray:mutableRetVal];
}

@end
