//
//  PARMapViewController.m
//  PARRouteMaker
//
//  Created by Paul Rolfe on 6/12/15.
//  Copyright (c) 2015 paulrolfe. All rights reserved.
//

#import "PARMapViewController.h"
#import "PARGestureTrap.h"
#import "PARMapView.h"
#import "PAROverlay.h"
#import "PARDirectionsViewController.h"
#import <MapKit/MapKit.h>

@interface PARMapViewController () <CLLocationManagerDelegate, MKMapViewDelegate>

@property (nonatomic, weak) IBOutlet PARMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, weak) IBOutlet PARGestureTrap *drawRecognizer;
@property (nonatomic, weak) IBOutlet PARGestureTrap *dragRecognizer;
@property (nonatomic, strong) NSMutableArray *drawnLocationArray; //array of array of CLLocations
@property (nonatomic, strong) NSMutableArray *directionRoutes; //array of MKRoutes
@property (nonatomic, strong) MKPolyline *routeLine; //routes put together as one line
@property (nonatomic, strong) NSMutableArray *currentLine;
@property (weak, nonatomic) IBOutlet UIButton *undoButton;

@end

@implementation PARMapViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureMapView];
    [self getCurrentLocation];
    self.title = @"Make Your Route";
    self.navigationItem.prompt = @"Use two fingers to scroll";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Directions" style:UIBarButtonItemStylePlain target:self action:@selector(getDirections)];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.drawnLocationArray  = [[NSMutableArray alloc] init];
    self.directionRoutes = [[NSMutableArray alloc] init];
}

- (void)configureMapView{
    self.mapView.showsUserLocation = YES;
    self.mapView.rotateEnabled=NO;
    self.mapView.pitchEnabled=NO;
    [self.undoButton.layer setCornerRadius:5];
    
}

#pragma mark - CLLocationManagerDelegate

- (void)getCurrentLocation{
    if (!self.locationManager)
        self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate =self;
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocation * myLocation = (CLLocation *)locations.firstObject;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(myLocation.coordinate, 2000, 2000);
    [self.mapView setRegion:region animated:YES];
    [self.locationManager stopUpdatingLocation];
    self.drawnLocationArray[0] = @[myLocation];
}

#pragma mark - IBActions

- (IBAction)dragGestureRecognized:(id)sender{
    self.mapView.scrollEnabled=YES;
}

- (IBAction)drawGestureRecognized:(UIPanGestureRecognizer *)sender{

    if (sender.state == UIGestureRecognizerStateBegan){
        self.currentLine = [[NSMutableArray alloc] init];
        self.mapView.scrollEnabled=NO;
    }
    else if (sender.state == UIGestureRecognizerStateChanged){
        CGPoint point = [sender locationInView:self.mapView];
        
        CLLocationCoordinate2D mapCoord = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:mapCoord.latitude longitude:mapCoord.longitude];
        [self.currentLine addObject:loc];
        [self drawLineWithLocationArray:self.drawnLocationArray andGetRoute:NO];
    }
    else if (sender.state == UIGestureRecognizerStateEnded ||
        sender.state == UIGestureRecognizerStateCancelled ||
        sender.state == UIGestureRecognizerStateFailed){
        self.mapView.scrollEnabled=YES;
        
        [self drawLineWithLocationArray:self.drawnLocationArray andGetRoute:YES];
    }
}

- (IBAction)undoTouched:(UIButton *)sender {
    if (self.drawnLocationArray.count < 1)
        return;
    
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.drawnLocationArray removeLastObject];
    [self.directionRoutes removeLastObject];
    [self drawLineWithLocationArray:self.drawnLocationArray andGetRoute:NO];
}

- (void)getDirections{
    NSMutableArray *directionArray = [[NSMutableArray alloc] init];
    for (MKRoute *route in self.directionRoutes){
        for (MKRouteStep *step in route.steps){
            if (([self.directionRoutes indexOfObject:route]!=0 && [route.steps indexOfObject:step]==0) ||
                (![self.directionRoutes.lastObject isEqual:route] && [route.steps.lastObject isEqual:step])){
                continue;
            }
            NSLog(@"%@",step.instructions);
            [directionArray addObject:step.instructions];
        }
    }
    
    PARDirectionsViewController *directionVC = [[PARDirectionsViewController alloc] initWithNibName:@"PARDirectionsViewController" bundle:nil];
    directionVC.directions = directionArray;
    [self.navigationController pushViewController:directionVC animated:YES];

}

#pragma mark - Line drawing

- (void)drawLineWithLocationArray:(NSArray *)locationArray andGetRoute:(BOOL)getRoute{
    [self.mapView removeOverlays:self.mapView.overlays];
    
    NSUInteger pointCount = self.currentLine.count;
    for (NSArray *line in locationArray){
        pointCount = pointCount + line.count;
    }
    CLLocationCoordinate2D *coordinateArray = (CLLocationCoordinate2D *)malloc(pointCount * sizeof(CLLocationCoordinate2D));
    
    int i = 0;
    for (NSArray *line in locationArray){
        for (CLLocation *location in line) {
            coordinateArray[i] = [location coordinate];
            i++;
        }
    }
    for (CLLocation *location in self.currentLine){
        coordinateArray[i] = [location coordinate];
        i++;
    }

    PAROverlay * routeLine = [PAROverlay polylineWithCoordinates:coordinateArray count:pointCount];
    [self.mapView addOverlay:routeLine];
    
    if (getRoute){
        [self.drawnLocationArray addObject:self.currentLine];
        [self findRouteFromLocation:[(NSArray *)locationArray[locationArray.count-2] lastObject] toLocation:[(NSArray *)locationArray.lastObject lastObject]];
        self.currentLine=nil;
    }
    else{
        [self drawRoutes];
    }
    
    free(coordinateArray);
    coordinateArray = NULL;
    
}

- (void)findRouteFromLocation:(CLLocation *)from toLocation:(CLLocation *)to {
    MKPlacemark *sourcePlacemark = [[MKPlacemark alloc] initWithCoordinate:from.coordinate addressDictionary:nil];
    MKMapItem *source = [[MKMapItem alloc] initWithPlacemark:sourcePlacemark];
    
    MKPlacemark *destPlacemark = [[MKPlacemark alloc] initWithCoordinate:to.coordinate addressDictionary:nil];
    MKMapItem * destination = [[MKMapItem alloc] initWithPlacemark:destPlacemark];
    
    MKDirectionsRequest *dRequest = [[MKDirectionsRequest alloc] init];
    dRequest.source = source;
    dRequest.destination = destination;
    MKDirections *directions = [[MKDirections alloc] initWithRequest:dRequest];
    
    [directions calculateDirectionsWithCompletionHandler:
     ^(MKDirectionsResponse *response, NSError *error) {
         if (!error) {
             [self.directionRoutes addObject:response.routes.firstObject];
             [self drawRoutes];
         }
     }];
}

- (void)drawRoutes{
    if (self.directionRoutes.count==0)
        return;
    
    [self.mapView removeOverlay:self.routeLine];
    
    NSUInteger pointCount = 0;
    for (MKRoute *route in self.directionRoutes){
        pointCount = pointCount + route.polyline.pointCount;
    }
    CLLocationCoordinate2D *coordinateArray = (CLLocationCoordinate2D *)malloc(pointCount * sizeof(CLLocationCoordinate2D));
    
    int index = 0;
    for (MKRoute *route in self.directionRoutes){
        for (int m = 0; m < (int)route.polyline.pointCount; m++){
            MKMapPoint point = route.polyline.points[m];
            CLLocationCoordinate2D loc2d = MKCoordinateForMapPoint(point);
            coordinateArray[index] = loc2d;
            index++;
        }
    }
    
    self.routeLine = [MKPolyline polylineWithCoordinates:coordinateArray count:pointCount];
    [self.mapView addOverlay:self.routeLine];
    
    free(coordinateArray);
    coordinateArray = NULL;

}

#pragma mark - MKMapViewDelegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    
    MKPolylineRenderer *renderer =[[MKPolylineRenderer alloc] initWithOverlay:overlay];
    if ([overlay isKindOfClass:[PAROverlay class]]){
        renderer.strokeColor = [UIColor grayColor];
        renderer.alpha = .5;
        renderer.lineWidth = 5.0;
    }
    else if ([overlay isKindOfClass:[MKPolyline class]]){
        renderer.strokeColor = [UIColor greenColor];
        renderer.lineWidth = 5.0;
    }
    return renderer;
}

@end
