//
//  TDDataController.h
//  The Dissonant
//
//  Created by Jonathan Gerber on 11/8/13.
//  Copyright (c) 2013 Malingo Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TDPost;
@class TDAuthor;
@class TDCategory;

@interface TDDataController : NSObject <NSURLConnectionDelegate>

@property (nonatomic) NSOperationQueue *imageDownloadQueue;

- (void)fetchRecentPosts;
- (void)fetchPostsForCategory:(TDCategory *)category;
- (TDPost *)postWithGUID:(int)guid;
- (TDAuthor *)authorWithGUID:(int)guid;
- (NSArray *)categories;
- (TDCategory *)categoryWithGUID:(int)guid;
- (NSFetchedResultsController *)frcForPosts;
- (NSFetchedResultsController *)frcForFavorites;
- (NSArray *)categoriesForCells;
- (NSFetchedResultsController *)frcForCategory:(TDCategory *)category;
@end
