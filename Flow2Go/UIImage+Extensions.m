//
//  UIImage+Extensions.m
//  Flow2Go
//
//  Created by Christian Hansen on 07/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "UIImage+Extensions.h"
#import <QuartzCore/QuartzCore.h>
@implementation UIImage (Extensions)

+ (UIImage *)imageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

@end