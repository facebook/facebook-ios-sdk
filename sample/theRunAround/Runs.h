//
//  Runs.h
//  theRunAround
//
//  Created by Yujuan Bao on 6/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface Runs :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * facebookUid;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * distance;
@property (nonatomic, retain) NSString * location;

@end



