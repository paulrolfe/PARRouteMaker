//
//  PARDirectionsViewController.m
//  PARRouteMaker
//
//  Created by Paul Rolfe on 6/15/15.
//  Copyright (c) 2015 paulrolfe. All rights reserved.
//

#import "PARDirectionsViewController.h"

@interface PARDirectionsViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation PARDirectionsViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"TableViewCell" bundle:nil] forCellReuseIdentifier:@"cell"];
    self.title = @"Directions";
}

#pragma mark - UITableView Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return (NSInteger)self.directions.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    cell.textLabel.text = self.directions[(NSUInteger)indexPath.row];
    
    return cell;
}


@end
