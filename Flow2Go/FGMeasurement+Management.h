//
//  FGMeasurement+Management.h
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGMeasurement.h"
@class FGKeyword;

@interface FGMeasurement (Management)

- (NSError *)readInFCSKeyWords;
- (FGKeyword *)existingKeywordForKey:(NSString *)key;
- (NSString *)md5Hash;
+ (void)deleteMeasurement:(FGMeasurement *)measurement;
+ (void)deleteMeasurements:(NSArray *)measurements;

- (FGFileType)fileType;
+ (FGFileType)fileTypeForFileName:(NSString *)fileNameWithExtension;

@property (nonatomic, readonly) NSString *fullFilePath;
@property (nonatomic, readonly) NSString *enclosingFolder;
@property (nonatomic, readonly) FGFileType fileType;
@property (nonatomic, readonly) BOOL isDownloaded;
@property (nonatomic, weak, readonly) NSString *downloadDateAsLocalizedString;

@end