//
//  AnalysisViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 21/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "AnalysisViewController.h"
#import "PlotViewController.h"
#import "Analysis.h"
#import "FCSFile.h"
#import "Measurement.h"
#import "Plot.h"
#import "Gate.h"
#import "PinchLayout.h"
#import "PlotDetailTableViewController.h"
#import "MeasurementCollectionViewController.h"

@interface AnalysisViewController () <PlotViewControllerDelegate, PlotDetailTableViewControllerDelegate, UIPopoverControllerDelegate>

@property (nonatomic, strong) FCSFile *fcsFile;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) UIPopoverController *detailPopoverController;
@property (nonatomic, strong) NSMutableArray *objectChanges;
@property (nonatomic) CGPoint pickedCellLocation;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;

@end

@implementation AnalysisViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    UIPinchGestureRecognizer* pinchRecognizer = [UIPinchGestureRecognizer.alloc initWithTarget:self
                                                                                        action:@selector(handlePinchGesture:)];
    [self.collectionView addGestureRecognizer:pinchRecognizer];
    
    UINib *cellNib = [UINib nibWithNibName:@"PlotCellView" bundle:NSBundle.mainBundle];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Plot Cell"];
}



- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}



- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DetailViewDidAppear" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)showAnalysis:(Analysis *)analysis
{
    self.analysis = analysis;
    self.title = self.analysis.name;
    
    if (self.analysis.plots.count == 0
        && self.analysis != nil)
    {
        [Plot createPlotForAnalysis:self.analysis parentNode:nil];
    }
    [self _reloadFCSFile];
    
    [NSFetchedResultsController deleteCacheWithName:nil];
    self.fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"analysis == %@", analysis];;
    
    NSError * error = nil;
    [self.fetchedResultsController performFetch:&error];
    if (error) {
        // report error
    }
    [self.collectionView reloadData];
}

- (void)_reloadFCSFile
{
    [self.fcsFile cleanUpEventsForFCSFile];
    NSError *error;
    self.fcsFile = [FCSFile fcsFileWithPath:[HOME_DIR stringByAppendingPathComponent:self.analysis.measurement.filepath] error:&error];
    if (self.fcsFile == nil)
    {
        NSLog(@"Error: %@", error.localizedDescription);
    }
}


- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Plot *plot = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if ([indexPath isEqual:self.collectionView.indexPathsForSelectedItems.lastObject])
    {
        return;
    }
    Gate *parentGate = (Gate *)plot.parentNode;
    
    UILabel *nameLabel = (UILabel *)[cell viewWithTag:1];
    nameLabel.text = plot.name;
    
    UILabel *countLabel = (UILabel *)[cell viewWithTag:2];
    countLabel.text = [NSString stringWithFormat:@"%i cells", parentGate.cellCount.integerValue];
    
    UIButton *infoButton = (UIButton *)[cell viewWithTag:5];
    [infoButton addTarget:self action:@selector(infoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    UIImageView *plotImageView = (UIImageView *)[cell viewWithTag:6];
    plotImageView.image = plot.image;
    
    if (parentGate == nil)
    {
        nameLabel.text = [NSString stringWithFormat:@"%@", self.analysis.measurement.filename];
        countLabel.text = [NSString stringWithFormat:@"%i cells", self.analysis.measurement.countOfEvents.integerValue];
    }
}


- (void)infoButtonTapped:(UIButton *)infoButton
{
    UICollectionViewCell *cell = (UICollectionViewCell *)infoButton.superview.superview;
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    
    UINavigationController *plotNavigationVC = [self.storyboard instantiateViewControllerWithIdentifier:@"plotDetailTableViewController"];
    PlotDetailTableViewController *plotTVC = (PlotDetailTableViewController *)plotNavigationVC.topViewController;
    plotTVC.delegate = self;
    plotTVC.plot = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (self.detailPopoverController.isPopoverVisible)
    {
        UINavigationController *navCon = (UINavigationController *)self.detailPopoverController.contentViewController;
        [self.detailPopoverController dismissPopoverAnimated:YES];
        if ([navCon.topViewController isKindOfClass:PlotDetailTableViewController.class])
        {
            return;
        }
    }
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        self.detailPopoverController = [UIPopoverController.alloc initWithContentViewController:plotNavigationVC];
        self.detailPopoverController.delegate = self;
        [self.detailPopoverController presentPopoverFromRect:infoButton.frame inView:cell.contentView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        [self presentViewController:plotNavigationVC animated:YES completion:nil];
    }
    [plotTVC setEditing:NO animated:YES];
}


- (void)doneTapped
{
    for (UIView *aSubView in self.view.subviews)
    {
        [aSubView removeFromSuperview];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        [self.fcsFile cleanUpEventsForFCSFile];
    }];
}


- (FCSFile *)fcsFile
{
    if (!_fcsFile)
    {
        NSError *error;
        _fcsFile = [FCSFile fcsFileWithPath:[DOCUMENTS_DIR stringByAppendingPathComponent:self.analysis.measurement.filename] error:&error];
    }
    return _fcsFile;
}


#define PLOTVIEWSIZE 500
#define NAVIGATION_BAR_HEIGHT 44

- (void)_presentPlot:(Plot *)plot
{
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:plot];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    self.pickedCellLocation = cell.center;
    UIImageView *plotImageView = (UIImageView *)[cell viewWithTag:6];
    CGRect destBounds = CGRectMake(0, 0, PLOTVIEWSIZE, PLOTVIEWSIZE);
    CGPoint destCenter = CGPointMake(self.collectionView.window.bounds.size.width / 2.0, self.collectionView.window.bounds.size.height / 2.0);
    
    [UIView animateWithDuration:0.5 animations:^{
        [self _hideLabels:YES forCell:cell];
        [self.collectionView bringSubviewToFront:cell];
        plotImageView.bounds = destBounds;
        plotImageView.center = [self.collectionView.window convertPoint:destCenter toView:self.collectionView];
        cell.bounds = destBounds;
        cell.center = [self.collectionView.window convertPoint:destCenter toView:self.collectionView];
    } completion:^(BOOL finished) {
        UINavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"plotViewController"];
        PlotViewController *plotViewController = (PlotViewController *)navigationController.topViewController;
        plotViewController.delegate = self;
        plotViewController.plot = plot;
        navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
        navigationController.navigationBar.translucent = YES;
        [navigationController setNavigationBarHidden:YES animated:NO];
        [self presentViewController:navigationController animated:NO completion:nil];
        navigationController.view.superview.frame  = destBounds; 
        navigationController.view.superview.center = destCenter;
    }];
}


- (void)_hideLabels:(BOOL)hidden forCell:(UICollectionViewCell *)cell
{
    UILabel *nameLabel = (UILabel *)[cell viewWithTag:1];
    nameLabel.hidden = hidden;
    
    UILabel *countLabel = (UILabel *)[cell viewWithTag:2];
    countLabel.hidden = hidden;
    
    UIButton *infoButton = (UIButton *)[cell viewWithTag:5];
    infoButton.hidden = hidden;
}


- (void)deletePlot:(Plot *)plotToBeDeleted
{
    BOOL success = [plotToBeDeleted deleteInContext:self.analysis.managedObjectContext];
    [self.analysis.managedObjectContext save];
    if (!success)
    {
        UIAlertView *alertView = [UIAlertView.alloc initWithTitle:NSLocalizedString(@"Error", nil)
                                                          message:[NSLocalizedString(@"Could not delete plot \"", nil) stringByAppendingFormat:@"%@\"", plotToBeDeleted.name]
                                                         delegate:nil
                                                cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                otherButtonTitles: nil];
        [alertView show];
    }
}


#pragma mark - Popover Controller Delegate
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    UINavigationController *navigationController = (UINavigationController *)popoverController.contentViewController;
    return !navigationController.topViewController.editing;
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest.alloc init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Plot"
                                      inManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    fetchRequest.fetchBatchSize = 50;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"analysis == %@", self.analysis];
    
    // Edit the sort key as appropriate.
    fetchRequest.sortDescriptors = @[[NSSortDescriptor.alloc initWithKey:@"dateCreated" ascending:YES]];
    
    NSFetchedResultsController *aFetchedResultsController = [NSFetchedResultsController.alloc initWithFetchRequest:fetchRequest
                                                                                              managedObjectContext:[NSManagedObjectContext defaultContext].parentContext
                                                                                                sectionNameKeyPath:nil
                                                                                                         cacheName:nil];
    
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    return _fetchedResultsController;
}


#pragma mark - Fetched Resultscontroller delegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    if (!_objectChanges) {
        _objectChanges = NSMutableArray.array;
    }
}



- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    NSLog(@"update");
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    [_objectChanges addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{    
    if ([_objectChanges count] > 0)
    {
        [self.collectionView performBatchUpdates:^{
            
            for (NSDictionary *change in _objectChanges)
            {
                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                    
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    switch (type)
                    {
                        case NSFetchedResultsChangeInsert:
                            [self.collectionView insertItemsAtIndexPaths:@[obj]];
                            break;
                        case NSFetchedResultsChangeDelete:
                            [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                            break;
                        case NSFetchedResultsChangeUpdate:
                            [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                            break;
                        case NSFetchedResultsChangeMove:
                            [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                            break;
                    }
                }];
            }
        } completion:^(BOOL finished) {
            //[self.fetchedResultsController performFetch:nil];
            //[self.collectionView reloadData];
            
        }];
    }
    [_objectChanges removeAllObjects];
}


#pragma mark - PlotViewController delegate
- (FCSFile *)fcsFileForPlot:(Plot *)plot
{
    return self.fcsFile;
}


- (void)plotViewController:(PlotViewController *)plotViewController didSelectGate:(Gate *)gate forPlot:(Plot *)plot
{
    [self dismissViewControllerAnimated:YES completion:^{
        Plot *newPlot = [Plot createPlotForAnalysis:self.analysis parentNode:gate];
        newPlot.xAxisType = plot.xAxisType;
        newPlot.yAxisType = plot.yAxisType;
        [newPlot.managedObjectContext save];
        [self _presentPlot:newPlot];
    }];
}


- (void)plotViewController:(PlotViewController *)plotViewController didDeleteGate:(Gate *)gate
{
    [self.analysis.managedObjectContext save];
}


- (void)plotViewController:(PlotViewController *)plotViewController didTapDoneForPlot:(Plot *)plot
{
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:plot];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    cell.bounds = plotViewController.view.bounds;
    
    UIImageView *plotImageView = (UIImageView *)[cell viewWithTag:6];
    plotImageView.bounds = cell.bounds;

    [self dismissViewControllerAnimated:NO completion:nil];
    CGRect destBounds = CGRectMake(0, 0, 250, 250);

    [UIView animateWithDuration:0.5 animations:^{
        plotImageView.bounds = destBounds;
        plotImageView.center = self.pickedCellLocation;
        cell.bounds = destBounds;
        cell.center = self.pickedCellLocation;
    } completion:^(BOOL finished) {
        [plot.managedObjectContext save];
        [self _hideLabels:NO forCell:cell];
    }];
}

#pragma mark - Plot Table View Controller delegate

- (void)didTapDeletePlot:(PlotDetailTableViewController *)sender
{
    __weak Plot *plotToBeDeleted = sender.plot;
    
    if ([self.presentedViewController isKindOfClass:PlotViewController.class])
    {
        [self dismissViewControllerAnimated:YES completion:^{
            [self deletePlot:plotToBeDeleted];
        }];
    }
    else
    {
        [self.detailPopoverController dismissPopoverAnimated:YES];
        [self deletePlot:plotToBeDeleted];
    }
}

#pragma mark - Collection View Data source
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.fetchedResultsController.sections.count;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return sectionInfo.numberOfObjects;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Plot Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Plot *plot = [self.analysis.plots objectAtIndex:indexPath.row];
    [self _presentPlot:plot];
}


#pragma mark - Pinch effect
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)sender
{
    PinchLayout* pinchLayout = (PinchLayout*)self.collectionView.collectionViewLayout;
    
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        CGPoint initialPinchPoint = [sender locationInView:self.collectionView];
        NSIndexPath* pinchedCellPath = [self.collectionView indexPathForItemAtPoint:initialPinchPoint];
        pinchLayout.pinchedCellPath = pinchedCellPath;
        
    }
    else if (sender.state == UIGestureRecognizerStateChanged)
    {
        pinchLayout.pinchedCellScale = sender.scale;
        pinchLayout.pinchedCellCenter = [sender locationInView:self.collectionView];
    }
    else
    {
        [self.collectionView performBatchUpdates:^{
            pinchLayout.pinchedCellPath = nil;
            pinchLayout.pinchedCellScale = 1.0;
        } completion:nil];
    }
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

- (BOOL)splitViewController:(UISplitViewController*)svc
   shouldHideViewController:(UIViewController *)vc
              inOrientation:(UIInterfaceOrientation)orientation
{
    return YES;
}


@end
