//
//  Gate.h
//  Flow2Go
//
//  Created by Christian Hansen on 14/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FCSFile;
@class CPTXYPlotSpace;
@class Gate;
@class Plot;

@interface GateCalculator : NSObject

+ (BOOL)eventInsideGateVertices:(NSArray *)vertices
                       onEvents:(FCSFile *)fcsFile
                        eventNo:(NSUInteger)eventNo
                         xParam:(NSUInteger)xPar
                         yParam:(NSUInteger)yPar;

+ (GateCalculator *)eventsInsideGateWithVertices:(NSArray *)vertices
                                        gateType:(GateType)gateType
                                         fcsFile:(FCSFile *)fcsFile
                                      insidePlot:(Plot *)plot
                                          subSet:(NSUInteger *)subSet
                                     subSetCount:(NSUInteger)subSetCount;

@property (nonatomic) NSUInteger numberOfCellsInside;
@property (nonatomic) NSUInteger *eventsInside;
@property (nonatomic) NSUInteger numberOfDensityPoints;
@property (nonatomic) DensityPoint *densityPoints;
@property (nonatomic, strong) NSArray *gateVertices;

@end