//
//  FCSFile.h
//  Flow2Go
//
//  Created by Christian Hansen on 05/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FCSFile : NSObject

+ (FCSFile *)fcsFileWithPath:(NSString *)path error:(NSError **)error;
+ (NSDictionary *)fcsKeywordsWithFCSFileAtPath:(NSString *)path;

- (void)cleanUpEventsForFCSFile;

+ (NSInteger)parameterNumberForName:(NSString *)PiNShortName inFCSFile:(FCSFile *)fcsFile;
+ (NSString *)parameterShortNameForParameterIndex:(NSInteger)parameterIndex inFCSFile:(FCSFile *)fcsFile;
+ (NSString *)parameterNameForParameterIndex:(NSInteger)parameterIndex inFCSFile:(FCSFile *)fcsFile;
- (NSInteger)rangeOfParameterIndex:(NSInteger)parameterIndex;
- (AxisType)axisTypeForParameterIndex:(NSInteger)parameterIndex;

@property (nonatomic) double **events;
@property (nonatomic) Range *ranges;

@property (nonatomic, strong) NSDictionary *calibrationUnitNames;
@property (nonatomic, strong) NSDictionary *text;
@property (nonatomic, strong) NSDictionary *analysis;
@property (nonatomic) NSUInteger noOfEvents;
@property (nonatomic) NSUInteger noOfParams;

@end